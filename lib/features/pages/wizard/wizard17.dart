// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../../core/constant/app_icons.dart';
// import '../../../core/custom_widgets/wizard_button.dart';
// import '../../../core/theme/app_text_styles.dart';
// import '../../../core/constant/app_images.dart';

// class Wizard17 extends StatelessWidget {
//   const Wizard17({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 24.w),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               SizedBox(height: 38.h),
//               // App Title
//               Image.asset(
//                 AppIcons.kali,
//                 color: colorScheme.primary,
//               ),
//               SizedBox(height: 20.h),
//               // Title
//               Text(
//                 "Great Job!\nYour Account is all set up.",
//                 style: AppTextStyles.headingMedium.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.onSurface,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 20.h),
//               // Description Text
//               Text(
//                 "Thanks for giving us your precious time. Now you're ready for a more healthier and productive life.",
//                 style: AppTextStyles.bodyMedium.copyWith(
//                   fontWeight: FontWeight.w400,
//                   color: colorScheme.onSurface,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 30.h),
//               // Image Display from Assets
//               Image.asset(
//                 AppImages.fz,
//                 width: 358.w,
//                 height: 202.h,
//                 fit: BoxFit.cover,
//               ),
//               SizedBox(height: 40.h),
//               // Continue Button
//               WizardButton(
//                 label: 'Continue',
//                 onPressed: () {},
//                 padding: EdgeInsets.symmetric(
//                     vertical: 18.h), // Adjust padding if necessary
//               ),
//               SizedBox(height: 24.h),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
