import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Fixed-height transition band between a gradient blue header and the grey
/// scaffold body: a rounded-top grey "notch" (with a centered grabber line)
/// sits over the header's gradient, all within [height] — this keeps the
/// rounding visible without negative margin/padding, which Flutter's
/// [Container]/[Padding] both reject (`isNonNegative` assertion).
class JagoHeaderBand extends StatelessWidget {
  final double height;

  const JagoHeaderBand({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADADA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
