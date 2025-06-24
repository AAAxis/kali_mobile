import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/welcome_section.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../meal_analysis.dart';
import '../settings.dart';
import '../auth/login.dart';
import '../widgets/upload_history.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/upload_service.dart';

import '../main.dart';
import 'notifications_screen.dart';
import '../services/paywall_service.dart';
import '../camera/camera_page.dart';
import 'package:camera/camera.dart';
import '../app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAnalyzing;
  final GlobalKey<DashboardScreenState>? dashboardKey;
  
  DashboardScreen({this.isAnalyzing = false, this.dashboardKey}) : super(key: dashboardKey);

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // Placeholder user and meal data
  final String profileImage = 'images/profile.jpg'; // Replace with actual image path
  final bool isPremium = true;
  final List<DateTime> days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
  DateTime? _selectedDay = DateTime.now();
  final ImagePicker _picker = ImagePicker();

  List<Meal> _meals = [];
  bool _isMealsLoading = false;

  // Nutrition goals loaded from SharedPreferences
  double _caloriesGoal = 2000;
  double _proteinGoal = 150;
  double _carbsGoal = 300;
  double _fatsGoal = 65;

  // Camera controller for pre-initialization
  CameraController? _preInitializedController;

  Future<void> _loadNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caloriesGoal = prefs.getDouble('daily_calories') ?? 2000;
      _proteinGoal = prefs.getDouble('daily_protein') ?? 150;
      _carbsGoal = prefs.getDouble('daily_carbs') ?? 300;
      _fatsGoal = prefs.getDouble('daily_fats') ?? 65;
    });
  }

  List<Meal> get _filteredMeals {
    if (_selectedDay == null) return _meals;
    return _meals.where((meal) {
      final mealDate = meal.timestamp;
      return mealDate.year == _selectedDay!.year &&
             mealDate.month == _selectedDay!.month &&
             mealDate.day == _selectedDay!.day;
    }).toList();
  }

  Future<void> _showCameraOrGalleryDialog(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Text('Choose how you want to add a meal photo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: Text('Camera'),
          ),
        ],
      ),
    );
    if (source != null) {
      await _pickOrTakePicture(context, source);
    }
  }

  Future<void> _pickOrTakePicture(BuildContext context, ImageSource source) async {
    // Instead of handling analysis and saving here, delegate to upload_history.dart
    await pickAndAnalyzeImageFromCamera(
      picker: _picker,
      meals: _meals,
      updateMeals: (meals) => setState(() => _meals = meals),
      context: context,
    );
  }

  Future<void> _showAuthDialog(String contextKey) async {
    String title = 'login.signin_required'.tr();
    String content;
    switch (contextKey) {
      case 'camera':
        content = 'login.signin_to_access_camera'.tr();
        break;
      case 'profile':
        content = 'Sign in to upload and manage your profile photo';
        break;
      case 'settings':
      default:
        content = 'login.signin_to_access_settings'.tr();
        break;
    }
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('login.sign_in'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> loadMealsFromFirebase() async {
    setState(() { _isMealsLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      List<Meal> meals = [];
      
      if (user != null) {
        // User is authenticated - load from Firebase ONLY
        print('🔥 Loading meals from Firebase for user: ${user.uid}');
        final snapshot = await FirebaseFirestore.instance
            .collection('analyzed_meals')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();
        meals = snapshot.docs.map((doc) => Meal.fromMap(doc.data(), doc.id)).toList();
        print('✅ Loaded ${meals.length} meals from Firebase');
        
        // Clear local storage meals when user is authenticated to avoid confusion
        await _clearLocalStorageMeals();
      } else {
        // User is not authenticated - load from local storage
        print('📱 Loading meals from local storage for non-authenticated user');
        meals = await Meal.loadFromLocalStorage();
        print('✅ Loaded ${meals.length} meals from local storage');
      }
      
      setState(() {
        _meals = meals;
      });
    } catch (e) {
      print('❌ Error loading meals: $e');
    } finally {
      setState(() { _isMealsLoading = false; });
    }
  }

  // Helper method to clear local storage meals when user signs in
  Future<void> _clearLocalStorageMeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_meals');
      print('🧹 Cleared local storage meals for authenticated user');
    } catch (e) {
      print('❌ Error clearing local storage meals: $e');
    }
  }

  // Method to handle authentication state changes
  Future<void> handleAuthStateChange() async {
    final user = FirebaseAuth.instance.currentUser;
    print('🔄 Authentication state changed, reloading meals...');
    print('🔍 Current user: ${user?.uid ?? 'null'}');
    await loadMealsFromFirebase();
  }

  @override
  void initState() {
    super.initState();
    _loadNutritionGoals();
    loadMealsFromFirebase();
    _preInitializeCamera();
  }

  @override
  void dispose() {
    _preInitializedController?.dispose();
    super.dispose();
  }

  Future<void> _preInitializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _preInitializedController = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
        await _preInitializedController!.initialize();
        print('✅ Camera pre-initialized successfully');
      }
    } catch (e) {
      print('❌ Failed to pre-initialize camera: $e');
    }
  }

  // Check if user has used their free scan
  Future<bool> _checkIfUserHasUsedFreeScan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Check local storage for non-authenticated users
        final localMeals = await Meal.loadFromLocalStorage();
        final hasUsedFreeScan = localMeals.isNotEmpty;
        print('🔍 Free scan check for non-authenticated user: hasUsed=$hasUsedFreeScan (${localMeals.length} local meals)');
        return hasUsedFreeScan;
      }

      // Check Firebase for logged-in users
      final snapshot = await FirebaseFirestore.instance
          .collection('analyzed_meals')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final hasUsedFreeScan = snapshot.docs.isNotEmpty;
      print('🔍 Free scan check for user ${user.uid}: hasUsed=$hasUsedFreeScan');
      return hasUsedFreeScan;
    } catch (e) {
      print('❌ Error checking free scan usage: $e');
      return false;
    }
  }

  // Function to show custom camera screen as bottom sheet
  Future<void> _showCustomCamera() async {
    try {
      // Show camera as bottom sheet with smooth animation
      final result = await showModalBottomSheet<File>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          child: CameraScreen(
            preInitializedController: _preInitializedController,
          ),
        ),
      );

      // Handle the result from camera screen
      if (result != null && result is File) {
        print('📸 Camera returned image: ${result.path}');
        
        // Analyze the image (analyzeImageFile will handle creating the analyzing meal)
        try {
          print('🎯 About to call analyzeImageFile...');
          await analyzeImageFile(
            imageFile: result,
            meals: _meals,
            updateMeals: (updatedMeals) {
              print('📊 Updating meals: ${updatedMeals.length} total meals');
              setState(() => _meals = updatedMeals);
            },
            context: context,
            source: ImageSource.camera,
          );
          print('✅ analyzeImageFile completed successfully');
        } catch (analysisError) {
          print('❌ Error in analyzeImageFile: $analysisError');
          
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analysis failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        
        // Final refresh
        print('🎯 Calling final refresh...');
        await refreshDashboard();
        print('✅ Final refresh completed');
      } else {
        print('❌ No image result from camera');
      }
      
      // Re-initialize camera after use
      _preInitializeCamera();
    } catch (e) {
      print('❌ Error showing custom camera: $e');
      print('❌ Stack trace: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open camera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if any meal is currently being analyzed
  bool _isAnalyzing() {
    final hasAnalyzingMeal = _meals.any((meal) => meal.isAnalyzing);
    print('🎬 Checking if analyzing: ${hasAnalyzingMeal ? 'YES' : 'NO'} (${_meals.where((m) => m.isAnalyzing).length} analyzing meals)');
    return hasAnalyzingMeal;
  }

  Future<void> _handleCameraAction() async {
    print('🎯 Camera action button pressed!');
    
    try {
      // Check if analysis is in progress
      if (_isAnalyzing()) {
        print('🚫 Scan disabled - analysis in progress');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait for current analysis to complete'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      print('🔍 Checking subscription status...');
      // Check subscription before allowing camera access
      final hasActiveSubscription = await PaywallService.hasActiveSubscription();
      print('💳 Has subscription: $hasActiveSubscription');
      
      if (!hasActiveSubscription) {
        // Check if user has used their free scan
        final hasUsedFreeScan = await _checkIfUserHasUsedFreeScan();
        print('🆓 Has used free scan: $hasUsedFreeScan');
        
        if (hasUsedFreeScan) {
          print('🔒 No active subscription and free scan already used, showing paywall...');
          
          // Show Sale paywall first
          final purchased = await PaywallService.showPaywall(context, forceCloseOnRestore: true);
          if (!purchased) {
            // Show Offer paywall as fallback
            print('💡 User closed Sale paywall, showing Offer paywall as fallback...');
            final purchasedOffer = await PaywallService.showPaywall(
              context, 
              offeringId: 'Offer',
              forceCloseOnRestore: true,
            );
            if (!purchasedOffer) {
              // User cancelled both paywalls
              print('❌ User cancelled paywalls, exiting camera action');
              return;
            }
          }
        } else {
          print('✅ No subscription but free scan available, allowing camera access...');
        }
      } else {
        print('✅ Active subscription found, allowing camera access...');
      }

      // Show custom camera
      print('📸 Opening camera...');
      await _showCustomCamera();
      
    } catch (e) {
      print('❌ Error handling camera action: $e');
      print('❌ Stack trace: ${e.toString()}');
    }
  }

  Future<void> refreshDashboard() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30, amplitude: 128);
    }
    await Future.wait([
      // _loadProfileImage(),
      // _loadUserName(),
      loadMealsFromFirebase(),
    ]);
    setState(() {});
  }

  List<Meal> get meals => _meals;
  set meals(List<Meal> value) => setState(() => _meals = value);
  void Function(List<Meal>) get updateMeals => (meals) => setState(() => _meals = meals);

  ImagePicker get picker => _picker;

  // Method to set analyzing state for animations
  void setAnalyzingState(bool isAnalyzing) {
    setState(() {
      // You can add any analyzing state variables here if needed
      // For now, this just triggers a rebuild
    });
  }

  // Helper method to check if user is truly authenticated
  bool _isUserAuthenticated() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return false;
    
    // You could add additional checks here if needed
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppTheme.getDashboardColors(isDark);
    
    final user = FirebaseAuth.instance.currentUser;
    final isAuthenticated = _isUserAuthenticated();
    final locale = Localizations.localeOf(context).languageCode;

    String getMealName(Meal meal) {
      if (meal.mealName != null) {
        return meal.mealName![locale] ?? meal.mealName!['en'] ?? meal.name ?? 'Unknown Meal';
      }
      return meal.name ?? 'Unknown Meal';
    }
    List<String> getIngredients(Meal meal) {
      if (meal.ingredients != null) {
        return meal.ingredients![locale] ?? meal.ingredients!['en'] ?? [];
      }
      return [];
    }

    // Calculate dailyCalories and macros for the selected day
    final double dailyCalories = _filteredMeals.fold(0.0, (sum, meal) => sum + (meal.calories ?? 0));
    final double protein = _filteredMeals.fold(0.0, (sum, meal) => sum + (meal.macros['proteins'] ?? 0));
    final double carbs = _filteredMeals.fold(0.0, (sum, meal) => sum + (meal.macros['carbs'] ?? 0));
    final double fats = _filteredMeals.fold(0.0, (sum, meal) => sum + (meal.macros['fats'] ?? 0));
    final Map<String, double> macros = {
      'proteins': protein,
      'carbs': carbs,
      'fats': fats,
    };

    return Scaffold(
      backgroundColor: colors['background'],
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                if (isAuthenticated && user != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
                    builder: (context, snapshot) {
                      String userName = 'Explorer';
                      String? profileImageUrl;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null) {
                          userName = data['displayName'] ?? user!.displayName ?? 'Explorer';
                          profileImageUrl = data['profileImage'] as String?;
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            // Profile image (tap to go to settings)
                            GestureDetector(
                              onTap: () {
                                if (!isAuthenticated) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginScreen()),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                                  );
                                }
                              },
                              child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        profileImageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.person, size: 28, color: isDark ? Colors.white : Colors.black),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.person, size: 28, color: isDark ? Colors.white : Colors.black),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.person, size: 28, color: isDark ? Colors.white : Colors.black),
                                    ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isPremium)
                                    Row(
                                      children: [
                                        Text(
                                          'premium'.tr(),
                                          style: TextStyle(
                                            color: colors['text'],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Icon(Icons.star, color: Color(0xFFFFD700), size: 16), // Gold color
                                      ],
                                    ),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      color: colors['text'],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification icon
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NotificationsScreen()),
                                );
                              },
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: colors['icon'],
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (!isAuthenticated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, size: 28, color: isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Explorer', style: TextStyle(color: colors['text'], fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                        // Notification icon
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NotificationsScreen()),
                            );
                          },
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: colors['icon'],
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Add space before Welcome Section (date picker, macro cards, etc.)
                SizedBox(height: 16),
                // Welcome Section (date picker, macro cards, etc.)
                WelcomeSection(
                  userName: 'Explorer',
                  currentMealTime: 'breakfast', // Placeholder
                  meals: _filteredMeals,
                  dailyCalories: dailyCalories,
                  caloriesGoal: _caloriesGoal,
                  proteinGoal: _proteinGoal,
                  carbsGoal: _carbsGoal,
                  fatsGoal: _fatsGoal,
                  macros: macros,
                  onTap: () {},
                  days: days,
                  selectedDay: _selectedDay,
                  onDaySelected: (d) {
                    setState(() {
                      _selectedDay = d;
                    });
                  },
                ),
                // Meal Analysis Section (example, replace with your logic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: MealHistory(
                    meals: _filteredMeals,
                    onRefresh: refreshDashboard,
                    onDelete: (mealId) async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          // User is authenticated - delete from Firebase
                          await FirebaseFirestore.instance
                              .collection('analyzed_meals')
                              .doc(mealId)
                              .delete();
                          print('✅ Deleted meal from Firebase: $mealId');
                        } else {
                          // User is not authenticated - delete from local storage
                          await Meal.deleteFromLocalStorage(mealId);
                          print('✅ Deleted meal from local storage: $mealId');
                          
                          // For testing: Reset free scan availability when last meal is deleted
                          final remainingMeals = await Meal.loadFromLocalStorage();
                          if (remainingMeals.isEmpty) {
                            print('🔄 All meals deleted - free scan is now available again');
                          }
                        }
                        await loadMealsFromFirebase();
                      } catch (e) {
                        print('❌ Error deleting meal: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete meal')),
                        );
                      }
                    },
                    updateMeals: (meals) {
                      setState(() { _meals = meals; });
                    },
                  ),
                ),
                // Spacer for floating action button
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAnalyzing() ? null : () {
          _handleCameraAction();
        },
        backgroundColor: _isAnalyzing() 
            ? Colors.grey 
            : (isDark ? Colors.white : Colors.black),
        child: Icon(
          Icons.add,
          color: _isAnalyzing() 
              ? Colors.white 
              : (isDark ? Colors.black : Colors.white),
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
} 