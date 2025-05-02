import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, danger }

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final ButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final double height;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.variant = ButtonVariant.primary,
    this.padding = const EdgeInsets.all(8),
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultColors = _getColorsFromVariant(colorScheme, variant);

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(defaultColors['background']),
          foregroundColor: WidgetStateProperty.all(defaultColors['text']),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          padding: WidgetStateProperty.all(padding),
        ),
        child: Text(
          text,
          style: TextStyle(color: defaultColors['text'], fontSize: 16),
        ),
      ),
    );
  }

  Map<String, Color> _getColorsFromVariant(
    ColorScheme colorScheme,
    ButtonVariant variant,
  ) {
    switch (variant) {
      case ButtonVariant.primary:
        return {
          'background': colorScheme.primary,
          'text': colorScheme.onPrimary,
        };
      case ButtonVariant.secondary:
        return {
          'background': colorScheme.surfaceBright,
          'text': colorScheme.onSurface,
        };
      case ButtonVariant.danger:
        return {'background': colorScheme.error, 'text': colorScheme.onError};
    }
  }
}
