import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_app/components/available_passenger_card.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/services/ride_service.dart';

class RideStartPage extends StatefulWidget {
  const RideStartPage({super.key});

  @override
  State<RideStartPage> createState() => _RideStartPageState();
}

class _RideStartPageState extends State<RideStartPage> {
  Map<String, dynamic>? _rideData;
  List<Map<String, dynamic>> _rideRequests = [];
  bool _isLoadingRequests = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      debugPrint('RideStartPage: Args recebidos: $args');
      debugPrint('RideStartPage: Tipo dos args: ${args.runtimeType}');

      if (args is Map<String, dynamic>) {
        debugPrint('RideStartPage: RideData completo: $args');
        debugPrint('RideStartPage: DriverId: ${args['driverId']}');
        debugPrint(
          'RideStartPage: Tipo do driverId: ${args['driverId']?.runtimeType}',
        );

        setState(() {
          _rideData = args;
        });
        _loadRideRequests();
        _startRefreshTimer();
      } else {
        debugPrint('RideStartPage: Args não é um Map<String, dynamic>');
        setState(() {
          _errorMessage = 'Dados da viagem inválidos';
          _isLoadingRequests = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('Timer: Atualizando solicitações de carona...');
      _loadRideRequests(showLoading: false);
    });
  }

  Future<void> _loadRideRequests({bool showLoading = true}) async {
    debugPrint('RideStartPage: _loadRideRequests chamado');
    debugPrint('RideStartPage: _rideData: $_rideData');

    if (_rideData == null) {
      debugPrint('RideStartPage: _rideData é null');
      setState(() {
        _isLoadingRequests = false;
        _errorMessage = 'Dados da viagem não encontrados';
      });
      return;
    }

    final driverId = _rideData!['driverId'];
    debugPrint('RideStartPage: driverId extraído: $driverId');
    debugPrint('RideStartPage: tipo do driverId: ${driverId.runtimeType}');

    if (driverId == null) {
      debugPrint('RideStartPage: driverId é null');
      setState(() {
        _isLoadingRequests = false;
        _errorMessage = 'ID do motorista não encontrado';
      });
      return;
    }

    try {
      if (showLoading) {
        setState(() {
          _isLoadingRequests = true;
          _errorMessage = null;
        });
      }

      // Converter para int se necessário
      final int driverIdInt =
          driverId is int ? driverId : int.parse(driverId.toString());
      debugPrint('RideStartPage: driverId convertido para int: $driverIdInt');

      final requests = await RideService.getRideRequestsByDriver(driverIdInt);

      if (mounted) {
        setState(() {
          _rideRequests = requests;
          if (showLoading) {
            _isLoadingRequests = false;
          }
        });
      }
    } catch (e) {
      debugPrint('RideStartPage: Erro ao carregar solicitações: $e');
      if (mounted) {
        setState(() {
          if (showLoading) {
            _isLoadingRequests = false;
          }
          _errorMessage = 'Erro ao carregar solicitações: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aguardando Passageiros'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driverHome',
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Informações da viagem
            if (_rideData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes da Viagem',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('📍 De:', _rideData!['startLocation']),
                    _buildInfoRow('🎯 Para:', _rideData!['endLocation']),
                    _buildInfoRow(
                      '⏰ Saída:',
                      '${_rideData!['date']} às ${_rideData!['departureTime']}',
                    ),
                    _buildInfoRow('💺 Vagas:', _rideData!['seats']),
                    _buildInfoRow('📏 Distância:', _rideData!['distance']),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Timer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tempo restante: 04:59',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Solicitações de carona:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildRequestsList()),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                onPressed: () {
                  // Logic to cancel the ride
                  Navigator.pop(context);
                },
                variant: ButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Iniciar Corrida',
                onPressed: () {
                  // Logic to start the ride and open maps
                  if (_rideData != null) {
                    _startRide();
                  }
                },
                variant: ButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoadingRequests) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando solicitações...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Tentar Novamente',
              onPressed: () => _loadRideRequests(),
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      );
    }

    if (_rideRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma solicitação de carona ainda',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _rideRequests.length,
      itemBuilder: (context, index) {
        final request = _rideRequests[index];

        // Log todas as informações do card
        debugPrint('=== CARD DE SOLICITAÇÃO $index ===');
        debugPrint('Dados completos: $request');
        debugPrint('Chaves disponíveis: ${request.keys.toList()}');

        // Log informações específicas
        debugPrint('ID: ${request['id']}');
        debugPrint('RequestId: ${request['requestId']}');
        debugPrint('RideRequestId: ${request['rideRequestId']}');
        debugPrint('PassengerName: ${request['passengerName']}');
        debugPrint('UserName: ${request['userName']}');
        debugPrint('PickupLocation: ${request['pickupLocation']}');
        debugPrint('StartLocation: ${request['startLocation']}');
        debugPrint('PhoneNumber: ${request['phoneNumber']}');
        debugPrint('Phone: ${request['phone']}');
        debugPrint('ProfileImage: ${request['profileImage']}');
        debugPrint('Rating: ${request['rating']}');
        debugPrint('Status: ${request['status']}');
        debugPrint('RideId: ${request['rideId']}');
        debugPrint('UserId: ${request['userId']}');
        debugPrint('CreatedAt: ${request['createdAt']}');
        debugPrint('================================');

        // Extrair dados do passageiro de forma segura
        final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
        final user = passenger['user'] as Map<String, dynamic>? ?? {};
        final name = user['name'] ?? passenger['name'] ?? 'Passageiro';
        final phoneNumber =
            user['phone'] ?? passenger['phone'] ?? 'Não informado';
        final imageUrl =
            user['profileImageUrl'] ??
            passenger['profileImageUrl'] ??
            'assets/images/profile1.png';

        return AvailablePassengerCard(
          name: name,
          location: request['startLocation'] ?? 'Local não informado',
          phoneNumber: phoneNumber,
          imageUrl: imageUrl,
          rating: (request['rating'] as num? ?? 4.0).toDouble(),
          onAccept: () {
            _acceptRequest(request);
          },
        );
      },
    );
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      // Extrair o ID da solicitação
      final requestId =
          request['id'] ?? request['requestId'] ?? request['rideRequestId'];

      if (requestId == null) {
        debugPrint('RideStartPage: ID da solicitação não encontrado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da solicitação não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('RideStartPage: Aceitando solicitação com ID: $requestId');

      // Converter para int se necessário
      final int requestIdInt =
          requestId is int ? requestId : int.parse(requestId.toString());

      // Enviar requisição PATCH para aceitar a solicitação
      final success = await RideService.updateRideRequestStatus(
        requestIdInt,
        'APPROVED',
      );

      if (success && mounted) {
        // Remover a solicitação da lista ou marcar como aceita
        setState(() {
          _rideRequests.removeWhere(
            (req) =>
                (req['id'] ?? req['requestId'] ?? req['rideRequestId']) ==
                requestId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitação de ${request['passengerName'] ?? request['userName'] ?? 'passageiro'} aceita!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('RideStartPage: Erro ao aceitar solicitação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar solicitação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startRide() {
    // Aqui você pode implementar a lógica para abrir o mapa
    // Por exemplo, construir uma URL do Google Maps com origem e destino
    final startLocation = _rideData!['startLocation'];
    final endLocation = _rideData!['endLocation'];

    // Exemplo de URL do Google Maps (você precisará implementar a abertura)
    final mapsUrl =
        'https://www.google.com/maps/dir/$startLocation/$endLocation';

    debugPrint('Abrindo mapa com URL: $mapsUrl');

    // TODO: Implementar abertura do mapa
    // TODO: Navegar para tela de "Corrida em Andamento"
  }
}
