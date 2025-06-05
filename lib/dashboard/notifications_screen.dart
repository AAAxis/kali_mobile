import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    bool granted = true;
    // Android
    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      if (result != null && result == false) granted = false;
    }
    // iOS
    final iosPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (result != null && result == false) granted = false;
    }
    if (!granted && mounted) {
      setState(() {});
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('notifications.disabled_title'.tr()),
              content: Text(
                'notifications.enable_prompt'.tr(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.ok'.tr()),
                ),
              ],
            ),
      );
    }
  }

  List<Map<String, String>> getNotifications() {
    // Use a static list of notifications (can be localized)
    return [
      {
        'title': 'notifications.get_started.title'.tr(),
        'subtitle': 'notifications.get_started.subtitle'.tr(),
      },
      {
        'title': 'notifications.first_meal.title'.tr(),
        'subtitle': 'notifications.first_meal.subtitle'.tr(),
      },
      {
        'title': 'notifications.three_days.title'.tr(),
        'subtitle': 'notifications.three_days.subtitle'.tr(),
      },
      {
        'title': 'notifications.five_meals.title'.tr(),
        'subtitle': 'notifications.five_meals.subtitle'.tr(),
      },
      {
        'title': 'notifications.ten_meals.title'.tr(),
        'subtitle': 'notifications.ten_meals.subtitle'.tr(),
      },
      {
        'title': 'notifications.keep_going.title'.tr(),
        'subtitle': 'notifications.keep_going.subtitle'.tr(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final notifications = getNotifications();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppTheme.getNotificationsColors(isDark);
    
    // Pick one notification per day
    final now = DateTime.now();
    final index = now.difference(DateTime(now.year)).inDays % notifications.length;
    final notification = notifications[index];

    return Scaffold(
      backgroundColor: colors['background'],
      appBar: AppBar(
        title: Text(
          'notifications.notifications'.tr(),
          style: TextStyle(color: colors['text']),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colors['text'],
        elevation: 0,
        iconTheme: IconThemeData(
          color: colors['icon'],
        ),
      ),
      body: Container(
        color: colors['background'],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors['primary']!.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 64,
                          color: colors['primary'],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'notifications.none_yet'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors['text'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for updates',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors['textSecondary'],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Reminder',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors['text'],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors['surface'],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors['primary']!.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: colors['primary']!.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors['primary']!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              size: 32,
                              color: colors['primary'],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colors['text'],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notification['subtitle'] ?? '',
                                  style: TextStyle(
                                    color: colors['textSecondary'],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
