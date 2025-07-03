import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/services/paywall_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../wizard/wizard1.dart';  // Import first wizard step directly
import 'user_info.dart';
import 'notifications_screen.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = 'Loading...';
  String email = 'Loading...';
  bool notificationsEnabled = false;
  bool isDarkMode = false;
  String subscriptionPlan = '';
  String subscriptionType = '';
  String subscriptionEndDate = '';
  String subscriptionStartDate = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Add a loading state for profile image upload
  bool _isUploadingProfileImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkNotificationPermission();
    _loadThemePreference();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        email = user.email ?? 'No email';
      });
    } else {
      setState(() {
        userName = 'Calzo';
        email = 'No email';
      });
    }
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      isDarkMode = value;
    });
  }

  Future<void> loadUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Initialize SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        email = user.email ?? 'No email found';
        // Immediately set display name from Firebase user
        userName = user.displayName ?? 'User';
      });

      // Get user data from Firestore as backup
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          final displayName = userData['displayName'];
          if (displayName != null && displayName.isNotEmpty) {
            setState(() {
              userName = displayName;
            });
          }
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }

      // Load subscription data from SharedPreferences
      setState(() {
        subscriptionPlan = prefs.getString('subscriptionPlan') ?? '';
        subscriptionType = prefs.getString('subscriptionType') ?? '';
        subscriptionEndDate = prefs.getString('subscriptionEndDate') ?? '';
        subscriptionStartDate = prefs.getString('subscriptionStartDate') ?? '';
      });

      // If no subscription data in SharedPreferences, try to get from Firestore
      // (Removed: Do not read from Firestore subscriptions collection)

      print(
        'Subscription Status: Plan=$subscriptionPlan, Type=$subscriptionType',
      );
      print('Dates: Start=$subscriptionStartDate, End=$subscriptionEndDate');
    }
  }

  Widget _buildSubscriptionBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'Premium',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Show language selection dialog
  void showLanguageDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Choose Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('English'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // Show delete account confirmation dialog
  void showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Delete Account'),
            content: Text(
              'Are you sure you want to delete your account? This cannot be undone.',
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  try {
                    User? user = _auth.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .delete();
                      await user.delete();

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account deleted')),
                      );

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();
                      // Reset welcome screen flag
                      await prefs.setBool('has_seen_welcome', false);
                      await _auth.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Wizard1(),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting account: $e')),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  // Logout and clear user data
  Future<void> logout() async {
    try {
      print('ℹ️ Log out called for user');
      
      // Clear all SharedPreferences first
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Reset welcome screen flag
      await prefs.setBool('has_seen_welcome', false);
      
      // Logout from RevenueCat if available
      await PaywallService.logoutUser();
      
      // Sign out from Firebase
      await _auth.signOut();

      if (!mounted) return;

      // Navigate to login screen using go_router
      context.go('/login');
      
    } catch (e) {
      print('❌ Error during logout: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSubscriptionTypeDisplay(String type) {
    if (type.isEmpty) {
      return 'Free';
    } else {
      return _capitalize(type);
    }
  }

  String _getSubscriptionPlanDisplay(String type) {
    if (type.isEmpty) {
      return 'Free';
    } else {
      return _capitalize(type);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final surfaceColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white70 : Colors.grey[600];
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'settings.title'.tr(),
          style: TextStyle(color: textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: iconColor),
        centerTitle: false,
      ),
      body: Container(
        color: backgroundColor,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                    : null,
                  builder: (context, snapshot) {
                    String userName = FirebaseAuth.instance.currentUser?.displayName ?? 
                                    FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 
                                    'User';
                    String? profileImageUrl;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        userName = data['displayName'] ?? userName;
                        profileImageUrl = data['profileImage'] as String?;
                      }
                    }
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              try {
                                setState(() { _isUploadingProfileImage = true; });
                                final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
                                await storageRef.putFile(File(image.path));
                                final url = await storageRef.getDownloadURL();
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                  'profileImage': url,
                                }, SetOptions(merge: true));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Profile image updated!')),
                                );
                                setState(() {}); 
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to upload profile image')),
                                );
                              } finally {
                                setState(() { _isUploadingProfileImage = false; });
                              }
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              profileImageUrl != null && profileImageUrl.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: profileImageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => CircleAvatar(
                                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                        radius: 40,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isDark ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => CircleAvatar(
                                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                        radius: 40,
                                        child: Icon(Icons.person, size: 40, color: isDark ? Colors.white70 : Colors.grey[400]),
                                      ),
                                      cacheKey: profileImageUrl.hashCode.toString(),
                                      memCacheHeight: 160,
                                      memCacheWidth: 160,
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                    radius: 40,
                                    child: Icon(Icons.person, size: 40, color: isDark ? Colors.white70 : Colors.grey[400]),
                                  ),
                              if (_isUploadingProfileImage)
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            ListTile(
              leading: Icon(Icons.person, color: iconColor),
              title: Text(
                'settings.my_profile'.tr(),
                style: TextStyle(color: textColor),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserInfoScreen()),
                );
              },
            ),

            // Always show subscriptions - trigger paywall if no active subscription
            ListTile(
              leading: Icon(Icons.subscriptions, color: iconColor),
              title: Text(
                'settings.subscriptions'.tr(),
                style: TextStyle(color: textColor),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
              onTap: () async {
                // Check if user has active subscription
                final hasActiveSubscription = await PaywallService.hasActiveSubscription();
                
                if (hasActiveSubscription) {
                  // User has active subscription - show system subscription management
                  try {
                    if (Platform.isIOS) {
                      await launchUrl(
                        Uri.parse(
                          'itms-apps://apps.apple.com/account/subscriptions',
                        ),
                      );
                    } else if (Platform.isAndroid) {
                      await launchUrl(Uri.parse('market://subscriptions'));
                    }
                  } catch (e) {
                    print('Error opening subscription settings: $e');
                  }
                } else {
                  // User doesn't have active subscription - show paywall
                  final prefs = await SharedPreferences.getInstance();
                  final hasUsedReferralCode = prefs.getBool('has_used_referral_code') ?? false;
                  final referralCode = prefs.getString('referral_code') ?? 'none';

                  await PaywallService.showPaywall(
                    context,
                    forceCloseOnRestore: true,
                  );
                }
              },
            ),

            ListTile(
              leading: Icon(Icons.language, color: iconColor),
              title: Text(
                'settings.language'.tr(),
                style: TextStyle(color: textColor),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
              onTap: () => _showLanguageDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip, color: iconColor),
              title: Text(
                'settings.privacy_policy'.tr(),
                style: TextStyle(color: textColor),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
              onTap: () async {
                const url = 'https://theholylabs.com/privacy';
                await launch(url);
              },
            ),
  
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'settings.logout'.tr(),
                style: TextStyle(color: Colors.red),
              ),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('settings.choose_language'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    'settings.english'.tr(),
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () async {
                    await context.setLocale(const Locale('en'));
                    Navigator.pop(context);
                    // Pop settings and refresh dashboard
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(
                    'settings.hebrew'.tr(),
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () async {
                    await context.setLocale(const Locale('he'));
                    Navigator.pop(context);
                    // Pop settings and refresh dashboard
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(
                    'settings.russian'.tr(),
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () async {
                    await context.setLocale(const Locale('ru'));
                    Navigator.pop(context);
                    // Pop settings and refresh dashboard
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _restartWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Wizard1()),
    );
  }

  Future<void> _handleAuthStateChange() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
