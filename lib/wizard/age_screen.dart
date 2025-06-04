import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class AgeScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const AgeScreen({Key? key, required this.onNext, required this.onBack}) : super(key: key);

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  int age = 25;
  final int minAge = 10;
  final int maxAge = 100;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAge();
  }

  Future<void> _loadAge() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      age = prefs.getInt('age') ?? 25;
      _loading = false;
    });
  }

  Future<void> _saveAge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('age', age);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'wizard.how_old_are_you'.tr(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '$age',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: age - minAge),
                      itemExtent: 48,
                      onSelectedItemChanged: (index) async {
                        setState(() {
                          age = minAge + index;
                        });
                        await _saveAge();
                      },
                      children: List.generate(
                        maxAge - minAge + 1,
                        (index) => Center(
                          child: Text(
                            '${minAge + index}',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 