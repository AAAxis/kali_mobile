import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import './loading_page.dart';
import './wizard18.dart';
import './wizard19.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';

import 'wizard1.dart';
import 'wizard2.dart';
import 'wizard3.dart';
import 'wizard4.dart';
import 'wizard5.dart';
import 'wizard6.dart';
import 'wizard7.dart';
import 'wizard8.dart';
import 'wizard9.dart';
import 'wizard10.dart';
import 'wizard11.dart';
import 'wizard12.dart';
import 'wizard13.dart';
import 'wizard14.dart';
import 'wizard15.dart';

class WizardPager extends StatelessWidget {
  const WizardPager({super.key});

  final List<Widget> screens = const [
    Wizard15(),
    Wizard4(),
    Wizard3(),
    Wizard2(),
    Wizard1(),
    Wizard5(),
    Wizard6(),
    Wizard7(),
    Wizard8(isGain: true, kgs: 17),
    Wizard9(),
    Wizard10(),
    LoadingPage(),
    Wizard11(), //have to work on this, guage is left in here
    Wizard18(),
    //
    Wizard12(),
    Wizard19(),
    Wizard13(),
    Wizard14(),
  ];

  @override
  Widget build(BuildContext context) {
    final wizard = Provider.of<WizardProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    // Index of LoadingPage
    const loadingIndex = 11; // adjust based on actual position

    final showIndicators = wizard.currentIndex != loadingIndex;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: wizard.pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: wizard.onPageChanged,
              children: screens,
            ),
          ),
          if (showIndicators) ...[
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(screens.length, (idx) {
                final isActive = wizard.currentIndex == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: isActive ? 14.w : 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
            SizedBox(height: 28.h),
          ],
        ],
      ),
    );
  }
}
