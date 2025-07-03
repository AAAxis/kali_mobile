// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../../core/constant/app_icons.dart';
// import '../../../core/custom_widgets/wizard_button.dart';
// import '../../../core/theme/app_text_styles.dart';
// import '../../providers/wizard_provider.dart';
// import 'package:provider/provider.dart';

// class Wizard16 extends StatelessWidget {
//   const Wizard16({super.key});

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
//                 "Almost there!\nUpload profile picture",
//                 style: AppTextStyles.headingMedium.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.onSurface,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 40.h),
//               // Placeholder for Image Icon (you can replace it with an image picker later)
//               Container(
//                 height: 120.h,
//                 width: 120.w,
//                 decoration: BoxDecoration(
//                   color: colorScheme.surface,
//                   borderRadius: BorderRadius.circular(16.r),
//                   border: Border.all(
//                     color: colorScheme.outline,
//                     width: 1,
//                   ),
//                 ),
//                 child: Icon(
//                   Icons.image_outlined,
//                   size: 60.sp,
//                   color: colorScheme.onSurface.withValues(alpha: 0.5),
//                 ),
//               ),
//               SizedBox(height: 28.h),
//               // Buttons: Add Photo, Skip for now
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Add Photo Button
//                   ElevatedButton(
//                     onPressed: () {
//                       // Add logic to allow the user to pick an image
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: colorScheme.primary,
//                       elevation: 8,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16.r),
//                       ),
//                       padding: EdgeInsets.symmetric(
//                           horizontal: 32.w, vertical: 14.h),
//                     ),
//                     child: Text(
//                       'Add Photo',
//                       style: AppTextStyles.bodyMedium.copyWith(
//                         color: colorScheme.onPrimary,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 16.w),
//                   // Skip Button
//                   ElevatedButton(
//                     onPressed: () {
//                       // Add logic for skipping the upload
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: colorScheme.surface,
//                       elevation: 8,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16.r),
//                       ),
//                       padding: EdgeInsets.symmetric(
//                           horizontal: 32.w, vertical: 14.h),
//                     ),
//                     child: Text(
//                       'Skip for now',
//                       style: AppTextStyles.bodyMedium.copyWith(
//                         color: colorScheme.onSurface,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const Spacer(),
//               // Continue Button
//               WizardButton(
//                 label: 'Continue',
//                 onPressed: () {
//                   // Your action here
//                   Provider.of<WizardProvider>(context, listen: false)
//                       .nextPage();
//                 },
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
