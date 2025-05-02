import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/pages/home/driver_home_page.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/passenger_history/passenger_ride_history_page.dart';
import 'package:mobile_app/pages/sign_up/driver_sign_up_page.dart';
import 'package:mobile_app/pages/sign_up/passenger_sign_up_page.dart';
import 'package:mobile_app/pages/sign_up/sign_up_role_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BPKCar',
      theme: ThemeData.light(), // Tema claro
      darkTheme: ThemeData.dark(), // Tema escuro
      themeMode: switch (theme) {
        "Claro" => ThemeMode.light,
        "Escuro" => ThemeMode.dark,
        _ => ThemeMode.system,
      },

      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginPage(),
        "/signUpRole": (context) => const SignUpRolePage(),
        "/driverSignUp": (context) => const DriverSignUpPage(),
        "/driverHome": (context) => const DriverHomePage(),
        "/passengerSignUp": (context) => const PassengerSignUpPage(),
        "/passengerRideHistory": (context) => const PassengerRideHistoryPage(),
      },
    );
  }
}
