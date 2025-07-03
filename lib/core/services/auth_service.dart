import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../store/shared_pref.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;
  
  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear user data from SharedPreferences
      await SharedPref.clearUserData();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Check authentication status and return appropriate route
  static String getInitialRoute() {
    // Check Firebase authentication state first
    final currentUser = _auth.currentUser;
    
    if (currentUser != null) {
      // User is already logged in
      print('🔐 User already logged in: ${currentUser.email}');
      return '/dashboard';
    }
    
    // No user logged in, check wizard completion
    final wizardCompleted = SharedPref.getWizardCompleted();
    
    if (wizardCompleted) {
      // Wizard completed but not logged in
      print('📋 Wizard completed, showing login');
      return '/login';
    } else {
      // Wizard not completed
      print('🎯 Starting onboarding flow');
      return '/onboarding1';
    }
  }
} 