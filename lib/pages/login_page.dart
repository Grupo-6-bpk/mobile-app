import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_textfield.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:mobile_app/config/app_config.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscure = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final errorMessage = ref.watch(authErrorProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.authenticated) {
        Navigator.pushReplacementNamed(context, "/main");
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 125, 0, 0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ClipOval(
                    child: Container(
                      width: 240,
                      height: 240,
                      color: Theme.of(context).colorScheme.primary,
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        if (errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => authNotifier.clearError(),
                                  color: Colors.red.shade700,
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        CustomTextfield(
                          controller: _emailController,
                          label: "Email",
                          obscureText: false,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, digite seu email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Por favor, digite um email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextfield(
                          controller: _passwordController,
                          label: "Senha",
                          obscureText: _isObscure,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, digite sua senha';
                            }
                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          },
                          icon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                // TODO: Implementar recuperação de senha
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Funcionalidade em desenvolvimento'),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                "Esqueceu a senha?",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  "Manter conectado",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _rememberMe = newValue!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Column(
                          children: [
                            FractionallySizedBox(
                              widthFactor: 0.6,
                              child: CustomButton(
                                onPressed: authState == AuthState.loading 
                                    ? null 
                                    : () => _handleLogin(),
                                variant: ButtonVariant.primary,
                                text: authState == AuthState.loading 
                                    ? "Entrando..." 
                                    : "Login",
                              ),
                            ),
                            if (authState == AuthState.loading) ...[
                              const SizedBox(height: 16),
                              const CircularProgressIndicator(),
                            ],
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: authState == AuthState.loading 
                                  ? null 
                                  : () {
                                Navigator.pushNamed(context, "/signUpRole");
                              },
                              child: Text(
                                "Cadastre-se",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    ref.read(authProvider.notifier).clearError();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final success = await ref.read(authProvider.notifier).login(email, password);
      
      if (!success && mounted) {
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testConnectivity() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testando conectividade com servidor...'),
          duration: Duration(seconds: 2),
        ),
      );

      final testResults = <String>[];
      
      for (String baseUrl in AppConfig.testUrls) {
        final stopwatch = Stopwatch()..start();
        
        try {
          final healthResponse = await http.get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 3));
          
          stopwatch.stop();
          testResults.add('✅ $baseUrl/health: ${healthResponse.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
        } catch (e) {
          stopwatch.stop();
          
          final loginStopwatch = Stopwatch()..start();
          try {
            final loginResponse = await http.post(
              Uri.parse('$baseUrl/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': 'test@test.com', 'password': 'test'}),
            ).timeout(const Duration(seconds: 3));
            
            loginStopwatch.stop();
            testResults.add('⚠️ $baseUrl/health: ERRO, mas /login: ${loginResponse.statusCode} (${loginStopwatch.elapsedMilliseconds}ms)');
          } catch (loginError) {
            loginStopwatch.stop();
            testResults.add('❌ $baseUrl: FALHOU - $e');
          }
        }
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Teste de Conectividade'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: testResults.map((result) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(result, style: const TextStyle(fontSize: 12)),
                  )
                ).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no teste: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
