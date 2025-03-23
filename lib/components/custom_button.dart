import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color bgColor;
  final Color textColor;
  final String text;
  final EdgeInsetsGeometry? padding;
  final double height;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.bgColor,
    required this.textColor,
    required this.text,
    this.padding = const EdgeInsets.all(8),
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(bgColor),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          padding: WidgetStateProperty.all(padding),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }
}
