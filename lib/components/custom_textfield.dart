import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;
  final String label;
  final IconButton? icon;
  final bool obscureText;
  final bool isNumeric;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const CustomTextfield({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSubmitted,
    required this.label,
    this.icon,
    required this.obscureText,
    this.isNumeric = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        suffixIcon: icon,
        label: Text(label),
        border: const OutlineInputBorder(),
        fillColor: Theme.of(context).colorScheme.surface,
        filled: true,
        errorMaxLines: 2,
      ),
    );
  }
}
