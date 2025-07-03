import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constant/app_animations.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/constant/constants.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';

class Wizard10 extends StatelessWidget {
  const Wizard10({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WizardProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final steps = [0.1, 0.8, 1.5];
    final current = provider.goalSpeed;

    int getActiveIndex() {
      double minDiff = (current - steps[0]).abs();
      int idx = 0;
      for (int i = 1; i < steps.length; i++) {
        double diff = (current - steps[i]).abs();
        if (diff < minDiff) {
          minDiff = diff;
          idx = i;
        }
      }
      return idx;
    }

    final active = getActiveIndex();

    String getAdvice() {
      if (active == 0) return "You will lose weight very slow.";
      if (active == 1) return "You will lose weight in a good speed!!";
      return "You will lose weight super fast!";
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Constants.beforeIcon),
            Image.asset(AppIcons.kali, color: colorScheme.primary),
            SizedBox(height: Constants.afterIcon),
            Text(
              "How fast do you\nwant to reach your goal?",
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 34,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50.h),
            Text(
              "${current.toStringAsFixed(1)} Kg",
              style: AppTextStyles.headingLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            SizedBox(height: 50.h),

            // Animal icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SpeedAnimalItem(
                  activeAsset: AppAnimations.monkey,
                  inactiveAsset: AppIcons.monkey,
                  active: active == 0,
                ),
                _SpeedAnimalItem(
                  activeAsset: AppAnimations.deer,
                  inactiveAsset: AppIcons.deer,
                  active: active == 1,
                ),
                _SpeedAnimalItem(
                  activeAsset: AppAnimations.rabit,
                  inactiveAsset: AppIcons.rabit,
                  active: active == 2,
                ),
              ],
            ),

            SizedBox(height: 14.h),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.black,
                inactiveTrackColor: Colors.black26,
                thumbColor: Colors.black,
              ),
              child: Slider(
                value: current,
                min: steps.first,
                max: steps.last,
                divisions: 14,
                onChanged: provider.setGoalSpeed,
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("0.1kg",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.black87)),
                  Text("0.8kg",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.black87)),
                  Text("1.5kg",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.black87)),
                ],
              ),
            ),

            SizedBox(height: 50.h),

            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 18.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                getAdvice(),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            WizardButton(
              label: 'Continue',
              // onPressed: () => context.goToLoadingPage(),
              onPressed: () => provider.nextPage(),
              padding: EdgeInsets.symmetric(vertical: 18.h),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _SpeedAnimalItem extends StatelessWidget {
  final String activeAsset;
  final String inactiveAsset;
  final bool active;

  const _SpeedAnimalItem({
    required this.activeAsset,
    required this.inactiveAsset,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.asset(
        active ? activeAsset : inactiveAsset,
        width: 52.w,
        height: 52.w,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}
