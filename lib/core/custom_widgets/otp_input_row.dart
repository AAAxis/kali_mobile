import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_text_styles.dart';
import '../../features/providers/otp_provider.dart';
import 'package:provider/provider.dart';

class OtpInputRow extends StatelessWidget {
  final int length;
  const OtpInputRow({this.length = 4, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<OtpProvider>(context);

    // Adjust sizing based on length to fit screen properly
    final fieldWidth = length > 4 ? 36.w : 54.w;
    final horizontalPadding = length > 4 ? 3.w : 7.w;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(length, (i) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            width: fieldWidth,
            height: fieldWidth,
            child: TextField(
              controller: provider.controllers[i],
              focusNode: provider.focusNodes[i],
              maxLength: 1,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                    width: 1.4,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                    width: 1.4,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              onChanged: (value) {
                if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
                  provider.controllers[i].clear();
                  return;
                }
                provider.onChanged(value, i);
              },
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),
        );
      }),
    );
  }
}
