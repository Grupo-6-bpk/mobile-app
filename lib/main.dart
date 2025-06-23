import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/firebase_options.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/pages/home/driver_home_page.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/login_role_page.dart';
import 'package:mobile_app/pages/passenger_home/passenger_home.dart';
import 'package:mobile_app/pages/ride/create_ride_page.dart';
import 'package:mobile_app/pages/ride/start/ride_start.dart';
import 'package:mobile_app/pages/sign_up/driver_sign_up_page.dart';
import 'package:mobile_app/pages/sign_up/passenger_sign_up_page.dart';
import 'package:mobile_app/pages/sign_up/sign_up_role_page.dart';
import 'package:mobile_app/pages/chat/chat_list_screen.dart';
import 'package:mobile_app/pages/chat/new_chat_screen.dart';
import 'package:mobile_app/theme/theme.dart';
import 'package:mobile_app/theme/util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    final textTheme = createTextTheme(context, "Nunito", "Nunito");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BPKCar',
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: switch (themeMode) {
        "Claro" => ThemeMode.light,
        "Escuro" => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      // Controlar rota inicial baseado na autenticação
      home: _buildInitialScreen(authState, isAuthenticated),
      routes: {
        "/login": (context) => LoginPage(),
        "/signUpRole": (context) => SignUpRolePage(),
        "/loginRole": (context) => LoginRolePage(),
        "/driverSignUp": (context) => DriverSignUpPage(),
        "/passengerHome": (context) => PassengerHome(),
        "/driverHome": (context) => DriverHomePage(),
        "/passengerSignUp": (context) => PassengerSignUpPage(),
        "/createRide": (context) => CreateRidePage(),
        "/ride_start": (context) => const RideStartPage(),
        "/chatList": (context) => const ChatListScreen(),
        "/newChat": (context) => const NewChatScreen(),
      },
    );
  }

  Widget _buildInitialScreen(AuthState authState, bool isAuthenticated) {
    switch (authState) {
      case AuthState.initial:
      case AuthState.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando...'),
              ],
            ),
          ),
        );
      case AuthState.authenticated:
        if (isAuthenticated) {
          // Redirecionar baseado no tipo de usuário
          return Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider);
              if (currentUser == null) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if(currentUser.isDriver == true && currentUser.isPassenger == true) {
                return const LoginRolePage();
              } else if (currentUser.isDriver == true) {
                return const DriverHomePage();
              }
              else if (currentUser.isPassenger == true) {
                return const PassengerHome();
              }
              else {
                return const PassengerHome();
              }
            },
          );
        }
        return LoginPage();
      case AuthState.unauthenticated:
      case AuthState.error:
        return LoginPage();
    }
  }
}
