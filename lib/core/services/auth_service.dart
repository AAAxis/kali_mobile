import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../store/shared_pref.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;
  
  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
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

  // APPLE SIGN IN
  static Future<AuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Update user profile if we have a name from Apple
      if (credential.givenName != null || credential.familyName != null) {
        final displayName = [credential.givenName, credential.familyName]
            .where((name) => name != null)
            .join(' ');
            
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
          
          // Also update Firestore
          if (userCredential.user != null) {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'displayName': displayName,
              'email': credential.email,
              'lastLoginAt': FieldValue.serverTimestamp(),
              'authProvider': 'apple',
            }, SetOptions(merge: true));
          }
        }
      }

      await _saveUserDataToPrefs(userCredential.user!);
      return AuthResult.success(userCredential.user!);
      
    } catch (e) {
      print('Error during Apple sign in: $e');
      return AuthResult.failure(_mapAuthException(e));
    }
  }

  // GOOGLE SIGN IN
  static Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return AuthResult.failure('Sign in cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Update Firestore with Google auth info
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'displayName': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'photoURL': userCredential.user!.photoURL,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        }, SetOptions(merge: true));
      }
      
      await _saveUserDataToPrefs(userCredential.user!);
      return AuthResult.success(userCredential.user!);
      
    } catch (e) {
      print('Error during Google sign in: $e');
      return AuthResult.failure(_mapAuthException(e));
    }
  }

  // EMAIL/PASSWORD LOGIN
  static Future<AuthResult> signInWithEmailAndPassword({
    required String email, 
    required String password
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _saveUserDataToPrefs(userCredential.user!);
      return AuthResult.success(userCredential.user!);
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      print('Error during email sign in: $e');
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  // SEND EMAIL VERIFICATION CODE
  static Future<EmailCodeResult> sendEmailVerificationCode(String email) async {
    try {
      print('🔗 Sending request to: https://api.theholylabs.com/global_auth?email=$email');
      
      // Create HTTP client with custom SSL handling
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('🔒 SSL Certificate issue for $host:$port');
        // Accept certificate for api.theholylabs.com
        return host == 'api.theholylabs.com';
      };
      
      // Use custom HTTP client for the request
      final httpClient = IOClient(client);
      final response = await httpClient.get(
        Uri.parse('https://api.theholylabs.com/global_auth?email=$email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'KaliAI-Mobile-App/1.0',
        },
      ).timeout(Duration(seconds: 30));
      
      // Close the client
      httpClient.close();

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verificationCode = data['verification_code'] ?? '';
        
        print('🔐 Received verification code from API: $verificationCode');
        
        if (verificationCode.isEmpty) {
          throw Exception('No verification code in response');
        }
        
        return EmailCodeResult.success(verificationCode);
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending verification code: $e');
      return EmailCodeResult.failure('Failed to send verification code. Please check your internet connection and try again.');
    }
  }

  // CREATE ACCOUNT WITH EMAIL AND PASSWORD
  static Future<AuthResult> createAccountWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String verificationCode,
    required String expectedCode,
  }) async {
    try {
      // Verify the code first
      if (verificationCode != expectedCode) {
        return AuthResult.failure('Invalid verification code. Please try again.');
      }

      // Create user account with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Update user profile with name
        await userCredential.user!.updateDisplayName(name);
        
        // Save user data to Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email.trim(),
          'name': name,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
          'authProvider': 'email',
        });

        await _saveUserDataToPrefs(userCredential.user!);
        return AuthResult.success(userCredential.user!);
      } else {
        return AuthResult.failure('Failed to create account. Please try again.');
      }
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      print('Error creating account: $e');
      return AuthResult.failure('Failed to create account. Please try again.');
    }
  }

  // SEND PASSWORD RESET EMAIL
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, message: 'Password reset email sent to $email');
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      print('Error sending password reset email: $e');
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  // DELETE USER ACCOUNT
  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user is currently signed in.');
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete user meals from Firestore
      final mealsQuery = await _firestore
          .collection('analyzed_meals')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (final doc in mealsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      await user.delete();
      
      // Clear local data
      await SharedPref.clearUserData();
      
      return AuthResult.success(null, message: 'Account deleted successfully');
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      print('Error deleting account: $e');
      return AuthResult.failure('Failed to delete account. Please try again.');
    }
  }

  // REAUTHENTICATE USER (required for sensitive operations)
  static Future<AuthResult> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return AuthResult.failure('No user is currently signed in.');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return AuthResult.success(user);
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      print('Error reauthenticating user: $e');
      return AuthResult.failure('Authentication failed. Please try again.');
    }
  }

  // UPDATE USER PROFILE
  static Future<AuthResult> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user is currently signed in.');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore as well
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      
      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update(updateData);
      }

      // Update SharedPreferences
      if (displayName != null) {
        await SharedPref.setUserName(displayName);
      }

      return AuthResult.success(user, message: 'Profile updated successfully');
      
    } catch (e) {
      print('Error updating user profile: $e');
      return AuthResult.failure('Failed to update profile. Please try again.');
    }
  }

  // HELPER METHODS
  
  static Future<void> _saveUserDataToPrefs(User user) async {
    await SharedPref.setUserEmail(user.email ?? '');
    await SharedPref.setUserName(user.displayName ?? '');
  }

  static String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please check and try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'email-already-in-use':
        return 'This email is already registered. Please use the login screen instead.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  static String _mapAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      return _mapFirebaseAuthError(e);
    }
    return e.toString();
  }
}

// RESULT CLASSES

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? message;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.message,
    this.error,
  });

  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}

class EmailCodeResult {
  final bool isSuccess;
  final String? verificationCode;
  final String? error;

  EmailCodeResult._({
    required this.isSuccess,
    this.verificationCode,
    this.error,
  });

  factory EmailCodeResult.success(String verificationCode) {
    return EmailCodeResult._(
      isSuccess: true,
      verificationCode: verificationCode,
    );
  }

  factory EmailCodeResult.failure(String error) {
    return EmailCodeResult._(
      isSuccess: false,
      error: error,
    );
  }
} 