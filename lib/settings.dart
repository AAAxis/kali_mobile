import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'wizard/wizard_flow.dart';
import 'user_info.dart';
import 'services/paywall_service.dart';
import 'services/image_cache_service.dart';
import 'main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../auth/login.dart';
import '../meal_analysis.dart';
import 'dashboard/notifications_screen.dart';
import 'dart:io';
import 'app_theme.dart';

// Extension must be outside of the class
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = 'Loading...';
  String email = 'Loading...';
  bool notificationsEnabled = false;
  bool isDarkTheme = false;
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
    loadUserInfo();
    _checkNotificationPermission();
    _loadThemePreference();
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
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    
    // Update global theme notifier for immediate theme change
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    
    setState(() {
      isDarkTheme = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme changed successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                          builder: (context) => const WizardController(),
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
  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Reset welcome screen flag
    await prefs.setBool('has_seen_welcome', false);
    
    // Reset theme to light mode for wizard screens
    await prefs.setBool('isDarkTheme', false);
    themeNotifier.value = ThemeMode.light;
    
    // Logout from RevenueCat
    await PaywallService.logoutUser();
    
    await _auth.signOut();
    
    // Clear dashboard meals when logging out
    globalDashboardKey.currentState?.handleAuthStateChange();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WizardController()),
    );
  }

  String _getSubscriptionTypeWithDuration(String type) {
    switch (type.toLowerCase()) {
      case 'trial':
        return 'Trial - 3 days';
      case 'premium':
        if (subscriptionPlan.contains('monthly')) {
          return 'Monthly - 30 days';
        } else if (subscriptionPlan.contains('yearly')) {
          return 'Yearly - 365 days';
        }
        return type.capitalize();
      default:
        return type.capitalize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the saved theme preference instead of Theme.of(context)
    final colors = AppTheme.getSettingsColors(isDarkTheme);
    
    return Scaffold(
      backgroundColor: colors['background'],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'settings.title'.tr(),
          style: TextStyle(color: colors['text']),
        ),
        iconTheme: IconThemeData(color: colors['icon']),
        centerTitle: false,
      ),
      body: Container(
        color: colors['background'],
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24.0),
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                    : null,
                  builder: (context, snapshot) {
                    String userName = this.userName;
                    String? profileImageUrl;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        userName = data['displayName'] ?? userName;
                        profileImageUrl = data['profileImage'] as String?;
                      }
                    }
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
                                // Upload image to Firebase Storage
                                final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
                                await storageRef.putFile(File(image.path));
                                final url = await storageRef.getDownloadURL();
                                // Update Firestore user document
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                  'profileImage': url,
                                }, SetOptions(merge: true));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Profile image updated!')),
                                );
                                setState(() {}); // Refresh UI to show new image
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
                                ? Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colors['primary']!, width: 3),
                                    ),
                                    child: ClipOval(
                                      child: ImageCacheService.getCachedImage(
                                        profileImageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: colors['primary']!.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(colors['primary']!),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: colors['primary']!.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: colors['primary']!, width: 3),
                                          ),
                                          child: Icon(Icons.person, size: 40, color: colors['primary']),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      color: colors['primary']!.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colors['primary']!, width: 3),
                                    ),
                                    child: Icon(Icons.person, size: 40, color: colors['primary']),
                                  ),
                              if (_isUploadingProfileImage)
                                Container(
                                  width: 86,
                                  height: 86,
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
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: colors['text'],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Theme switcher - with custom styling
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colors['surface'],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors['primary']!.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors['primary']!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDarkTheme ? Icons.dark_mode : Icons.light_mode, 
                    color: colors['primary'],
                  ),
                ),
                title: Text(
                  'settings.theme'.tr(),
                  style: TextStyle(
                    color: colors['text'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  isDarkTheme ? 'settings.theme_dark'.tr() : 'settings.theme_light'.tr(),
                  style: TextStyle(color: colors['textSecondary']),
                ),
                trailing: Switch(
                  value: isDarkTheme,
                  onChanged: _toggleTheme,
                  activeColor: colors['accent'],
                  activeTrackColor: colors['accent']!.withOpacity(0.5),
                  inactiveThumbColor: colors['textSecondary'],
                  inactiveTrackColor: colors['textSecondary']!.withOpacity(0.3),
                ),
              ),
            ),
            
            // Settings items with custom styling
            _buildSettingsItem(
              context,
              icon: Icons.person,
              title: 'settings.my_profile'.tr(),
              colors: colors,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserInfoScreen()),
                );
              },
            ),

            _buildSettingsItem(
              context,
              icon: Icons.subscriptions,
              title: 'settings.subscriptions'.tr(),
              colors: colors,
              onTap: () async {
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
              },
            ),

            _buildSettingsItem(
              context,
              icon: Icons.language,
              title: 'settings.language'.tr(),
              colors: colors,
              onTap: () => _showLanguageDialog(context),
            ),

            _buildSettingsItem(
              context,
              icon: Icons.privacy_tip,
              title: 'settings.privacy_policy'.tr(),
              colors: colors,
              onTap: () async {
                const url = 'https://theholylabs.com/privacy';
                await launch(url);
              },
            ),

            _buildSettingsItem(
              context,
              icon: Icons.logout,
              title: 'settings.logout'.tr(),
              colors: colors,
              isDestructive: true,
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Map<String, Color> colors,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colors['surface'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors['primary']!.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withOpacity(0.1)
                : colors['primary']!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : colors['primary'],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : colors['text'],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colors['textSecondary'],
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('settings.choose_language'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('settings.english'.tr()),
                  onTap: () {
                    context.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('settings.hebrew'.tr()),
                  onTap: () {
                    context.setLocale(const Locale('he'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('settings.russian'.tr()),
                  onTap: () {
                    context.setLocale(const Locale('ru'));
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
            title: Text('settings.delete_account'.tr()),
            content: Text('settings.delete_account_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('dashboard.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'settings.delete_account'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.account_deleted'.tr())),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.delete_error'.tr(args: [e.toString()])),
          ),
        );
      }
    }
  }
}
