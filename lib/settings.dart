import 'package:flutter/material.dart';
import 'package:kaliai/wizard/welcome_screen.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'wizard/wizard_flow.dart';
import 'user_info.dart';
import 'services/paywall_service.dart';
import 'wizard/promocode.dart';
import 'main.dart';

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
  String subscriptionPlan = '';
  String subscriptionType = '';
  String subscriptionEndDate = '';
  String subscriptionStartDate = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      notificationsEnabled = status.isGranted;
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
    
    // Logout from RevenueCat
    await PaywallService.logoutUser();
    
    await _auth.signOut();
    
    // Dashboard will handle authentication state changes automatically
    
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
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        children: [
          // My Profile tile
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('settings.my_profile'.tr()),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserInfoScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: Text('settings.subscriptions'.tr()),
            trailing: Icon(Icons.arrow_forward_ios),
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
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('settings.language'.tr()),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text('settings.privacy_policy'.tr()),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              const url = 'https://kali-ai-nine.vercel.app/privacy';
              await launch(url);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text('settings.terms_of_use'.tr()),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              const url =
                  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
              await launch(url);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('settings.about'.tr()),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              const url = 'https://kali-ai-nine.vercel.app/';
              await launch(url);
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: Text('settings.logout'.tr()),
            onTap: logout,
          ),
        ],
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
