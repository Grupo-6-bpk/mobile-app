import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, danger, success }

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final ButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final double height;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.padding = const EdgeInsets.all(8),
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultColors = _getColorsFromVariant(colorScheme, variant);

    return icon != null
        ? SizedBox(
          height: height,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: defaultColors['text']),
            label: Text(
              text,
              style: TextStyle(color: defaultColors['text'], fontSize: 16),
            ),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                defaultColors['background'],
              ),
              foregroundColor: WidgetStateProperty.all(defaultColors['text']),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              padding: WidgetStateProperty.all(padding),
            ),
          ),
        )
        : SizedBox(
          height: height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                defaultColors['background'],
              ),
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
      case ButtonVariant.success:
        return {'background': Colors.green.shade600, 'text': colorScheme.onError};
    }
  }
}
