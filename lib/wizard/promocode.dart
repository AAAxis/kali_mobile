import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/paywall_service.dart';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../dashboard/dashboard.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../main.dart';

class RedeemCodeScreen extends StatefulWidget {
  @override
  _RedeemCodeScreenState createState() => _RedeemCodeScreenState();
}

class _RedeemCodeScreenState extends State<RedeemCodeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isRedeeming = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Future<bool> hasUserUsedCode(String code, String purchaserId) async {
    final doc = await FirebaseFirestore.instance
        .collection('promocodes')
        .doc('${code}_$purchaserId')
        .get();
    return doc.exists;
  }

  Future<void> logCodeUsage({
    required String code,
    required String purchaserId,
    double price = 2.99,
    String productId = 'promo_code',
    String subscriptionType = 'monthly',
  }) async {
    // Always use 2.99 for promo code
    price = 2.99;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final endDate = now.add(Duration(days: 30));

    // Get RevenueCat customer ID
    String? revenueCatCustomerId;
    try {
      revenueCatCustomerId = await Purchases.appUserID;
      print('RevenueCat Customer ID: $revenueCatCustomerId');
    } catch (e) {
      print('Error getting RevenueCat customer ID: $e');
      revenueCatCustomerId = null;
    }

    // Device info
    final deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceData = {
        'model': androidInfo.model,
        'androidVersion': androidInfo.version.release,
        'manufacturer': androidInfo.manufacturer,
        'device': androidInfo.device,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceData = {
        'model': iosInfo.utsname.machine,
        'iosVersion': iosInfo.systemVersion,
        'name': iosInfo.name,
      };
    }

    final usageData = {
      'productId': productId,
      'subscriptionType': subscriptionType,
      'startDate': now.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'price': price,
      'lastValidated': now.toIso8601String(),
      'code': code,
      'userId': purchaserId,
      'revenueCatCustomerId': revenueCatCustomerId,
      'device': deviceData,
      'platform': Platform.operatingSystem,
      'timestamp': now.toIso8601String(),
    };

    // Store in local storage
    final prefs2 = await SharedPreferences.getInstance();
    await prefs2.setString('subscription_status', json.encode(usageData));

    // Store in Firestore with composite key to prevent duplicates
    await FirebaseFirestore.instance
        .collection('promocodes')
        .doc('${code}_$purchaserId')
        .set(usageData);

    // Also track promo code usage in RevenueCat attributes if customer ID exists
    if (revenueCatCustomerId != null) {
      try {
        await Purchases.setAttributes({
          'promo_code_used': code,
          'promo_code_date': now.toIso8601String(),
          'redemption_method': 'app_promo_screen',
          'promo_code_price': price.toString(),
        });
        print('✅ Promo code usage tracked in RevenueCat: $code');
      } catch (e) {
        print('❌ Error tracking promo code usage in RevenueCat: $e');
      }
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    // Navigate to the login screen and clear the wizard stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a promo code')),
      );
      return;
    }

    setState(() => _isRedeeming = true);

    try {
      // Get RevenueCat customer ID as purchaser ID
      String? purchaserId;
      try {
        purchaserId = await Purchases.appUserID;
        print('Using RevenueCat Customer ID as purchaser ID: $purchaserId');
      } catch (e) {
        print('Error getting RevenueCat customer ID: $e');
        // Fallback to a simple timestamp-based ID if RevenueCat fails
        purchaserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Check if code was already used
      if (await hasUserUsedCode(code, purchaserId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have already used this code.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isRedeeming = false);
        return;
      }

      // Log code usage for both Android and iOS, regardless of purchase
      await logCodeUsage(code: code, purchaserId: purchaserId);

      if (Platform.isAndroid) {
        final productId = 'premium_code'; // <-- your product ID
        final response = await InAppPurchase.instance.queryProductDetails({productId});
        if (response.productDetails.isEmpty) {
          throw Exception('Product not found');
        }

        final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
        await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

        // Listen for purchase updates
        _purchaseSubscription?.cancel();
        _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen((purchases) async {
          for (var purchase in purchases) {
            if (purchase.productID == productId) {
              if (purchase.status == PurchaseStatus.purchased) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You have been granted one month of premium access!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } else if (purchase.status == PurchaseStatus.error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: You already used this code or it is invalid.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          }
        });
      } else {
        // For iOS, open the App Store promo code redemption URL
        final promoUrl = PaywallService.createPromoCodeUrl(code);
        print('🍎 Opening iOS promo code URL: $promoUrl');
        
        try {
          await launchUrl(Uri.parse(promoUrl), mode: LaunchMode.externalApplication);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Redirecting to App Store for promo code redemption...'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } catch (e) {
          print('❌ Error opening promo code URL: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening App Store: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error redeeming code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error redeeming code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: _goToLogin,
            tooltip: 'Close',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Colors.black,
            secondary: Colors.black,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            background: Colors.white,
            onBackground: Colors.black,
            error: Colors.red,
            onError: Colors.white,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionColor: Colors.black12,
            selectionHandleColor: Colors.black,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 64,
                color: Colors.black,
              ),
              const SizedBox(height: 24),
              Text(
                'redeem_code_heading'.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _controller,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: 'enter_promo_code_hint'.tr(),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isRedeeming ? null : _redeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isRedeeming
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('redeem'.tr(), style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}