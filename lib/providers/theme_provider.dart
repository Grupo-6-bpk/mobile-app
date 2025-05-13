import 'package:flutter_riverpod/flutter_riverpod.dart';

const String theme = "Sistema";

final themeProvider = StateProvider<String>((ref) {
  return theme;
});
