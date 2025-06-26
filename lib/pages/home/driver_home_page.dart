import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/components/available_passenger_card.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_menu_bar.dart';
import 'package:mobile_app/components/custom_map.dart';
import 'package:mobile_app/pages/chat/chat_list_screen.dart';
import 'package:mobile_app/pages/ride_history/ride_history_page.dart';
import 'package:mobile_app/pages/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/ride_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage>
    with WidgetsBindingObserver {
  int _currentPageIndex = 0;
  Map<String, dynamic>? _activeRide;
  bool _isLoadingRide = false;
  final AuthService _authService = AuthService();
  
  // Lista de passageiros aceitos (paradas)
  List<Map<String, dynamic>> _acceptedPassengers = [];

  // Dados mocados dos passageiros disponíveis
  final List<Map<String, dynamic>> _availablePassengers = [];

  // Variáveis para localização e mapa
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _locationError = null;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
        if (kDebugMode) {
          print('Erro ao obter localização: $e');
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Removido: verificações automáticas de corrida ativa
    // A verificação só acontecerá quando o usuário pressionar o botão criar carona
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      try {
        if (args.containsKey('acceptedPassenger')) {
          final acceptedPassenger = args['acceptedPassenger'] as Map<String, dynamic>;
          setState(() {
            _acceptedPassengers.add(acceptedPassenger);
          });
        }

        if (args.containsKey('rideStarted') && args['rideStarted'] == true) {
          final acceptedPassengers = args['acceptedPassengers'] as List<Map<String, dynamic>>? ?? [];
          setState(() {
            _acceptedPassengers = acceptedPassengers;
          });

          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Corrida iniciada com ${acceptedPassengers.length} passageiro(s)!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }

        // Verificar se voltamos de uma tela onde uma corrida foi cancelada/finalizada
        if (args.containsKey('refreshRides') && args['refreshRides'] == true) {
          // Limpar imediatamente a corrida ativa do estado local
          setState(() {
            _activeRide = null;
            _acceptedPassengers.clear();
          });
          
          if (kDebugMode) {
            debugPrint('🔄 DriverHomePage: Detectado retorno de tela de corrida, limpando estado local...');
          }
        }

        // Verificar se uma carona foi criada
        if (args.containsKey('rideCreated') && args['rideCreated'] == true) {
          final rideData = args['rideData'] as Map<String, dynamic>?;
          if (rideData != null) {
            setState(() {
              _activeRide = rideData;
            });
            
            // Mostrar informações da carona criada
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showRideCreatedDialog(rideData);
              }
            });
            
            if (kDebugMode) {
              debugPrint('✅ DriverHomePage: Carona criada detectada - ID: ${rideData['id']}');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao processar argumentos: $e');
        }
      }
    }

    // Removido: verificação automática de corrida ativa
    // A verificação só acontecerá quando o usuário pressionar o botão criar carona
  }

  Future<void> _checkForActiveRide({bool forceRefresh = false}) async {
    final currentUser = _authService.currentUser;
    if (currentUser?.userId == null) {
      setState(() => _isLoadingRide = false);
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔍 DriverHomePage: Verificando corrida ativa para motorista ${currentUser!.userId}');
        debugPrint('🔍 ForceRefresh: $forceRefresh');
      }

      final activeRide = await RideService.getActiveRideForDriver(currentUser!.userId!);
      
      if (mounted) {
        if (kDebugMode) {
          debugPrint('🔍 DriverHomePage: Corrida ativa encontrada: ${activeRide != null}');
          if (activeRide != null) {
            debugPrint('🔍 Detalhes da corrida: ID=${activeRide['id']}, Status=${activeRide['status']}');
          }
        }

        setState(() {
          _activeRide = activeRide;
          _isLoadingRide = false;
          
          // Se não há corrida ativa, limpar também os passageiros aceitos
          if (activeRide == null) {
            _acceptedPassengers.clear();
          }
        });

        // Se há uma corrida ativa, redirecionar para tela de gerenciamento
        if (activeRide != null) {
          _redirectToActiveRide(activeRide);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ DriverHomePage: Erro ao verificar corrida ativa: $e');
      }
      if (mounted) {
        setState(() => _isLoadingRide = false);
      }
    }
  }

  void _redirectToActiveRide(Map<String, dynamic> activeRide) {
    // Verificar se já estamos na tela de gerenciamento para evitar redirecionamento em loop
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == '/ride_start') {
      return; // Já estamos na tela de gerenciamento
    }

    final extractedRideId = RideService.extractRideId(activeRide);
    if (!RideService.isValidRideId(extractedRideId)) {
      return; // ID inválido, não redirecionar
    }

    final rideData = {
      'driverId': activeRide['driverId'],
      'rideId': extractedRideId,
      'id': extractedRideId,
      'startLocation': activeRide['startLocation'],
      'endLocation': activeRide['endLocation'],
      'departureTime': activeRide['departureTime'],
      'date': 'Hoje',
      'totalSeats': activeRide['totalSeats'],
      'distance': activeRide['distance'].toString(),
      'vehicleBrand': activeRide['vehicle']?['brand'],
      'vehicleModel': activeRide['vehicle']?['model'],
      'acceptedPassengers': _acceptedPassengers,
      'status': activeRide['status'] ?? 'PENDING',
    };

    // Aguardar um pouco para garantir que a tela foi totalmente carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/ride_start', arguments: rideData);
      }
    });
  }

  Widget _buildDriverHomePage() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool corridaIniciada = args != null && args['rideStarted'] == true;
    final List<Map<String, dynamic>> passageiros = args?['acceptedPassengers'] as List<Map<String, dynamic>>? ?? _acceptedPassengers;

    return Stack(
      children: [
        // Mapa ocupando toda a tela
        _buildMapSection(),
        
        // Cabeçalho com informações
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildHeader(passageiros),
        ),
        
        // Botão de criar corrida na parte inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomSection(corridaIniciada, passageiros, args),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    if (_isLoadingLocation) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Obtendo localização...'),
            ],
          ),
        ),
      );
    }

    if (_locationError != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao obter localização',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _locationError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: Text('Localização não disponível'),
        ),
      );
    }

    final currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLatLng,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('current_location'),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: 'Sua localização'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }

  Widget _buildHeader(List<Map<String, dynamic>> passageiros) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boa tarde, Gabriel',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      passageiros.isNotEmpty
                          ? 'Paradas confirmadas: ${passageiros.length}'
                          : 'Sua localização atual',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeRide != null) _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool corridaIniciada, List<Map<String, dynamic>> passageiros, Map<String, dynamic>? args) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMainActionButton(corridaIniciada, args),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton(bool corridaIniciada, Map<String, dynamic>? args) {
    return CustomButton(
      text: 'Criar Carona',
      variant: ButtonVariant.primary,
      icon: Icons.add_circle,
      onPressed: () async {
        // Verificar se há corrida ativa apenas quando o botão for pressionado
        setState(() => _isLoadingRide = true);
        
        try {
          final currentUser = _authService.currentUser;
          if (currentUser?.userId != null) {
            final activeRide = await RideService.getActiveRideForDriver(currentUser!.userId!);
            
            if (activeRide != null) {
              // Se há corrida ativa, redirecionar para gerenciamento
              setState(() {
                _activeRide = activeRide;
                _isLoadingRide = false;
              });
              _redirectToActiveRide(activeRide);
              return;
            }
          }
          
          // Se não há corrida ativa, ir para tela de criação
          setState(() => _isLoadingRide = false);
          Navigator.pushNamed(context, '/createRide');
        } catch (e) {
          setState(() => _isLoadingRide = false);
          if (kDebugMode) {
            debugPrint('Erro ao verificar corrida ativa: $e');
          }
          // Em caso de erro, permitir ir para tela de criação
          Navigator.pushNamed(context, '/createRide');
        }
      },
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

    return CustomButton(
      text: 'Criar Carona',
      variant: ButtonVariant.primary,
      icon: Icons.add,
      onPressed: () async {
        // Verificar se há corrida ativa apenas quando o botão for pressionado
        setState(() => _isLoadingRide = true);
        
        try {
          final currentUser = _authService.currentUser;
          if (currentUser?.userId != null) {
            final activeRide = await RideService.getActiveRideForDriver(currentUser!.userId!);
            
            if (activeRide != null) {
              // Se há corrida ativa, redirecionar para gerenciamento
              setState(() {
                _activeRide = activeRide;
                _isLoadingRide = false;
              });
              _redirectToActiveRide(activeRide);
              return;
            }
          }
          
          // Se não há corrida ativa, ir para tela de criação
          setState(() => _isLoadingRide = false);
          Navigator.pushNamed(context, '/createRide');
        } catch (e) {
          setState(() => _isLoadingRide = false);
          if (kDebugMode) {
            debugPrint('Erro ao verificar corrida ativa: $e');
          }
          // Em caso de erro, permitir ir para tela de criação
          Navigator.pushNamed(context, '/createRide');
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      height: 40,
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'Corrida em andamento';
      case 'COMPLETED':
        return 'Corrida concluída';
      case 'CANCELLED':
        return 'Corrida cancelada';
      case 'FINISHED':
        return 'Corrida finalizada';
      default:
        return 'Status desconhecido';
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
      appBar: AppBar(
        title: const Text('Motorista'),
        centerTitle: true,
      ),
      body: <Widget>[
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

  void _showRideCreatedDialog(Map<String, dynamic> rideData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Carona Criada!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID da Carona
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'ID da Carona: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${rideData['id'] ?? rideData['rideId'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Informações da Carona
                _buildRideInfoRow(Icons.location_on, 'Origem', rideData['startLocation'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildRideInfoRow(Icons.location_on, 'Destino', rideData['endLocation'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildRideInfoRow(Icons.access_time, 'Horário', rideData['departureTime'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildRideInfoRow(Icons.calendar_today, 'Data', rideData['date'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildRideInfoRow(Icons.people, 'Vagas', '${rideData['totalSeats'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                _buildRideInfoRow(Icons.route, 'Distância', '${rideData['distance'] ?? 'N/A'} km'),
                if (rideData['vehicleBrand'] != null && rideData['vehicleModel'] != null) ...[
                  const SizedBox(height: 8),
                  _buildRideInfoRow(Icons.directions_car, 'Veículo', '${rideData['vehicleBrand']} ${rideData['vehicleModel']}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar para a tela de gerenciamento da carona
                Navigator.pushNamed(context, '/ride_start', arguments: rideData);
              },
              child: const Text('Gerenciar Carona'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRideInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
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
    });

    final url = Uri.parse('${AppConfig.baseUrl}/api/ride-requests/');
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      // sucesso
    } else {
      // erro
    }
  }
}
