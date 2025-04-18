import 'package:flutter/material.dart';
import 'package:mobile_app/pages/home/home_page.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/sign_up/driver_sign_up_page.dart';
import 'package:mobile_app/pages/sign_up/passenger_sign_up_page.dart';
import 'package:mobile_app/pages/sign_up/sign_up_role_page.dart';
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

    TextTheme textTheme = createTextTheme(context, "Nunito", "Nunito");

    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BPKCar',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      initialRoute: "/home",
      routes: {
        "/login": (context) => LoginPage(),
        "/signUpRole": (context) => SignUpRolePage(),
        "/driverSignUp": (context) => DriverSignUpPage(),
        "/home": (context) => HomePage(),
        "/passengerSignUp": (context) => PassengerSignUpPage(),
      },
    );
  }
}
