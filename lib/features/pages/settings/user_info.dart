import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../features/providers/wizard_provider.dart';
import '../../pages/wizard/wizard_pager.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  Map<String, Object> _userPrefs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      final map = <String, Object>{};

      // Load display name from Firebase Auth, fallback to email prefix or 'User'
      if (user != null) {
        String displayName = user.displayName ?? '';
        if (displayName.isEmpty) {
          displayName = user.email?.split('@')[0] ?? 'User';
        }
        map['user_display_name'] = displayName;
        map['user_email'] = user.email ?? '';

        // Load from Firestore
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            // If Firestore has displayName, prefer it
            if (data['displayName'] != null && (data['displayName'] as String).isNotEmpty) {
              map['user_display_name'] = data['displayName'];
            }
          }
        } catch (e) {
          print('Error loading displayName from Firestore: $e');
        }
      }

      setState(() {
        _userPrefs = map;
        _loading = false;
      });
    } catch (e) {
      print('Error loading preferences: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showNameEditDialog(String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'common.edit'.tr() + ' ' + 'common.display_name'.tr(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'common.display_name'.tr(),
            labelStyle: const TextStyle(color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
    
    if (result != null && result != currentValue) {
      await _saveDisplayName(result);
      await _loadPrefs();
    }
  }

  Future<void> _saveDisplayName(String value) async {
    // Update Firestore if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'displayName': value}, SetOptions(merge: true));
        print('[Firestore] Updated displayName: $value');
      } catch (e) {
        print('[Firestore] Error updating displayName: $e');
      }
    }
  }

  Future<void> _restartWizard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'common.restart_wizard'.tr(),
          style: const TextStyle(color: Colors.black87),
        ),
        content: Text(
          'common.restart_wizard_confirm'.tr(),
          style: const TextStyle(color: Colors.black54),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: Text('common.restart'.tr()),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear wizard-related preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_wizard', false);
      
      if (!mounted) return;
      
      // Navigate to wizard with a new provider
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => WizardProvider(totalScreens: 18),
            child: const WizardPager(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'common.user_data'.tr(), 
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Email (non-editable)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(
                            Icons.email,
                            color: Colors.blue,
                            size: 24,
                          ),
                          title: Text(
                            'common.email'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _userPrefs['user_email']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Display Name (editable)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 24,
                          ),
                          title: Text(
                            'common.display_name'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _userPrefs['user_display_name']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          trailing: Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                          onTap: () => _showNameEditDialog(
                            _userPrefs['user_display_name']?.toString() ?? '',
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      
                      // Restart Wizard (tile style)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(
                            Icons.refresh,
                            color: Colors.blue,
                            size: 24,
                          ),
                          title: Text(
                            'common.restart_wizard'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'common.restart_wizard_description'.tr(),
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          onTap: _restartWizard,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Delete Account Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.delete_forever),
                          label: Text('common.delete_account'.tr()),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: Text(
                                  'common.delete_account'.tr(),
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                content: Text(
                                  'common.delete_account_confirm'.tr(),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text(
                                      'common.cancel'.tr(),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    onPressed: () => Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('common.delete'.tr()),
                                    onPressed: () => Navigator.pop(context, true),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              try {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('common.account_deleted'.tr()),
                                    backgroundColor: Colors.black87,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting account: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 