import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/app_animations.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/constant/app_icons.dart';

class Wizard8 extends StatelessWidget {
  final bool isGain;

  const Wizard8({
    super.key,
    required this.isGain,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FutureBuilder<double>(
      future: _calculateWeightDifference(),
      builder: (context, snapshot) {
        final weightDifference = snapshot.data ?? 0.0;
        
        return _buildContent(context, colorScheme, weightDifference);
      },
    );
  }

  Future<double> _calculateWeightDifference() async {
    final prefs = await SharedPreferences.getInstance();
    final currentWeight = prefs.getDouble('wizard_weight') ?? 70.0;
    final targetWeight = prefs.getDouble('wizard_target_weight') ?? 65.0;
    return (targetWeight - currentWeight).abs();
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme, double weightDifference) {

    return SafeArea(
      child: Stack(
        children: [
          /// Left-side party popper GIF
          Positioned(
            left: -10.w,
            top: 200.h,
            child: RepaintBoundary(
              child: Image.asset(
                AppAnimations.goal,
                width: 250.w,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),

          /// Right-side party popper GIF (mirrored)
          Positioned(
            right: -10.w,
            top: 200.h,
            child: RepaintBoundary(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159),
                child: Image.asset(
                  AppAnimations.goal,
                  width: 250.w,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),

          /// Main Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: Constants.beforeIcon),
                Image.asset(
                  AppIcons.kali,
                  color: colorScheme.primary,
                ),
                SizedBox(height: Constants.afterIcon),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: isGain ? "Gaining " : "Losing ",
                        style: AppTextStyles.headingMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "${weightDifference.toStringAsFixed(1)} kg",
                        style: AppTextStyles.headingMedium.copyWith(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: isGain
                            ? " is totally a realistic goal. You can achieve it!!"
                            : " is totally a realistic goal. It's not hard at all!!",
                        style: AppTextStyles.headingMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                WizardButton(
                  label: 'Continue',
                  onPressed: () {
                    Provider.of<WizardProvider>(context, listen: false)
                        .nextPage();
                  },
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
