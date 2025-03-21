import 'package:flutter/material.dart';
import 'package:mobile_app/theme/theme.dart';
import 'package:mobile_app/theme/util.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    TextTheme textTheme = createTextTheme(context, "Open Sans", "Nunito");

    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      title: 'BPKCar',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
    );
  }
}
