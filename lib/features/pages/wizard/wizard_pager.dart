import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import './loading_page.dart';
import './wizard18.dart';
import './apple_health.dart';
import './google_fit.dart';
import '../../providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';

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

  List<Widget> _getScreens() {
    return [
      const Wizard15(),
      const Wizard4(),
      const Wizard3(),
      const Wizard2(),
      const Wizard1(),
      const Wizard5(),
      const Wizard6(),
      const Wizard7(),
      const Wizard8(isGain: true, kgs: 17),
      const Wizard9(),
      const Wizard10(),
      const LoadingPage(),
      const Wizard11(),
      const Wizard18(),
      const Wizard12(),
      if (Platform.isIOS) const Wizard20() else const Wizard21(),
      const Wizard13(),
      const Wizard14(),
      const LoginScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WizardProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Index of LoadingPage and results screen
    const loadingIndex = 11; // LoadingPage index
    const resultsIndex = 12; // Wizard11 (results) index
    final showIndicators = provider.currentIndex != loadingIndex && provider.currentIndex != resultsIndex;
    
    // Calculate visible dots range (show 5 dots at a time)
    final currentIndex = provider.currentIndex;
    final totalPages = _getScreens().length;
    final visibleDots = 5;
    
    int startDot = currentIndex - (visibleDots ~/ 2);
    startDot = startDot.clamp(0, totalPages - visibleDots);
    int endDot = startDot + visibleDots;
    endDot = endDot.clamp(visibleDots, totalPages);
    startDot = endDot - visibleDots;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: provider.pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: provider.onPageChanged,
              children: _getScreens().map((screen) => 
                Container(
                  color: colorScheme.surface,
                  child: screen,
                )
              ).toList(),
            ),
          ),
          if (showIndicators) ...[
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show left ellipsis if needed
                if (startDot > 0)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                
                // Show visible dots
                ...List.generate(endDot - startDot, (index) {
                  final dotIndex = startDot + index;
                  final isActive = provider.currentIndex == dotIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: isActive ? 14.w : 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  );
                }),
                
                // Show right ellipsis if needed
                if (endDot < totalPages)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 28.h),
          ],
        ],
      ),
    );
  }
}
