import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/nutrition_database_service.dart';
import '../../../core/services/paywall_service.dart';
import '../../../core/custom_widgets/nutrition_summary.dart';
import '../../../core/custom_widgets/pantry_section.dart';
import '../settings/settings_screen.dart';
import '../camera/camera_screen.dart';
import '../../models/meal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../settings/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAnalyzing;
  final Function(int, {String? categoryId, String? categoryName})? onTabChange;

  const DashboardScreen({
    Key? key,
    this.isAnalyzing = false,
    this.onTabChange,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Meal> meals = [];
  bool _isLoading = true;
  final ImagePicker picker = ImagePicker();
  bool _isAnalyzing = false;
  String userName = 'User';
  DateTime? selectedDate; // null means show all meals, otherwise filter by date

  @override
  void initState() {
    super.initState();
    _loadUserName();
    loadMealsFromStorage();
    // Initialize nutrition database
    NutritionDatabaseService.initialize();
  }

  Future<void> _loadUserName() async {
    try {
      setState(() {
        userName = 'Calzo'; // Default username since no auth
      });
    } catch (e) {
      print('Error loading user name: $e');
      setState(() {
        userName = 'Calzo';
      });
    }
  }

  void setAnalyzingState(bool analyzing) {
    setState(() {
      _isAnalyzing = analyzing;
    });
  }

  void updateMeals(List<Meal> newMeals) {
    setState(() {
      meals = newMeals;
    });
  }

  void onDateChanged(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  List<Meal> get filteredMeals {
    if (selectedDate == null) {
      return meals;
    }
    
    final startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return meals.where((meal) =>
        meal.timestamp.isAfter(startOfDay) &&
        meal.timestamp.isBefore(endOfDay)
    ).toList();
  }

  Future<void> loadMealsFromStorage() async {
    try {
      // Only show loading if we don't have meals yet (avoid showing loading on refresh)
      if (meals.isEmpty) {
        setState(() => _isLoading = true);
      }
      
      // Load from local storage only
      List<Meal> loadedMeals = await Meal.loadFromLocalStorage();

      // Apply translation to existing meals if needed
      final translatedMeals = await _translateExistingMeals(loadedMeals);
      
      setState(() {
        meals = translatedMeals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meals: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// For now, just return meals as-is (translation service not yet implemented)
  Future<List<Meal>> _translateExistingMeals(List<Meal> meals) async {
    return meals;
  }

  Future<void> refreshDashboard() async {
    // Preserve analyzing meals during refresh
    final analyzingMeals = meals.where((meal) => meal.isAnalyzing).toList();
    print('🔄 Refreshing dashboard, preserving ${analyzingMeals.length} analyzing meals');
    
    // Don't show loading if we already have meals (silent refresh)
    final shouldShowLoading = meals.isEmpty;
    if (shouldShowLoading) {
      setState(() => _isLoading = true);
    }
    
    await loadMealsFromStorage();
    
    // Re-add analyzing meals that weren't in the loaded data
    if (analyzingMeals.isNotEmpty) {
      final loadedMealIds = meals.map((m) => m.id).toSet();
      final missingAnalyzingMeals = analyzingMeals.where((m) => !loadedMealIds.contains(m.id)).toList();
      
      if (missingAnalyzingMeals.isNotEmpty) {
        print('🔄 Re-adding ${missingAnalyzingMeals.length} analyzing meals');
        setState(() {
          meals = [...meals, ...missingAnalyzingMeals];
        });
      }
    }
    
    // Re-translate meals for current language (important for language changes)
    final translatedMeals = await _translateExistingMeals(meals);
    setState(() {
      meals = translatedMeals;
      if (shouldShowLoading) {
        _isLoading = false;
      }
    });
  }

  Future<void> _deleteMeal(String mealId) async {
    try {
      // Delete from local storage only
      await Meal.deleteFromLocalStorage(mealId);
      
      // Refresh the meals list
      await loadMealsFromStorage();
    } catch (e) {
      print('Error deleting meal: $e');
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              print('🔍 Profile icon tapped');
              print('🔍 Going to settings');
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
              // Refresh dashboard when returning from settings (in case language changed)
              await refreshDashboard();
            },
            child: Builder(
              builder: (context) {
                return CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.1),
                  radius: 22,
                  child: Icon(
                    Icons.person,
                    color: Colors.black,
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                print('🔍 Username text tapped');
                print('🔍 Going to settings');
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
                // Refresh dashboard when returning from settings (in case language changed)
                await refreshDashboard();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    return NutritionSummary(
      meals: meals,
      onDateChanged: onDateChanged,
    );
  }

  bool _hasScansToday() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    return meals.any((meal) =>
        meal.timestamp.isAfter(startOfToday) &&
        meal.timestamp.isBefore(endOfToday) &&
        !meal.isAnalyzing &&
        !meal.analysisFailed
    );
  }

  // Helper function to check if user should have free camera access
  Future<bool> _shouldAllowFreeCameraAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check referral scans first
      final hasUsedReferralCode = prefs.getBool('has_used_referral_code') ?? false;
      if (hasUsedReferralCode) {
        final referralFreeScans = prefs.getInt('referral_free_scans') ?? 0;
        final usedReferralScans = prefs.getInt('used_referral_scans') ?? 0;
        
        if (usedReferralScans < referralFreeScans) {
          print('🎁 User has ${referralFreeScans - usedReferralScans} referral scans');
          return true;
        }
      }
      
      // Check daily scan limit (1 scan per day for free users)
      final localMeals = await Meal.loadFromLocalStorage();
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));
      
      final todayScans = localMeals.where((meal) =>
          meal.timestamp.isAfter(startOfToday) &&
          meal.timestamp.isBefore(endOfToday) &&
          !meal.isAnalyzing &&
          !meal.analysisFailed
      ).length;
      
      final canUseFreeScan = todayScans < 1;
      print('🔍 Daily scan check: $canUseFreeScan (${todayScans}/1 used today)');
      return canUseFreeScan;
      
    } catch (e) {
      print('❌ Error checking free camera access: $e');
      return false;
    }
  }

  Future<void> _triggerCameraAccess() async {
    print('🚀 _triggerCameraAccess called - opening camera directly');
    print('🎯 Context mounted: ${context.mounted}');
    
    try {
      if (context.mounted) {
        print('📸 Opening camera page...');
        
        // Navigate to camera page and wait for result
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(
              updateMeals: updateMeals,
              meals: meals,
            ),
          ),
        );
        
        // Refresh dashboard after returning from camera
        await refreshDashboard();
      }
      
    } catch (e) {
      print('❌ Error in _triggerCameraAccess: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening camera. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPantrySection() {
    return PantrySection(
      meals: filteredMeals, // Use filtered meals instead of all meals
      onDelete: _deleteMeal,
      onRefresh: refreshDashboard,
      updateMeals: updateMeals,
      selectedDate: selectedDate, // Pass selected date for additional filtering logic
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.black,
                ),
              ),
            )
          : RefreshIndicator(
          onRefresh: refreshDashboard,
              color: Colors.black,
              backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                            _buildTopBar(),
                            _buildNutritionSection(),
                            const SizedBox(height: 8),
                            _buildPantrySection(), 
                            const SizedBox(height: 100),
                          ],
                        ),
              ),
            ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
                        ),
                      ],
                    ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              // Check if user has premium subscription
              final hasActiveSubscription = await PaywallService.hasActiveSubscription();
              if (hasActiveSubscription) {
                print('✅ User has active subscription');
                await _triggerCameraAccess();
                return;
              }

              // Check if user can still use free camera access
              final canUseFreeAccess = await _shouldAllowFreeCameraAccess();
              if (canUseFreeAccess) {
                print('✅ Free camera access granted');
                print('📱 User without subscription: checking free scans');
                await _triggerCameraAccess();
                return;
              }

              // User has exceeded free scans, show paywall
              print('❌ Free scans exhausted, showing paywall');
              final prefs = await SharedPreferences.getInstance();
              final hasUsedReferralCode = prefs.getBool('has_used_referral_code') ?? false;
              final referralCode = prefs.getString('referral_code') ?? 'none';

              final paywallResult = await PaywallService.showPaywall(
                context,
                forceCloseOnRestore: true,
              );
              
              // If paywall was successful, proceed with camera access
              if (paywallResult && context.mounted) {
                await _triggerCameraAccess();
              }
            },
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
} 