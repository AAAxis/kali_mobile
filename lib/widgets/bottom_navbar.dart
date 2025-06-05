import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/paywall_service.dart';
import '../meal_analysis.dart';
import '../dashboard/dashboard.dart';
import '../main.dart';
import '../camera/camera_page.dart';
import 'package:camera/camera.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final GlobalKey<DashboardScreenState> dashboardKey;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.dashboardKey,
  }) : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  CameraController? _preInitializedController;

  @override
  void initState() {
    super.initState();
    
    // Pre-initialize camera for faster startup
    _preInitializeCamera();
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

  @override
  void dispose() {
    _preInitializedController?.dispose();
    super.dispose();
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

  // Function to show your custom camera screen as bottom sheet
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

      // Handle the result from your camera screen
      if (result != null && result is File) {
        print('📸 Camera returned image: ${result.path}');
        
        // Use global dashboard key instead of widget.dashboardKey
        final dashboardState = globalDashboardKey.currentState;
        print('🎯 Dashboard state: ${dashboardState != null ? 'found' : 'null'}');
        
        if (dashboardState != null) {
          final meals = dashboardState.meals;
          final updateMeals = dashboardState.updateMeals;
          
          print('🎯 Starting analysis with ${meals.length} existing meals');
          print('🎯 UpdateMeals function: ${updateMeals != null ? 'available' : 'null'}');
          
          // Immediately trigger a refresh to show analyzing state
          dashboardState.setState(() {
            // This will trigger a rebuild and show any new analyzing meals
          });
          
          // Analyze the image (this will add the analyzing meal to the list)
          try {
            print('🎯 About to call analyzeImageFile...');
            await analyzeImageFile(
              imageFile: result,
              meals: meals,
              updateMeals: (updatedMeals) {
                print('📊 Updating meals: ${updatedMeals.length} total meals');
                updateMeals(updatedMeals);
                // Force immediate dashboard refresh
                dashboardState.setState(() {});
              },
              context: context,
              source: ImageSource.camera,
            );
            print('✅ analyzeImageFile completed successfully');
          } catch (analysisError) {
            print('❌ Error in analyzeImageFile: $analysisError');
            print('❌ Stack trace: ${analysisError.toString()}');
            rethrow;
          }
          
          // Final refresh
          print('🎯 Calling final refresh...');
          await dashboardState.refreshDashboard();
          print('✅ Final refresh completed');
        } else {
          print('❌ Dashboard state is null - cannot proceed with analysis');
        }
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
    final dashboardState = globalDashboardKey.currentState;
    if (dashboardState == null) return false;
    
    final meals = dashboardState.meals;
    final hasAnalyzingMeal = meals.any((meal) => meal.isAnalyzing);
    print('🎬 Checking if analyzing: ${hasAnalyzingMeal ? 'YES' : 'NO'} (${meals.where((m) => m.isAnalyzing).length} analyzing meals)');
    return hasAnalyzingMeal;
  }

  void _onTabTapped(int index) async {
    // Only handle camera functionality now
    if (index == 0) {
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
      await _handleCameraTab();
      return;
    }
    // Pass other tabs to parent
    widget.onTabChanged(index);
  }

  Future<void> _handleCameraTab() async {
    try {
      // Check subscription before allowing camera access
      final hasActiveSubscription = await PaywallService.hasActiveSubscription();
      
      if (!hasActiveSubscription) {
        // Check if user has used their free scan
        final hasUsedFreeScan = await _checkIfUserHasUsedFreeScan();
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
              return;
            }
          }
        } else {
          print('✅ No subscription but free scan available, allowing camera access...');
        }
      }

      // Show your custom camera
      await _showCustomCamera();
      
    } catch (e) {
      print('❌ Error handling camera tab: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Since we removed the bottom nav bar from dashboard, this widget might not be needed anymore
    // But keeping it for compatibility if used elsewhere
    return SizedBox.shrink();
  }
} 