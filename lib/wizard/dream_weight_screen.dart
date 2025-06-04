import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class DreamWeightScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const DreamWeightScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<DreamWeightScreen> createState() => _DreamWeightScreenState();
}

class _DreamWeightScreenState extends State<DreamWeightScreen> {
  int? selectedWeight;
  int? minWeight;
  int? maxWeight;
  bool? isPlus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initFromPrefs();
  }

  Future<void> _initFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    double? weightGoal = prefs.getDouble('weight_goal');
    int minW = 30;
    int maxW = 200;
    int selW = (weightGoal != null && weightGoal > 0) ? weightGoal.toInt() : 70;
    selW = selW.clamp(minW, maxW);
    setState(() {
      selectedWeight = selW;
      minWeight = minW;
      maxWeight = maxW;
      _loading = false;
    });
    if (weightGoal == null || weightGoal == 0) {
      await prefs.setDouble('weight_goal', selW.toDouble());
    }
  }

  Future<void> _saveDreamWeight() async {
    final prefs = await SharedPreferences.getInstance();
    if (selectedWeight != null) {
      await prefs.setDouble('weight_goal', selectedWeight!.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || selectedWeight == null || minWeight == null || maxWeight == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final int itemCount = maxWeight! - minWeight! + 1;
    final int initialItem = (selectedWeight! - minWeight!).clamp(0, itemCount - 1);
    final FixedExtentScrollController pickerController = FixedExtentScrollController(initialItem: initialItem);
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
                    'wizard.dream_weight'.tr(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '${selectedWeight!} ${'wizard.kg'.tr()}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: CupertinoPicker(
                      scrollController: pickerController,
                      itemExtent: 48,
                      onSelectedItemChanged: (index) async {
                        setState(() {
                          selectedWeight = minWeight! + index;
                        });
                        await _saveDreamWeight();
                      },
                      children: List.generate(
                        itemCount,
                        (index) => Center(
                          child: Text(
                            '${minWeight! + index} ${'wizard.kg'.tr()}',
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