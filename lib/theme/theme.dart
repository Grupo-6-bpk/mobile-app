import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff246488),
      surfaceTint: Color(0xff246488),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffc8e6ff),
      onPrimaryContainer: Color(0xff004c6d),
      secondary: Color(0xff05677e),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffb6ebff),
      onSecondaryContainer: Color(0xff004e60),
      tertiary: Color(0xff904a44),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffdad6),
      onTertiaryContainer: Color(0xff73332e),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fafb),
      onSurface: Color(0xff171d1e),
      onSurfaceVariant: Color(0xff3f484a),
      outline: Color(0xff6f797a),
      outlineVariant: Color(0xffbfc8ca),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b3133),
      inversePrimary: Color(0xff94cdf6),
      primaryFixed: Color(0xffc8e6ff),
      onPrimaryFixed: Color(0xff001e2e),
      primaryFixedDim: Color(0xff94cdf6),
      onPrimaryFixedVariant: Color(0xff004c6d),
      secondaryFixed: Color(0xffb6ebff),
      onSecondaryFixed: Color(0xff001f28),
      secondaryFixedDim: Color(0xff87d1eb),
      onSecondaryFixedVariant: Color(0xff004e60),
      tertiaryFixed: Color(0xffffdad6),
      onTertiaryFixed: Color(0xff3b0908),
      tertiaryFixedDim: Color(0xffffb4ac),
      onTertiaryFixedVariant: Color(0xff73332e),
      surfaceDim: Color(0xffd5dbdc),
      surfaceBright: Color(0xfff5fafb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f6),
      surfaceContainer: Color(0xffe9eff0),
      surfaceContainerHigh: Color(0xffe3e9ea),
      surfaceContainerHighest: Color(0xffdee3e5),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003a55),
      surfaceTint: Color(0xff246488),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff367398),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff003c4a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff23768e),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff5e231f),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffa15852),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fafb),
      onSurface: Color(0xff0c1213),
      onSurfaceVariant: Color(0xff2f3839),
      outline: Color(0xff4b5456),
      outlineVariant: Color(0xff656f70),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b3133),
      inversePrimary: Color(0xff94cdf6),
      primaryFixed: Color(0xff367398),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff155a7e),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff23768e),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff005d72),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xffa15852),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff84413b),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2c7c9),
      surfaceBright: Color(0xfff5fafb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f6),
      surfaceContainer: Color(0xffe3e9ea),
      surfaceContainerHigh: Color(0xffd8dedf),
      surfaceContainerHighest: Color(0xffcdd3d4),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff002f46),
      surfaceTint: Color(0xff246488),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff004e71),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff00313d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff005063),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff511a16),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff763630),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fafb),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e2f),
      outlineVariant: Color(0xff414b4c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b3133),
      inversePrimary: Color(0xff94cdf6),
      primaryFixed: Color(0xff004e71),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003650),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff005063),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff003846),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff763630),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff59201c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb4babb),
      surfaceBright: Color(0xfff5fafb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffecf2f3),
      surfaceContainer: Color(0xffdee3e5),
      surfaceContainerHigh: Color(0xffcfd5d6),
      surfaceContainerHighest: Color(0xffc2c7c9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff94cdf6),
      surfaceTint: Color(0xff94cdf6),
      onPrimary: Color(0xff00344d),
      primaryContainer: Color(0xff004c6d),
      onPrimaryContainer: Color(0xffc8e6ff),
      secondary: Color(0xff87d1eb),
      onSecondary: Color(0xff003543),
      secondaryContainer: Color(0xff004e60),
      onSecondaryContainer: Color(0xffb6ebff),
      tertiary: Color(0xffffb4ac),
      onTertiary: Color(0xff561e1a),
      tertiaryContainer: Color(0xff73332e),
      onTertiaryContainer: Color(0xffffdad6),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0e1415),
      onSurface: Color(0xffdee3e5),
      onSurfaceVariant: Color(0xffbfc8ca),
      outline: Color(0xff899294),
      outlineVariant: Color(0xff3f484a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee3e5),
      inversePrimary: Color(0xff246488),
      primaryFixed: Color(0xffc8e6ff),
      onPrimaryFixed: Color(0xff001e2e),
      primaryFixedDim: Color(0xff94cdf6),
      onPrimaryFixedVariant: Color(0xff004c6d),
      secondaryFixed: Color(0xffb6ebff),
      onSecondaryFixed: Color(0xff001f28),
      secondaryFixedDim: Color(0xff87d1eb),
      onSecondaryFixedVariant: Color(0xff004e60),
      tertiaryFixed: Color(0xffffdad6),
      onTertiaryFixed: Color(0xff3b0908),
      tertiaryFixedDim: Color(0xffffb4ac),
      onTertiaryFixedVariant: Color(0xff73332e),
      surfaceDim: Color(0xff0e1415),
      surfaceBright: Color(0xff343a3b),
      surfaceContainerLowest: Color(0xff090f10),
      surfaceContainerLow: Color(0xff171d1e),
      surfaceContainer: Color(0xff1b2122),
      surfaceContainerHigh: Color(0xff252b2c),
      surfaceContainerHighest: Color(0xff303637),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbbe1ff),
      surfaceTint: Color(0xff94cdf6),
      onPrimary: Color(0xff00293d),
      primaryContainer: Color(0xff5d97be),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffa3e6ff),
      onSecondary: Color(0xff002a35),
      secondaryContainer: Color(0xff4f9ab3),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffd2cd),
      onTertiary: Color(0xff481310),
      tertiaryContainer: Color(0xffcc7b73),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0e1415),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd4dee0),
      outline: Color(0xffaab4b5),
      outlineVariant: Color(0xff889294),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee3e5),
      inversePrimary: Color(0xff004d6f),
      primaryFixed: Color(0xffc8e6ff),
      onPrimaryFixed: Color(0xff00131f),
      primaryFixedDim: Color(0xff94cdf6),
      onPrimaryFixedVariant: Color(0xff003a55),
      secondaryFixed: Color(0xffb6ebff),
      onSecondaryFixed: Color(0xff00141a),
      secondaryFixedDim: Color(0xff87d1eb),
      onSecondaryFixedVariant: Color(0xff003c4a),
      tertiaryFixed: Color(0xffffdad6),
      onTertiaryFixed: Color(0xff2c0102),
      tertiaryFixedDim: Color(0xffffb4ac),
      onTertiaryFixedVariant: Color(0xff5e231f),
      surfaceDim: Color(0xff0e1415),
      surfaceBright: Color(0xff3f4647),
      surfaceContainerLowest: Color(0xff040809),
      surfaceContainerLow: Color(0xff191f20),
      surfaceContainer: Color(0xff23292a),
      surfaceContainerHigh: Color(0xff2d3435),
      surfaceContainerHighest: Color(0xff393f40),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffe4f2ff),
      surfaceTint: Color(0xff94cdf6),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff90c9f2),
      onPrimaryContainer: Color(0xff000d17),
      secondary: Color(0xffdbf4ff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff83cde7),
      onSecondaryContainer: Color(0xff000d13),
      tertiary: Color(0xffffece9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffffaea6),
      onTertiaryContainer: Color(0xff220001),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0e1415),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f2f3),
      outlineVariant: Color(0xffbbc4c6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee3e5),
      inversePrimary: Color(0xff004d6f),
      primaryFixed: Color(0xffc8e6ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff94cdf6),
      onPrimaryFixedVariant: Color(0xff00131f),
      secondaryFixed: Color(0xffb6ebff),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xff87d1eb),
      onSecondaryFixedVariant: Color(0xff00141a),
      tertiaryFixed: Color(0xffffdad6),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffffb4ac),
      onTertiaryFixedVariant: Color(0xff2c0102),
      surfaceDim: Color(0xff0e1415),
      surfaceBright: Color(0xff4b5152),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b2122),
      surfaceContainer: Color(0xff2b3133),
      surfaceContainerHigh: Color(0xff363c3e),
      surfaceContainerHighest: Color(0xff424849),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
