import 'package:flutter/material.dart';
import 'package:mobile_app/components/available_passenger_card.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_menu_bar.dart';
import 'package:mobile_app/pages/chat/chat_list_screen.dart';
import 'package:mobile_app/pages/ride_history/ride_history_page.dart';
import 'package:mobile_app/pages/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/ride_service.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _currentPageIndex = 0;
  Map<String, dynamic>? _activeRide;
  bool _isLoadingRide = true;
  final AuthService _authService = AuthService();

  // Dados mocados dos passageiros disponíveis
  final List<Map<String, dynamic>> _availablePassengers = [
    {
      'name': 'Jéssica Santos',
      'location': 'Av. Maripa - 5498, Centro, Toledo - PR',
      'phoneNumber': '45 98432-3230',
      'imageUrl': 'assets/images/profile1.png',
      'rating': 4.0,
    },
    {
      'name': 'Ana Silva',
      'location': 'Av. Maripa - 5498, Centro, Toledo - PR',
      'phoneNumber': '45 98432-3230',
      'imageUrl': 'assets/images/profile2.png',
      'rating': 4.5,
    },
    {
      'name': 'Carla Pereira',
      'location': 'Av. Maripa - 5498, Centro, Toledo - PR',
      'phoneNumber': '45 98432-3230',
      'imageUrl': 'assets/images/profile3.png',
      'rating': 5.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkForActiveRide();
  }

  Future<void> _checkForActiveRide() async {
    final currentUser = _authService.currentUser;
    if (currentUser?.userId == null) {
      setState(() => _isLoadingRide = false);
      return;
    }
    try {
      final activeRide = await RideService.getActiveRideForDriver(
        currentUser!.userId!,
      );
      if (mounted) {
        setState(() {
          _activeRide = activeRide;
          _isLoadingRide = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar viagem ativa: $e');
      if (mounted) {
        setState(() => _isLoadingRide = false);
      }
    }
  }

  // Widget da página inicial do motorista
  Widget _buildDriverHomePage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com saudação e botão criar viagem
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boa tarde, Gabriel',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passageiros disponíveis:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                _buildActionButton(),
              ],
            ),
          ),

          // Lista de passageiros disponíveis
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                itemCount: _availablePassengers.length,
                itemBuilder: (context, index) {
                  final passenger = _availablePassengers[index];
                  return AvailablePassengerCard(
                    name: passenger['name'],
                    location: passenger['location'],
                    phoneNumber: passenger['phoneNumber'],
                    imageUrl: passenger['imageUrl'],
                    rating: passenger['rating'],
                    onAccept: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Passageiro ${passenger['name']} aceito!',
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoadingRide) {
      return const SizedBox(
        height: 40,
        width: 40,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeRide != null) {
      return CustomButton(
        text: 'Gerenciar Viagem',
        variant: ButtonVariant.success,
        icon: Icons.directions_car,
        onPressed: () {
          final rideData = {
            'driverId': _activeRide!['driverId'],
            'rideId': _activeRide!['id'],
            'startLocation': _activeRide!['startLocation'],
            'endLocation': _activeRide!['endLocation'],
            'departureTime': _activeRide!['departureTime'],
            'date': 'Hoje',
            'seats': _activeRide!['totalSeats'].toString(),
            'distance': _activeRide!['distance'].toString(),
            'vehicleBrand': _activeRide!['vehicle']?['brand'],
            'vehicleModel': _activeRide!['vehicle']?['model'],
          };
          Navigator.pushNamed(
            context,
            '/ride_start',
            arguments: rideData,
          ).then((_) => _checkForActiveRide());
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        height: 40,
      );
    } else {
      return CustomButton(
        text: 'Criar viagem',
        variant: ButtonVariant.primary,
        icon: Icons.add,
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/createRide',
          ).then((_) => _checkForActiveRide());
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        height: 40,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    void updatePageIndex(int index) {
      if (context.mounted) {
        setState(() {
          _currentPageIndex = index;
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body:
          <Widget>[
            _buildDriverHomePage(),
            const RideHistoryPage(),
            const ChatListScreen(),
            const SettingsPage(),
          ][_currentPageIndex],
      bottomNavigationBar: CustomMenuBar(
        currentPageIndex: _currentPageIndex,
        onPageSelected: updatePageIndex,
      ),
    );
  }

  Future<void> criarSolicitacaoCarona(
    String startLocation,
    String endLocation,
    int rideId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenKey);

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'rideId': rideId,
      'startLocation': startLocation,
      'endLocation': endLocation,
      // outros campos necessários
    });

    debugPrint(
      'Enviando solicitação: $body para ${AppConfig.baseUrl}/api/ride-requests/',
    );
    final url = Uri.parse('${AppConfig.baseUrl}/api/ride-requests/');
    final response = await http.post(url, headers: headers, body: body);
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      // sucesso
    } else {
      // erro
    }
  }
}
