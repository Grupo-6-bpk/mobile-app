// caronas_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/models/ride.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/pages/passenger_home/passenger_detail_home.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/ride_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:mobile_app/config/app_config.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> with AutomaticKeepAliveClientMixin<PassengerHomeScreen> {
  late Future<List<Ride>> _ridesFuture;
  final authService = AuthService();
  int? passengerId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _ridesFuture = RideService.getRides();
    passengerId = authService.currentUser?.userId;
  }

  void showPassagerDetailHome(BuildContext context, Ride ride) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      // Use a slightly transparent barrier color
      barrierColor: theme.colorScheme.onSurface.withAlpha((255 * 0.8).toInt()),
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent, // Make material transparent
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: PassengerDetailHome(ride: ride),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Importante para o AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boa tarde, Gabriel', // This could be dynamic
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Caronas Disponíveis:',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha((255 * 0.7).toInt()),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Ride>>(
                  future: _ridesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('Erro ao carregar corridas: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Nenhuma carona encontrada.'));
                    }

                    final rides = snapshot.data!;
                    return ListView.builder(
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return CaronaCard(
                          key: ValueKey(ride.id), // Add key for stability
                          ride: ride,
                          onTap: () => showPassagerDetailHome(context, ride),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaronaCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onTap;

  const CaronaCard({super.key, required this.ride, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('HH:mm').format(ride.departureTime);
    final formattedPrice = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(ride.pricePerMember ?? 0);

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade800,
                  radius: 25,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<User>(
                              future: UserService.getUserById(ride.driver.userId),
                              builder: (context, userSnapshot) {
                                String displayName;
                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                  displayName = 'Carregando...';
                                } else if (userSnapshot.hasError || !userSnapshot.hasData) {
                                  displayName = '${ride.vehicle.brand} ${ride.vehicle.model}';
                                } else {
                                  displayName = userSnapshot.data!.name;
                                }
                                return Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: onTap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saída: ${ride.startLocation}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Horário de saída: $formattedTime',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (ride.pricePerMember != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Valor por pessoa: $formattedPrice',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < 4
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                          CustomButton(
                            text: "Solicitar",
                            onPressed: () => _onSolicitarPressed(context),
                            variant: ButtonVariant.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSolicitarPressed(BuildContext context) async {
    try {
      // Verifica e solicita permissão de localização, se necessário
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissão negada
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização permanentemente negada.')),
        );
        return;
      }

      // Obtém a localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String startLocation = '${position.latitude},${position.longitude}';
      String endLocation = 'bpkedu';

      // Pegue o id do passageiro autenticado
      final authService = AuthService();
      final passengerId = authService.currentUser?.passenger?.id;

      if (passengerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado ou não é passageiro!')),
        );
        return;
      }

      await criarSolicitacaoCarona(startLocation, endLocation, ride.id, passengerId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    }
  }
}

Future<void> criarSolicitacaoCarona(
    String startLocation, String endLocation, int rideId, int passengerId) async {
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
    'passengerId': passengerId,
  });

  final url = Uri.parse('${AppConfig.baseUrl}/api/ride-requests/');
  final response = await http.post(url, headers: headers, body: body);

  print('Status: ${response.statusCode}');
  print('Response: ${response.body}');

  if (response.statusCode == 201 || response.statusCode == 200) {
    // sucesso
  } else {
    // erro
  }
}
