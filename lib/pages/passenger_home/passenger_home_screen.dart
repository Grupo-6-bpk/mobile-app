// caronas_screen.dart
import 'dart:convert';
import 'dart:async';

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
import 'package:mobile_app/config/app_config.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with
        AutomaticKeepAliveClientMixin<PassengerHomeScreen>,
        WidgetsBindingObserver {
  late Future<List<Ride>> _ridesFuture;
  final authService = AuthService();
  int? passengerId;
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ridesFuture = RideService.getRides();
    passengerId = authService.currentUser?.userId;
    _startAutoRefreshTimer();
    _checkForAcceptedRequests();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 PassengerHomeScreen: App retomado, retomando timer');
      _startAutoRefreshTimer(); // Retomar timer
    } else if (state == AppLifecycleState.paused) {
      debugPrint('📱 PassengerHomeScreen: App pausado, pausando timer');
      _autoRefreshTimer?.cancel(); // Pausar timer
    } else if (state == AppLifecycleState.detached) {
      debugPrint('📱 PassengerHomeScreen: App fechado, cancelando timer');
      _autoRefreshTimer?.cancel(); // Cancelar timer
    }
  }

  void _startAutoRefreshTimer() {
    // Cancelar timer anterior se existir
    _autoRefreshTimer?.cancel();

    // Iniciar novo timer que atualiza a cada 30 segundos
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('🔄 PassengerHomeScreen: Atualização automática iniciada');
      if (mounted) {
        _performAutoRefresh();
      } else {
        timer.cancel();
      }
    });

    debugPrint(
      '⏰ PassengerHomeScreen: Timer de atualização automática iniciado (30s)',
    );
  }

  Future<void> _performAutoRefresh() async {
    if (_isRefreshing) {
      debugPrint(
        '⏳ PassengerHomeScreen: Atualização já em andamento, pulando...',
      );
      return;
    }

    debugPrint('🔄 PassengerHomeScreen: Executando atualização automática...');
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Recarregar a lista de caronas
      _ridesFuture = RideService.getRides();

      // Verificar solicitações aceitas
      await _checkForAcceptedRequests();

      // Forçar rebuild do FutureBuilder
      setState(() {
        _ridesFuture = RideService.getRides();
      });

      debugPrint(
        '✅ PassengerHomeScreen: Atualização automática concluída com sucesso',
      );
    } catch (e) {
      debugPrint('❌ PassengerHomeScreen: Erro na atualização automática: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _manualRefresh() {
    debugPrint('🔄 PassengerHomeScreen: Atualização manual solicitada');
    _performAutoRefresh();
  }

  void showPassagerDetailHome(BuildContext context, Ride ride) {
    // Verificar se a viagem ainda está disponível
    if (ride.status.toUpperCase() != 'PENDING') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Esta carona já não está mais disponível (status: ${ride.status})',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      // Use a slightly transparent barrier color
      barrierColor: theme.colorScheme.onSurface.withAlpha((255 * 0.8).toInt()),
      builder:
          (_) => Center(
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

  Future<void> _checkForAcceptedRequests() async {
    if (passengerId == null) return;

    try {
      final int passengerIdInt = passengerId!;
      final requests = await RideService.getRideRequestsByPassenger(
        passengerIdInt,
      );
      final acceptedRequests =
          requests
              .where(
                (req) => req['status']?.toString().toUpperCase() == 'APPROVED',
              )
              .toList();

      if (acceptedRequests.isNotEmpty && mounted) {
        // Mostrar notificação para cada solicitação aceita
        for (final request in acceptedRequests) {
          final rideId = request['rideId'];
          if (rideId != null) {
            try {
              final int rideIdInt =
                  rideId is int ? rideId : int.parse(rideId.toString());
              final rideDetails = await RideService.getRideById(rideIdInt);
              if (rideDetails != null) {
                final driverName =
                    rideDetails['driver']?['name'] ?? 'Motorista';

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sua solicitação foi aceita por $driverName! 🎉',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(16),
                      action: SnackBarAction(
                        label: 'Ver',
                        textColor: Colors.white,
                        onPressed: () {
                          // Aqui você pode navegar para uma tela de detalhes da viagem aceita
                          debugPrint(
                            'Navegar para detalhes da viagem aceita: $rideId',
                          );
                        },
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('Erro ao buscar detalhes da viagem: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar solicitações aceitas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Importante para o AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Caronas',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            // Indicador de atualização automática
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                _isRefreshing
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
            tooltip: 'Atualizar agora',
            onPressed: _isRefreshing ? null : _manualRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com saudação
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boa tarde, Gabriel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encontre sua carona ideal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Seção de caronas disponíveis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Caronas Disponíveis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (_isRefreshing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Atualizando...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista de caronas
            Expanded(
              child: FutureBuilder<List<Ride>>(
                future: _ridesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Carregando caronas...',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar caronas',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma carona encontrada',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente novamente mais tarde',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final rides = snapshot.data!;

                  // Filtrar apenas viagens com status PENDING (que ainda não partiram)
                  final availableRides =
                      rides.where((ride) {
                        final status = ride.status.toUpperCase();
                        final isAvailable = status == 'PENDING';
                        if (!isAvailable) {
                          debugPrint(
                            'PassengerHomeScreen: Ocultando viagem ${ride.id} - status: $status',
                          );
                        }
                        return isAvailable;
                      }).toList();

                  if (availableRides.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma carona disponível',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aguarde novas caronas serem criadas',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: availableRides.length,
                    itemBuilder: (context, index) {
                      final ride = availableRides[index];
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
    );
  }
}

class CaronaCard extends StatefulWidget {
  final Ride ride;
  final VoidCallback onTap;

  const CaronaCard({super.key, required this.ride, required this.onTap});

  @override
  State<CaronaCard> createState() => _CaronaCardState();
}

class _CaronaCardState extends State<CaronaCard> {
  bool _isRequested = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRequested();
  }

  Future<void> _checkIfAlreadyRequested() async {
    try {
      final authService = AuthService();
      final passengerId = authService.currentUser?.passenger?.id;

      if (passengerId != null) {
        final requests = await RideService.getRideRequestsByPassenger(
          passengerId,
        );
        final alreadyRequested = requests.any(
          (req) =>
              (req['rideId'] == widget.ride.id) &&
              (req['status'] == null ||
                  req['status'].toString().toUpperCase() == 'PENDING' ||
                  req['status'].toString().toUpperCase() == 'APPROVED'),
        );

        if (mounted) {
          setState(() {
            _isRequested = alreadyRequested;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar solicitações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('HH:mm').format(widget.ride.departureTime);
    final formattedPrice = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(widget.ride.pricePerMember ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com avatar e informações do motorista
            Row(
              children: [
                // Avatar do motorista
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Informações do motorista
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<User>(
                        future: UserService.getUserById(
                          widget.ride.driver.userId,
                        ),
                        builder: (context, userSnapshot) {
                          String displayName;
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            displayName = 'Carregando...';
                          } else if (userSnapshot.hasError ||
                              !userSnapshot.hasData) {
                            displayName =
                                '${widget.ride.vehicle.brand} ${widget.ride.vehicle.model}';
                          } else {
                            displayName = userSnapshot.data!.name;
                          }
                          return Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.ride.vehicle.brand} ${widget.ride.vehicle.model} • ${widget.ride.vehicle.plate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão de detalhes
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: widget.onTap,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informações da viagem
            Row(
              children: [
                // Local de partida
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.location_on,
                    'De',
                    widget.ride.startLocation,
                  ),
                ),
                const SizedBox(width: 16),
                // Local de destino
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.location_on_outlined,
                    'Para',
                    widget.ride.endLocation,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Horário e preço
            Row(
              children: [
                // Horário
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.access_time,
                    'Saída',
                    formattedTime,
                  ),
                ),
                const SizedBox(width: 16),
                // Preço
                Expanded(
                  child: _buildInfoItem(
                    context,
                    Icons.attach_money,
                    'Valor',
                    formattedPrice,
                    isPrice: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer com avaliação e botão
            Row(
              children: [
                // Avaliação
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < 4 ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFD700),
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
                // Botão solicitar
                _buildRequestButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestButton(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 100,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_isRequested) {
      return Container(
        width: 100,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Solicitado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomButton(
      text: "Solicitar",
      onPressed: () {
        // Verificar se a viagem ainda está disponível
        if (widget.ride.status.toUpperCase() != 'PENDING') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Esta carona já não está mais disponível (status: ${widget.ride.status})',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _onSolicitarPressed(context);
      },
      variant: ButtonVariant.primary,
      height: 36,
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isPrice = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isPrice
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isPrice ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onSolicitarPressed(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verifica e solicita permissão de localização, se necessário
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && context.mounted) {
          // Permissão negada
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização permanentemente negada.'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
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

      if (passengerId == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não autenticado ou não é passageiro!'),
          ),
        );
        return;
      }

      // Verificar se já existe solicitação pendente/aprovada para o passageiro nesta viagem
      final requests = await RideService.getRideRequestsByPassenger(
        passengerId!,
      );
      final alreadyRequested = requests.any(
        (req) =>
            (req['rideId'] == widget.ride.id) &&
            (req['status'] == null ||
                req['status'].toString().toUpperCase() == 'PENDING' ||
                req['status'].toString().toUpperCase() == 'APPROVED'),
      );
      if (alreadyRequested && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Você já possui uma solicitação pendente ou aprovada para esta viagem.',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
          _isRequested = true;
        });
        return;
      }

      await criarSolicitacaoCarona(
        startLocation,
        endLocation,
        widget.ride.id,
        passengerId,
      );

      if (context.mounted) {
        setState(() {
          _isLoading = false;
          _isRequested = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solicitação enviada com sucesso!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar solicitação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

Future<void> criarSolicitacaoCarona(
  String startLocation,
  String endLocation,
  int rideId,
  int passengerId,
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
    'passengerId': passengerId,
  });

  final url = Uri.parse('${AppConfig.baseUrl}/api/ride-requests/');
  final response = await http.post(url, headers: headers, body: body);

  debugPrint('Status: ${response.statusCode}');
  debugPrint('Response: ${response.body}');

  if (response.statusCode == 201 || response.statusCode == 200) {
    // sucesso
  } else {
    // erro
  }
}
