import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.validator,
    this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }
}
