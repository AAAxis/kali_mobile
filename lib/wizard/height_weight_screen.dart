import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'health_screen.dart';
// import 'birth_date_screen.dart';
// import your next wizard screen here
// import 'your_next_screen.dart';

class HeightWeightScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const HeightWeightScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends State<HeightWeightScreen> {
  bool isMetric = true;
  int selectedHeight = 170; // cm or in
  int selectedWeight = 70; // kg or lb

  final List<int> metricHeights = List.generate(
    151,
    (i) => 100 + i,
  ); // 100-250 cm
  final List<int> metricWeights = List.generate(
    151,
    (i) => 30 + i,
  ); // 30-180 kg
  final List<int> imperialHeights = List.generate(
    22,
    (i) => 36 + i,
  ); // 36-57 in (3ft-4ft9in)
  final List<int> imperialWeights = List.generate(
    331,
    (i) => 66 + i,
  ); // 66-396 lb

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMetric = prefs.getString('height_weight_unit') != 'imperial';
      selectedHeight = prefs.getInt('height') ?? 170;
      selectedWeight = prefs.getInt('weight') ?? 70;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'height_weight_unit',
      isMetric ? 'metric' : 'imperial',
    );
    await prefs.setInt('height', selectedHeight);
    await prefs.setInt('weight', selectedWeight);
  }

  void _onHeightChanged(int index) async {
    setState(() {
      selectedHeight = metricHeights[index];
    });
  }

  void _onWeightChanged(int index) async {
    setState(() {
      selectedWeight = metricWeights[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final heights = metricHeights;
    final weights = metricWeights;
    final heightUnit = 'cm';
    final weightUnit = 'kg';

    return Column(
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
                // Header and icon
                Column(
                  children: [
                    Text(
                      'wizard.height_weight_title'.tr(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          'wizard.height'.tr(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          width: 100,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 48,
                            diameterRatio: 1.2,
                            physics: FixedExtentScrollPhysics(),
                            onSelectedItemChanged: _onHeightChanged,
                            controller: FixedExtentScrollController(
                              initialItem: heights.indexOf(selectedHeight),
                            ),
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final value = heights[index];
                                final isSelected = value == selectedHeight;
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$value $heightUnit',
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black.withOpacity(0.3),
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: heights.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Black vertical divider between pickers
                    Container(
                      width: 2,
                      height: 180,
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Column(
                      children: [
                        Text(
                          'wizard.weight'.tr(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          width: 100,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 48,
                            diameterRatio: 1.2,
                            physics: FixedExtentScrollPhysics(),
                            onSelectedItemChanged: _onWeightChanged,
                            controller: FixedExtentScrollController(
                              initialItem: weights.indexOf(selectedWeight),
                            ),
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final value = weights[index];
                                final isSelected = value == selectedWeight;
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$value $weightUnit',
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black.withOpacity(0.3),
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: weights.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
