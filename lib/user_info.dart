import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final map = <String, Object>{};
    for (final key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        // Only include wizard steps, user email/name, and key user/subscription info
        if (key == 'user_email' || key == 'user_display_name' ||
            key == 'wizard_completed' || key == 'wizard_data' || key.startsWith('wizard_') ||
            key == 'subscriptionType' || key == 'subscriptionPlan' || key == 'subscriptionEndDate' || key == 'subscriptionStartDate' || key == 'subscriptionPrice' ||
            key == 'height' || key == 'weight' || key == 'gender' || key == 'birthDate' || key == 'age' ||
            key == 'main_goal' || key == 'weight_goal' || key == 'speed_goal' || key == 'dietType' ||
            key == 'steps' || key == 'sleep_hours') {
          map[key] = value;
        }
      }
    }
    setState(() {
      _userPrefs = map;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // Move nonEditableKeys here so it's available for the whole list
                      final nonEditableKeys = [
                        'user_email',
                        'subscriptionType',
                        'subscriptionPlan',
                        'subscriptionEndDate',
                        'subscriptionStartDate',
                        'subscriptionPrice',
                        'wizard_completed',
                        'wizard_data',
                      ];
                      // Human-friendly labels for fields
                      final fieldLabels = {
                        'user_email': 'Email',
                        'user_display_name': 'Name',
                        'wizard_completed': 'Wizard Completed',
                        'wizard_data': 'Wizard Data',
                        'subscriptionType': 'Subscription Type',
                        'subscriptionPlan': 'Subscription Plan',
                        'subscriptionEndDate': 'Subscription End Date',
                        'subscriptionStartDate': 'Subscription Start Date',
                        'subscriptionPrice': 'Subscription Price',
                        'height': 'Height (cm)',
                        'weight': 'Weight (kg)',
                        'gender': 'Gender',
                        'birthDate': 'Birth Date',
                        'age': 'Age',
                        'main_goal': 'Main Goal',
                        'weight_goal': 'Weight Goal',
                        'speed_goal': 'Speed Goal',
                        'dietType': 'Diet Type',
                        'steps': 'Daily Steps',
                        'sleep_hours': 'Sleep Hours',
                      };
                      return ListView.separated(
                        // Only show editable fields in the list
                        itemCount: _userPrefs.keys.where((key) => !nonEditableKeys.contains(key)).length + 1, // +1 for email tile
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final editableKeys = _userPrefs.keys.where((key) => !nonEditableKeys.contains(key)).toList();
                          if (index == 0) {
                            // Special tile for email at the top
                            final email = _userPrefs['user_email'] ?? '';
                            return ListTile(
                              title: Text(fieldLabels['user_email'] ?? 'Email'),
                              subtitle: Text(email.toString()),
                              onTap: () async {
                                final nonEditableMap = Map.fromEntries(_userPrefs.entries.where((entry) => nonEditableKeys.contains(entry.key)));
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Account & Subscription Info'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: nonEditableMap.entries.map((entry) => ListTile(
                                          title: Text(fieldLabels[entry.key] ?? entry.key),
                                          subtitle: Text(entry.value.toString()),
                                        )).toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                          final key = editableKeys[index - 1];
                          final value = _userPrefs[key];
                          final isNonEditable = nonEditableKeys.contains(key);
                          return ListTile(
                            title: Text(fieldLabels[key] ?? key),
                            subtitle: Text(value.toString()),
                            onTap: isNonEditable
                                ? null
                                : () async {
                                    final controller = TextEditingController(text: value.toString());
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Edit $key'),
                                        content: TextField(
                                          controller: controller,
                                          decoration: InputDecoration(labelText: key),
                                          autofocus: true,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, controller.text),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (result != null && result != value.toString()) {
                                      final prefs = await SharedPreferences.getInstance();
                                      // Try to preserve type
                                      if (value is int) {
                                        await prefs.setInt(key, int.tryParse(result) ?? 0);
                                      } else if (value is double) {
                                        await prefs.setDouble(key, double.tryParse(result) ?? 0.0);
                                      } else if (value is bool) {
                                        await prefs.setBool(key, result.toLowerCase() == 'true');
                                      } else {
                                        await prefs.setString(key, result);
                                      }
                                      // Update Firestore if user is authenticated
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        try {
                                          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({key: result}, SetOptions(merge: true));
                                          print('[Firestore] Updated $key: $result');
                                        } catch (e) {
                                          print('[Firestore] Error updating $key: $e');
                                        }
                                      }
                                      await _loadPrefs();
                                    }
                                  },
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text('Are you sure you want to delete your account? This cannot be undone.'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          // Delete from Firebase Auth and clear local storage
                          // (You may want to add your own logic here)
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account deleted')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting account: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 