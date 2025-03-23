import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;
  final String label;
  final IconButton? icon;
  final bool obscureText;

  const CustomTextfield({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSubmitted,
    required this.label,
    this.icon,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        suffixIcon: icon,
        label: Text(label),
        border: OutlineInputBorder(),
        fillColor: Theme.of(context).colorScheme.surface,
        filled: true,
      ),
    );
  }
}
