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
import 'dart:async';
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/ride_service.dart';
import 'package:flutter/scheduler.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage>
    with WidgetsBindingObserver {
  int _currentPageIndex = 0;
  Map<String, dynamic>? _activeRide;
  bool _isLoadingRide = true;
  final AuthService _authService = AuthService();
  Timer? _autoRefreshTimer;

  // Lista de passageiros aceitos (paradas)
  List<Map<String, dynamic>> _acceptedPassengers = [];

  // Dados mocados dos passageiros disponíveis
  final List<Map<String, dynamic>> _availablePassengers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForActiveRide();
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    // Cancelar timer anterior se existir
    _autoRefreshTimer?.cancel();

    // Iniciar novo timer que atualiza a cada 30 segundos
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 DriverHomePage: Atualização automática iniciada');
      if (mounted) {
        _performAutoRefresh();
      } else {
        timer.cancel();
      }
    });

    print('⏰ DriverHomePage: Timer de atualização automática iniciado (30s)');
  }

  Future<void> _performAutoRefresh() async {
    print('🔄 DriverHomePage: Executando atualização automática...');

    try {
      // Verificar viagem ativa
      await _checkForActiveRide();

      // Se há viagem ativa, verificar solicitações pendentes
      if (_activeRide != null) {
        final rideId = RideService.extractRideId(_activeRide);
        if (RideService.isValidRideId(rideId)) {
          print(
            '🔄 DriverHomePage: Verificando solicitações pendentes para viagem $rideId',
          );
          // Aqui você pode adicionar lógica para verificar solicitações pendentes
          // e atualizar a lista de passageiros aceitos se necessário
        }
      }

      print('✅ DriverHomePage: Atualização automática concluída com sucesso');
    } catch (e) {
      print('❌ DriverHomePage: Erro na atualização automática: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Quando o app volta ao foco, verificar se há mudanças na viagem ativa
      print('📱 DriverHomePage: App retomado, verificando viagem ativa');
      _checkForActiveRide();
      _startAutoRefreshTimer(); // Retomar timer
    } else if (state == AppLifecycleState.paused) {
      print('📱 DriverHomePage: App pausado, pausando timer');
      _autoRefreshTimer?.cancel(); // Pausar timer
    } else if (state == AppLifecycleState.detached) {
      print('📱 DriverHomePage: App fechado, cancelando timer');
      _autoRefreshTimer?.cancel(); // Cancelar timer
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verificar se há dados de passageiro aceito passados como argumentos
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      try {
        if (args.containsKey('acceptedPassenger')) {
          final acceptedPassenger =
              args['acceptedPassenger'] as Map<String, dynamic>;
          setState(() {
            _acceptedPassengers.add(acceptedPassenger);
          });
        }

        // Verificar se a corrida foi iniciada
        if (args.containsKey('rideStarted') && args['rideStarted'] == true) {
          print('🚀 Processando corrida iniciada...');

          final acceptedPassengers =
              args['acceptedPassengers'] as List<Map<String, dynamic>>? ?? [];
          final startLocation =
              args['startLocation'] as String? ?? 'Não informado';
          final endLocation = args['endLocation'] as String? ?? 'Não informado';

          print('📊 Dados recebidos:');
          print('  - Passageiros: ${acceptedPassengers.length}');
          print('  - Início: $startLocation');
          print('  - Fim: $endLocation');

          setState(() {
            _acceptedPassengers = acceptedPassengers;
          });

          // Mostrar mensagem de sucesso após o build
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Corrida iniciada com ${acceptedPassengers.length} passageiro(s)!',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });

          // Print das coordenadas no console
          print('=== CORRIDA INICIADA - TELA HOME ===');
          print('📍 Ponto inicial: $startLocation');
          print('🎯 Ponto final: $endLocation');
          print('👥 Total de passageiros: ${acceptedPassengers.length}');

          if (acceptedPassengers.isNotEmpty) {
            print('📋 DETALHES DOS PASSAGEIROS:');
            for (int i = 0; i < acceptedPassengers.length; i++) {
              final passenger = acceptedPassengers[i];
              print('${i + 1}. ${passenger['name'] ?? 'Sem nome'}:');
              print(
                '   📍 Início: ${passenger['startLocation'] ?? 'Não informado'}',
              );
              print(
                '   🎯 Fim: ${passenger['endLocation'] ?? 'Não informado'}',
              );
              print('   📞 Tel: ${passenger['phone'] ?? 'Não informado'}');
            }
          }
          print('=== FIM DOS DETALHES ===');
        }
      } catch (e) {
        print('❌ ERRO ao processar argumentos: $e');
        // Mostrar erro após o build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao processar dados da corrida: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }

    // Verificar viagem ativa quando a tela volta ao foco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveRide();
    });
  }

  Future<void> _checkForActiveRide() async {
    final currentUser = _authService.currentUser;
    if (currentUser?.userId == null) {
      print(
        'DriverHomePage: Usuário não autenticado, pulando verificação de viagem ativa',
      );
      setState(() => _isLoadingRide = false);
      return;
    }

    print(
      'DriverHomePage: Verificando viagem ativa para usuário ${currentUser!.userId}',
    );

    try {
      final activeRide = await RideService.getActiveRideForDriver(
        currentUser!.userId!,
      );
      if (mounted) {
        final hadActiveRide = _activeRide != null;
        final hasActiveRide = activeRide != null;

        setState(() {
          _activeRide = activeRide;
          _isLoadingRide = false;
        });

        // Log das mudanças
        if (!hadActiveRide && hasActiveRide) {
          print(
            '✅ DriverHomePage: Nova viagem ativa encontrada: ${activeRide!['id']}',
          );
        } else if (hadActiveRide && !hasActiveRide) {
          print('❌ DriverHomePage: Viagem ativa foi removida');
        } else if (hadActiveRide && hasActiveRide) {
          final oldId = _activeRide?['id'];
          final newId = activeRide?['id'];
          if (oldId != newId) {
            print('🔄 DriverHomePage: Viagem ativa alterada: $oldId -> $newId');
          } else {
            print('✅ DriverHomePage: Viagem ativa mantida: $newId');
          }
        } else {
          print('ℹ️ DriverHomePage: Nenhuma viagem ativa encontrada');
        }
      }
    } catch (e) {
      print('Erro ao verificar viagem ativa: $e');
      if (mounted) {
        setState(() => _isLoadingRide = false);
      }
    }
  }

  // Widget da página inicial do motorista
  Widget _buildDriverHomePage() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool corridaIniciada = args != null && args['rideStarted'] == true;
    final List<Map<String, dynamic>> passageiros =
        args?['acceptedPassengers'] as List<Map<String, dynamic>>? ??
        _acceptedPassengers;
    final motorista = args?['driver'];
    final String startLocation =
        args?['startLocation'] ??
        _activeRide?['startLocation'] ??
        'Não informado';
    final String endLocation =
        args?['endLocation'] ?? _activeRide?['endLocation'] ?? 'Não informado';

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
                      passageiros.isNotEmpty
                          ? 'Paradas confirmadas: ${passageiros.length}'
                          : 'Passageiros disponíveis:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                _buildActionButton(),
              ],
            ),
          ),

          // Seção de informações da corrida iniciada
          if (corridaIniciada) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corrida em andamento',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (motorista != null) ...[
                    Text('Motorista: ${motorista['name']}'),
                    Text('Telefone: ${motorista['phone'] ?? 'Não informado'}'),
                    Text('Email: ${motorista['email'] ?? 'Não informado'}'),
                  ],
                  Text('Origem: $startLocation'),
                  Text('Destino: $endLocation'),
                  const SizedBox(height: 12),
                  if (passageiros.isNotEmpty) ...[
                    Text(
                      'Passageiros:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...passageiros.map((p) => _buildAcceptedPassengerCard(p)),
                  ],
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Cancelar Corrida',
                    variant: ButtonVariant.secondary,
                    onPressed: () async {
                      // Chamar cancelamento da viagem ativa com validação robusta
                      final rideId =
                          RideService.extractRideId(_activeRide) ??
                          RideService.extractRideId(args);
                      if (RideService.isValidRideId(rideId)) {
                        print(
                          'DriverHomePage: RideId para cancelamento: $rideId',
                        );
                        final int rideIdInt = rideId!;
                        print(
                          'DriverHomePage: RideId convertido para int: $rideIdInt',
                        );

                        final success = await RideService.cancelRide(rideIdInt);
                        if (success && mounted) {
                          print('DriverHomePage: Viagem cancelada com sucesso');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Corrida cancelada com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Resetar estado
                          setState(() {
                            _activeRide = null;
                            _acceptedPassengers.clear();
                          });
                          // Remover argumentos da rota
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/driverHome',
                            (route) => false,
                          );
                        } else {
                          print('DriverHomePage: Erro ao cancelar viagem');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao cancelar corrida'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        print(
                          'DriverHomePage: ERRO - RideId não encontrado ou inválido para cancelamento',
                        );
                        print('DriverHomePage: _activeRide: $_activeRide');
                        print('DriverHomePage: args: $args');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Erro: ID da viagem não encontrado ou inválido',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],

          // Seção de paradas (passageiros aceitos)
          if (!corridaIniciada && _acceptedPassengers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paradas Confirmadas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_acceptedPassengers.map(
                    (passenger) => _buildAcceptedPassengerCard(passenger),
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],

          // Lista de passageiros disponíveis
          if (!corridaIniciada)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:
                    _acceptedPassengers.isNotEmpty
                        ? const Center(
                          child: Text(
                            'Não há mais solicitações pendentes',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _availablePassengers.length,
                          itemBuilder: (context, index) {
                            final passenger = _availablePassengers[index];
                            if ((passenger['user']?['name'] ??
                                        passenger['name']) !=
                                    null &&
                                (passenger['user']?['phone'] ??
                                        passenger['phone']) !=
                                    null) {
                              return AvailablePassengerCard(
                                name:
                                    passenger['user']?['name'] ??
                                    passenger['name'] ??
                                    'Passageiro',
                                location: passenger['location'],
                                phoneNumber:
                                    passenger['user']?['phone'] ??
                                    passenger['phone'] ??
                                    'Não informado',
                                imageUrl: passenger['imageUrl'],
                                rating: passenger['rating'],
                                onAccept: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Passageiro ${passenger['user']?['name'] ?? passenger['name']} aceito!',
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                              );
                            }
                            return Container();
                          },
                        ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcceptedPassengerCard(Map<String, dynamic> passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar do passageiro
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),

          // Informações do passageiro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger['name'] ?? 'Passageiro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      passenger['phone'] ?? 'Não informado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${passenger['startLocation']} → ${passenger['endLocation']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status de aceito
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aceito',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
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

    // Se a corrida foi iniciada, não mostrar botão de gerenciar
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['rideStarted'] == true) {
      return const SizedBox.shrink();
    }

    if (_activeRide != null) {
      // Verificar se a viagem já partiu (status diferente de PENDING)
      final rideStatus =
          _activeRide!['status']?.toString()?.toUpperCase() ?? 'PENDING';
      final statusesQueIndicamPartida = [
        'IN_PROGRESS',
        'COMPLETED',
        'CANCELLED',
        'FINISHED',
      ];

      if (statusesQueIndicamPartida.contains(rideStatus)) {
        print(
          'DriverHomePage: Viagem já partiu ou foi finalizada (status: $rideStatus), ocultando botão Gerenciar Viagem',
        );

        // Retornar um widget informativo em vez de um espaço vazio
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
              const SizedBox(width: 6),
              Text(
                _getStatusMessage(rideStatus),
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return CustomButton(
        text: 'Gerenciar Viagem',
        variant: ButtonVariant.primary,
        icon: Icons.directions_car,
        onPressed: () {
          final extractedRideId = RideService.extractRideId(_activeRide);
          if (!RideService.isValidRideId(extractedRideId)) {
            print(
              'DriverHomePage: ERRO - RideId inválido para gerenciar viagem',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro: ID da viagem inválido'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final rideData = {
            'driverId': _activeRide!['driverId'],
            'rideId': extractedRideId,
            'id': extractedRideId,
            'startLocation': _activeRide!['startLocation'],
            'endLocation': _activeRide!['endLocation'],
            'departureTime': _activeRide!['departureTime'],
            'date': 'Hoje',
            'totalSeats': _activeRide!['totalSeats'],
            'distance': _activeRide!['distance'].toString(),
            'vehicleBrand': _activeRide!['vehicle']?['brand'],
            'vehicleModel': _activeRide!['vehicle']?['model'],
            'acceptedPassengers': _acceptedPassengers,
            'status': _activeRide!['status'] ?? 'PENDING',
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Motorista'),
            const SizedBox(width: 8),
            // Indicador de atualização automática
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync,
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '30s',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar agora',
            onPressed: () {
              print('🔄 DriverHomePage: Atualização manual solicitada');
              setState(() {
                _isLoadingRide = true;
              });
              _checkForActiveRide();
            },
          ),
        ],
      ),
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
}
