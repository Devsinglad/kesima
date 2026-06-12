import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Warm amber-to-espresso gradient that wraps both screens.
class GradientBg extends StatelessWidget {
  final Widget child;
  const GradientBg({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}
