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
import '../widgets/bottom_navbar.dart';
import '../services/upload_service.dart';
import '../services/image_cache_service.dart';
import '../main.dart';
import 'notifications_screen.dart';

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
  bool _isUploadingProfile = false;

  int _selectedIndex = 0;

  List<Meal> _meals = [];
  bool _isMealsLoading = false;

  // Nutrition goals loaded from SharedPreferences
  double _caloriesGoal = 2000;
  double _proteinGoal = 150;
  double _carbsGoal = 300;
  double _fatsGoal = 65;

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

  Future<void> _onProfileTap() async {
    if (!_isUserAuthenticated()) {
      // Navigate directly to login screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Additional safety check
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        setState(() { _isUploadingProfile = true; });
        final url = await UploadService.uploadImage(File(image.path));
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImage': url,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error uploading profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile image')),
        );
      } finally {
        setState(() { _isUploadingProfile = false; });
      }
    }
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

  void _onItemTapped(int index) {
    if (index == 1) {
      _showCameraOrGalleryDialog(context);
      return;
    }
    if (index == 2) {
      // Navigate to notifications screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NotificationsScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
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
    final cardColor = Colors.white;
    final textColor = Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
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
      backgroundColor: isDark ? Colors.black : Colors.white,
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _onProfileTap,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _isUploadingProfile
                                      ? Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            ),
                                          ),
                                        )
                                      : (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                          ? ClipOval(
                                              child: ImageCacheService.getCachedImage(
                                                profileImageUrl,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                placeholder: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.person, size: 28, color: Colors.grey[300]),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.person, size: 28, color: Colors.grey[300]),
                                            ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isPremium)
                                  Row(
                                    children: [
                                      Text(
                                        'premium'.tr(),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Icon(Icons.star, color: Colors.amber, size: 16),
                                    ],
                                  ),
                                Text(
                                  userName,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.menu, color: textColor),
                              onPressed: () {
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
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (!isAuthenticated)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, size: 28, color: Colors.grey[300]),
                        ),
                        SizedBox(width: 12),
                        Text('Explorer', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.menu, color: textColor),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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
                  child: _isMealsLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 0.0),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            backgroundColor: Colors.white,
                          ),
                        )
                      : MealHistory(
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
                // Spacer for bottom nav bar
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTabChanged: _onItemTapped,
        dashboardKey: globalDashboardKey,
      ),
    );
  }
} 