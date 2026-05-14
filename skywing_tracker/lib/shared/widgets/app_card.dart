import 'package:flutter/material.dart';
import 'package:skywing_tracker/core/theme.dart';

class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
