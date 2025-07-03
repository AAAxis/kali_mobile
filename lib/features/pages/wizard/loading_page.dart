import 'package:flutter/material.dart';
import '../../../core/constant/app_icons.dart';
import '../../../core/custom_widgets/wizard_button.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/loading_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_text_styles.dart';
import 'wizard11.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  void _navigateToResults() {
    // Use PageView navigation instead of pushReplacement for page-based routes
    final provider = Provider.of<WizardProvider>(context, listen: false);
    provider.nextPage();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoadingProvider>().startLoading(
        onComplete: () {
          // Navigate automatically when loading completes
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _navigateToResults();
              }
            });
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loadingProvider = context.watch<LoadingProvider>();
    final progress = loadingProvider.progress;
    final recommendations = loadingProvider.recommendations;

    final checkedCount = (progress ~/ 20).clamp(0, recommendations.length);
    final isCompleted = progress >= 100;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              Image.asset(AppIcons.kali, color: colorScheme.primary),
              SizedBox(height: 60.h),

              // Percentage with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${progress.toInt()}%',
                  key: ValueKey(progress.toInt()),
                  style: AppTextStyles.headingLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 64.sp,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Building your personalized\nnutrition guide',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18.sp,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 30.h),

              // Gradient progress bar
              Container(
                height: 4.h,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: Stack(
                    children: [
                      Container(
                        color: colorScheme.surfaceVariant,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * (progress / 100),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.green[300]!],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  loadingProvider.currentStatus,
                  key: ValueKey(loadingProvider.currentStatus),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // Daily Recommendations
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Recommendations',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...List.generate(
                    recommendations.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Text(
                            '- ${recommendations[index]}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 16.sp,
                            ),
                          ),
                          const Spacer(),
                          if (index < checkedCount)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.check_circle_rounded,
                                key: ValueKey('check_$index'),
                                color: colorScheme.primary,
                                size: 20.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
