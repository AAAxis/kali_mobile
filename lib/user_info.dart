import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dashboard/nutrition_edit.dart';


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

      // Load from SharedPreferences
      final keys = prefs.getKeys();
      for (final key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          if (key == 'user_email' || 
              key == 'user_display_name' || 
              key == 'dietType' || 
              key == 'main_goal' ||
              key == 'delivery_name' ||
              key == 'delivery_address' ||
              key == 'delivery_phone' ||
              key == 'delivery_zip') {
            map[key] = value;
          }
        }
      }

      // Load display name from Firebase Auth, fallback to email prefix or 'User'
      if (user != null) {
        String displayName = user.displayName ?? '';
        if (displayName.isEmpty) {
          displayName = user.email?.split('@')[0] ?? 'User';
        }
        map['user_display_name'] = displayName;
        map['user_email'] = user.email ?? '';

        // Load goal from Firestore
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            if (data['main_goal'] != null) {
              map['main_goal'] = data['main_goal'];
            }
            // If Firestore has displayName, prefer it
            if (data['displayName'] != null && (data['displayName'] as String).isNotEmpty) {
              map['user_display_name'] = data['displayName'];
            }
          }
        } catch (e) {
          print('Error loading goal/displayName from Firestore: $e');
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

  String _formatDisplayValue(String key, Object value) {
    switch (key) {
      case 'dietType':
        return _formatDietType(value.toString());
      case 'main_goal':
        return _formatGoal(value.toString());
      case 'user_display_name':
        return value.toString();
      case 'user_email':
        return value.toString();
      case 'delivery_name':
      case 'delivery_address':
      case 'delivery_phone':
      case 'delivery_zip':
        return value.toString();
      default:
        return value.toString();
    }
  }

  String _formatDietType(String dietType) {
    // Remove known prefixes and normalize
    String normalized = dietType
      .replaceAll('Wizard.diet ', '')
      .replaceAll('wizard.diet_', '')
      .replaceAll('wizard.diet ', '')
      .replaceAll('diet_', '')
      .replaceAll('_', ' ')
      .trim()
      .toLowerCase();

    switch (normalized) {
      case 'classic':
        return 'common.diet_classic'.tr();
      case 'regular':
      case 'normal':
        return 'common.diet_regular'.tr();
      case 'vegetarian':
        return 'common.diet_vegetarian'.tr();
      case 'vegan':
        return 'common.diet_vegan'.tr();
      case 'keto':
      case 'ketogenic':
        return 'common.diet_keto'.tr();
      case 'paleo':
        return 'common.diet_paleo'.tr();
      case 'mediterranean':
        return 'common.diet_mediterranean'.tr();
      case 'low carb':
        return 'common.diet_low_carb'.tr();
      case 'low fat':
        return 'common.diet_low_fat'.tr();
      case 'gluten free':
        return 'common.diet_gluten_free'.tr();
      case 'dairy free':
        return 'common.diet_dairy_free'.tr();
      case 'intermittent fasting':
        return 'common.diet_intermittent_fasting'.tr();
      case 'pescatarian':
        return 'common.diet_pescatarian'.tr();
      case 'flexitarian':
        return 'common.diet_flexitarian'.tr();
      default:
        // Capitalize each word
        return normalized.split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  String _formatGoal(String goal) {
    if (goal.isEmpty) return 'common.not_set'.tr();
    
    // Remove the 'wizard.goal_' prefix if it exists
    String cleanGoal = goal.replaceAll('wizard.goal_', '');
    
    switch (cleanGoal.toLowerCase()) {
      case 'lose_weight':
        return 'common.goal_lose_weight'.tr();
      case 'gain_weight':
        return 'common.goal_gain_weight'.tr();
      case 'build_muscle':
        return 'common.goal_build_muscle'.tr();
      case 'maintain_weight':
        return 'common.goal_maintain_weight'.tr();
      case 'improve_flexibility':
        return 'common.goal_improve_flexibility'.tr();
      default:
        return cleanGoal.split('_').map((word) => 
          word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  Future<Map<String, double>> _loadNutritionGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'calories': prefs.getDouble('daily_calories') ?? 
                   prefs.getDouble('nutrition_goal_calories') ?? 2000,
        'protein': prefs.getDouble('daily_protein') ?? 
                  prefs.getDouble('nutrition_goal_protein') ?? 150,
        'carbs': prefs.getDouble('daily_carbs') ?? 
                prefs.getDouble('nutrition_goal_carbs') ?? 300,
        'fats': prefs.getDouble('daily_fats') ?? 
               prefs.getDouble('nutrition_goal_fats') ?? 65,
      };
    } catch (e) {
      print('Error loading nutrition goals: $e');
      return {
        'calories': 2000,
        'protein': 150,
        'carbs': 300,
        'fats': 65,
      };
    }
  }

  Future<void> _saveNutritionGoals(Map<String, dynamic> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save to wizard keys (daily_*)
      await prefs.setDouble('daily_calories', goals['calories']?.toDouble() ?? 2000);
      await prefs.setDouble('daily_protein', goals['protein']?.toDouble() ?? 150);
      await prefs.setDouble('daily_carbs', goals['carbs']?.toDouble() ?? 300);
      await prefs.setDouble('daily_fats', goals['fats']?.toDouble() ?? 65);
      
      // Save to dashboard keys (nutrition_goal_*) for consistency
      await prefs.setDouble('nutrition_goal_calories', goals['calories']?.toDouble() ?? 2000);
      await prefs.setDouble('nutrition_goal_protein', goals['protein']?.toDouble() ?? 150);
      await prefs.setDouble('nutrition_goal_carbs', goals['carbs']?.toDouble() ?? 300);
      await prefs.setDouble('nutrition_goal_fats', goals['fats']?.toDouble() ?? 65);
      
      // Set flag to indicate goals have been set
      await prefs.setBool('nutrition_goals_set', true);
      
      print('✅ Nutrition goals saved to both key sets from user info screen');
    } catch (e) {
      print('❌ Error saving nutrition goals: $e');
    }
  }

  Widget _getIconForKey(String key) {
    IconData iconData;
    switch (key) {
      case 'user_display_name':
        iconData = Icons.person;
        break;
      case 'dietType':
        iconData = Icons.restaurant;
        break;
      case 'main_goal':
        iconData = Icons.flag;
        break;
      case 'delivery_name':
        iconData = Icons.person_outline;
        break;
      case 'delivery_address':
        iconData = Icons.location_on;
        break;
      case 'delivery_phone':
        iconData = Icons.phone;
        break;
      case 'delivery_zip':
        iconData = Icons.markunread_mailbox;
        break;
      default:
        iconData = Icons.info;
        break;
    }
    
    return Icon(
      iconData,
      color: Colors.blue,
      size: 24,
    );
  }

  Future<void> _showSelectionDialog(String key, String currentValue, Map<String, String> fieldLabels) async {
    String? result;
    
    switch (key) {
      case 'dietType':
        result = await _showDietTypeDialog(currentValue);
        break;
      case 'main_goal':
        result = await _showGoalDialog(currentValue);
        break;
      case 'user_display_name':
      case 'delivery_name':
      case 'delivery_address':
      case 'delivery_phone':
      case 'delivery_zip':
        result = await _showTextInputDialog(key, currentValue, fieldLabels);
        break;
    }
    
    if (result != null && result != currentValue) {
      await _saveFieldValue(key, result);
      await _loadPrefs();
    }
  }

  Future<String?> _showDietTypeDialog(String currentValue) async {
    final dietTypes = [
      {'key': 'classic', 'label': 'common.diet_classic'.tr()},
      {'key': 'vegetarian', 'label': 'common.diet_vegetarian'.tr()},
      {'key': 'vegan', 'label': 'common.diet_vegan'.tr()},
      {'key': 'keto', 'label': 'common.diet_keto'.tr()},
      {'key': 'paleo', 'label': 'common.diet_paleo'.tr()},
      {'key': 'mediterranean', 'label': 'common.diet_mediterranean'.tr()},
      {'key': 'low_carb', 'label': 'common.diet_low_carb'.tr()},
      {'key': 'low_fat', 'label': 'common.diet_low_fat'.tr()},
      {'key': 'gluten_free', 'label': 'common.diet_gluten_free'.tr()},
      {'key': 'dairy_free', 'label': 'common.diet_dairy_free'.tr()},
    ];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'common.select_diet_type'.tr(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: dietTypes.length,
            itemBuilder: (context, index) {
              final diet = dietTypes[index];
              final isSelected = diet['key'] == currentValue;
              return ListTile(
                title: Text(
                  diet['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () => Navigator.pop(context, diet['key']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showGoalDialog(String currentValue) async {
    final goals = [
      {'key': 'lose_weight', 'label': 'common.goal_lose_weight'.tr()},
      {'key': 'gain_weight', 'label': 'common.goal_gain_weight'.tr()},
      {'key': 'build_muscle', 'label': 'common.goal_build_muscle'.tr()},
      {'key': 'maintain_weight', 'label': 'common.goal_maintain_weight'.tr()},
      {'key': 'improve_flexibility', 'label': 'common.goal_improve_flexibility'.tr()},
    ];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'common.select_health_goal'.tr(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final isSelected = goal['key'] == currentValue;
              return ListTile(
                title: Text(
                  goal['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () => Navigator.pop(context, goal['key']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTextInputDialog(String key, String currentValue, Map<String, String> fieldLabels) async {
    final controller = TextEditingController(text: currentValue);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'common.edit'.tr() + ' ${fieldLabels[key] ?? key}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: fieldLabels[key] ?? key,
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
  }

  Future<void> _saveFieldValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    
    // Update Firestore if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({key: value}, SetOptions(merge: true));
        print('[Firestore] Updated $key: $value');
      } catch (e) {
        print('[Firestore] Error updating $key: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('common.user_data'.tr(), style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // Move nonEditableKeys here so it's available for the whole list
                      final nonEditableKeys = [
                        'user_email', // Email should not be editable
                      ];
                      // Human-friendly labels for fields
                      final fieldLabels = {
                        'user_email': 'common.email'.tr(),
                        'user_display_name': 'common.display_name'.tr(),
                        'dietType': 'common.diet_type'.tr(),
                        'main_goal': 'common.health_goal'.tr(),
                        'delivery_name': 'common.delivery_name'.tr(),
                        'delivery_address': 'common.delivery_address'.tr(),
                        'delivery_phone': 'common.phone_number'.tr(),
                        'delivery_zip': 'common.zip_code'.tr(),
                      };
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        // Show email tile + nutrition goals tile + all other fields
                        itemCount: 2 + _userPrefs.keys.where((key) => !nonEditableKeys.contains(key)).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final editableKeys = _userPrefs.keys.where((key) => !nonEditableKeys.contains(key)).toList();
                          
                          if (index == 0) {
                            // Special tile for email at the top
                            final email = _userPrefs['user_email'] ?? '';
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Icon(
                                  Icons.email,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                title: Text(
                                  fieldLabels['user_email'] ?? 'Email',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    email.toString(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          if (index == 1) {
                            // Special tile for nutrition goals
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Icon(
                                  Icons.track_changes,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                title: Text(
                                  'common.nutrition_goals'.tr(),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: FutureBuilder<Map<String, double>>(
                                    future: _loadNutritionGoals(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final goals = snapshot.data!;
                                        return Text(
                                          '${goals['calories']?.round() ?? 2000} ${'common.kcal'.tr()} • ${goals['protein']?.round() ?? 150}g ${'common.protein'.tr()} • ${goals['carbs']?.round() ?? 300}g ${'common.carbs'.tr()} • ${goals['fats']?.round() ?? 65}g ${'common.fats'.tr()}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.black54,
                                          ),
                                        );
                                      }
                                      return Text(
                                        'common.set_nutrition_targets'.tr(),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.black54,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                onTap: () async {
                                  final currentGoals = await _loadNutritionGoals();
                                  final result = await Navigator.push<Map<String, dynamic>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NutritionGoalsEditScreen(
                                        initialCalories: currentGoals['calories'] ?? 2000,
                                        initialProteins: (currentGoals['protein'] ?? 150).clamp(0, 100),
                                        initialCarbs: (currentGoals['carbs'] ?? 300).clamp(0, 300),
                                        initialFats: (currentGoals['fats'] ?? 65).clamp(0, 100),
                                      ),
                                    ),
                                  );
                                  
                                  if (result != null) {
                                    await _saveNutritionGoals(result);
                                    setState(() {}); // Refresh the UI
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('common.nutrition_goals_updated'.tr())),
                                    );
                                  }
                                },
                              ),
                            );
                          }
                          
                          // All other fields (index >= 2)
                          final key = editableKeys[index - 2];
                          final value = _userPrefs[key];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: _getIconForKey(key),
                              title: Text(
                                fieldLabels[key] ?? key,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatDisplayValue(key, value!),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              trailing: null,
                              onTap: () async {
                                await _showSelectionDialog(key, value.toString(), fieldLabels);
                              },
                            ),
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
                          title: Text('common.delete_account'.tr()),
                          content: Text('common.delete_account_confirm'.tr()),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          actions: [
                            TextButton(
                              child: Text('common.cancel'.tr()),
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
                          // Delete from Firebase Auth and clear local storage
                          // (You may want to add your own logic here)
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('common.account_deleted'.tr())),
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