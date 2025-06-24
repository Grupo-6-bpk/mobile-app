import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_app/components/available_passenger_card.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/services/ride_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/auth_service.dart';

class RideStartPage extends StatefulWidget {
  const RideStartPage({super.key});

  @override
  State<RideStartPage> createState() => _RideStartPageState();
}

class _RideStartPageState extends State<RideStartPage> {
  Map<String, dynamic>? _rideData;
  List<Map<String, dynamic>> _rideRequests = [];
  List<Map<String, dynamic>> _acceptedPassengers = [];
  bool _isLoadingRequests = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      print('RideStartPage: Args recebidos: $args');
      print('RideStartPage: Tipo dos args: ${args.runtimeType}');
      
      if (args is Map<String, dynamic>) {
        print('RideStartPage: RideData completo: $args');
        print('RideStartPage: DriverId: ${args['driverId']}');
        print('RideStartPage: Tipo do driverId: ${args['driverId']?.runtimeType}');
        print('RideStartPage: RideId: ${args['rideId']}');
        print('RideStartPage: Id: ${args['id']}');
        print('RideStartPage: TotalSeats: ${args['totalSeats']}');
        print('RideStartPage: Seats: ${args['seats']}');
        print('RideStartPage: Tipo do totalSeats: ${args['totalSeats']?.runtimeType}');
        print('RideStartPage: Tipo do seats: ${args['seats']?.runtimeType}');
        
        // VALIDAÇÃO CRÍTICA: Verificar se o rideId está presente
        final rideId = RideService.extractRideId(args);
        if (!RideService.isValidRideId(rideId)) {
          print('RideStartPage: ERRO - RideId não encontrado ou inválido nos argumentos');
          print('RideStartPage: RideId extraído: $rideId');
          setState(() {
            _errorMessage = 'ID da viagem não encontrado ou inválido';
            _isLoadingRequests = false;
          });
          return;
        }
        
        print('RideStartPage: RideId validado: $rideId');
        
        setState(() {
          _rideData = args;
          if (args.containsKey('acceptedPassengers')) {
            _acceptedPassengers = List<Map<String, dynamic>>.from(args['acceptedPassengers'] ?? []);
          }
        });
        
        print('RideStartPage: _rideData definido: $_rideData');
        print('RideStartPage: totalSeats no _rideData: ${_rideData?['totalSeats']}');
        print('RideStartPage: seats no _rideData: ${_rideData?['seats']}');
        print('RideStartPage: status no _rideData: ${_rideData?['status']}');
        
        // Usar o campo correto para totalSeats
        final totalSeats = _rideData?['totalSeats'] ?? _rideData?['seats'] ?? 0;
        print('RideStartPage: TotalSeats final: $totalSeats');
        
        // Se não há status definido, assumir PENDING
        if (_rideData != null && !_rideData!.containsKey('status')) {
          _rideData!['status'] = 'PENDING';
          print('RideStartPage: Status não encontrado, definindo como PENDING');
        }
        
        _loadRideRequests();
        _startRefreshTimer();
      } else {
        print('RideStartPage: Args não é um Map<String, dynamic>');
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
      print('Timer: Atualizando solicitações de carona...');
      _loadRideRequests(showLoading: false);
    });
  }

  Future<void> _loadRideRequests({bool showLoading = true}) async {
    print('RideStartPage: _loadRideRequests chamado');
    print('RideStartPage: _rideData: $_rideData');
    
    if (_rideData == null) {
      print('RideStartPage: _rideData é null');
      setState(() {
        _isLoadingRequests = false;
        _errorMessage = 'Dados da viagem não encontrados';
      });
      return;
    }

    final driverId = _rideData!['driverId'];
    print('RideStartPage: driverId extraído: $driverId');
    print('RideStartPage: tipo do driverId: ${driverId.runtimeType}');
    
    if (driverId == null) {
      print('RideStartPage: driverId é null');
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
      final int driverIdInt = driverId is int ? driverId : int.parse(driverId.toString());
      print('RideStartPage: driverId convertido para int: $driverIdInt');
      
      final requests = await RideService.getRideRequestsByDriver(driverIdInt);
      
      if (mounted) {
        // Filtrar apenas solicitações PENDING para mostrar na lista de pendentes
        final pendingRequests = requests.where((request) {
          final status = request['status']?.toString().toUpperCase();
          return status == 'PENDING';
        }).toList();
        
        // Separar solicitações aprovadas para mostrar na lista de aceitos
        final approvedRequests = requests.where((request) {
          final status = request['status']?.toString().toUpperCase();
          return status == 'APPROVED';
        }).toList();
        
        print('RideStartPage: Total de solicitações: ${requests.length}');
        print('RideStartPage: Solicitações pendentes: ${pendingRequests.length}');
        print('RideStartPage: Solicitações aprovadas: ${approvedRequests.length}');
        
        setState(() {
          _rideRequests = pendingRequests;
          
          // Converter solicitações aprovadas para o formato de passageiros aceitos
          _acceptedPassengers = approvedRequests.map((request) {
            final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
            final passengerUserId = passenger['userId'];
            
            return {
              'id': request['id'],
              'userId': passengerUserId,
              'name': 'Passageiro ${passengerUserId ?? 'Desconhecido'}', // Será atualizado pelo UserService
              'phone': 'Não informado', // Será atualizado pelo UserService
              'startLocation': request['startLocation'] ?? 'Não informado',
              'endLocation': request['endLocation'] ?? 'Não informado',
              'status': 'APPROVED',
            };
          }).toList();
          
          if (showLoading) {
            _isLoadingRequests = false;
          }
        });
        
        // Buscar dados completos dos passageiros aprovados
        await _loadAcceptedPassengersData();
      }
    } catch (e) {
      print('RideStartPage: Erro ao carregar solicitações: $e');
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

  Future<void> _loadAcceptedPassengersData() async {
    print('RideStartPage: Carregando dados completos dos passageiros aprovados...');
    
    for (int i = 0; i < _acceptedPassengers.length; i++) {
      final passenger = _acceptedPassengers[i];
      final userId = passenger['userId'];
      
      if (userId != null) {
        try {
          final int userIdInt = userId is int ? userId : int.parse(userId.toString());
          final user = await UserService.getUserById(userIdInt);
          
          setState(() {
            _acceptedPassengers[i]['name'] = user.name;
            _acceptedPassengers[i]['phone'] = user.phone ?? 'Não informado';
          });
          
          print('RideStartPage: Dados do passageiro $userId carregados: ${user.name}');
        } catch (e) {
          print('RideStartPage: Erro ao carregar dados do passageiro $userId: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Gerenciar Viagem',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/driverHome', 
              (route) => false
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Informações da viagem
            if (_rideData != null) ...[
              _buildRideInfoCard(),
              const SizedBox(height: 16),
            ],
            
            // Timer
            _buildTimerCard(),
            const SizedBox(height: 20),
            
            // Seção de passageiros aceitos
            if (_acceptedPassengers.isNotEmpty) ...[
              _buildAcceptedPassengersSection(),
              const SizedBox(height: 20),
            ],
            
            // Seção de solicitações pendentes
            Expanded(child: _buildPendingRequestsSection()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildRideInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes da Viagem',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'De:', _rideData!['startLocation']),
          _buildInfoRow(Icons.location_on_outlined, 'Para:', _rideData!['endLocation']),
          _buildInfoRow(Icons.access_time, 'Saída:', '${_rideData!['date']} às ${_rideData!['departureTime']}'),
          _buildInfoRow(Icons.event_seat, 'Vagas:', () {
            final totalSeats = _rideData!['totalSeats'] ?? _rideData!['seats'] ?? 0;
            final acceptedCount = _acceptedPassengers.length;
            final availableSeats = totalSeats - acceptedCount;
            return '$availableSeats/$totalSeats disponíveis';
          }()),
          _buildInfoRow(Icons.straighten, 'Distância:', _rideData!['distance']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Tempo restante: 04:59',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedPassengersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Confirmados (${_acceptedPassengers.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _acceptedPassengers.length,
            itemBuilder: (context, index) {
              final passenger = _acceptedPassengers[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        (passenger['name'] ?? 'P')[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      passenger['name'] ?? 'Passageiro',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: Theme.of(context).colorScheme.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Solicitações Pendentes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRequestsList(),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    if (_isLoadingRequests) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'Carregando...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma solicitação',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aguarde passageiros solicitarem',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _rideRequests.length,
      itemBuilder: (context, index) {
        final request = _rideRequests[index];
        
        return FutureBuilder<Map<String, String>>(
          future: _getPassengerInfo(request),
          builder: (context, snapshot) {
            String name = 'Passageiro';
            String phoneNumber = 'Não informado';
            
            if (snapshot.hasData) {
              name = snapshot.data!['name'] ?? 'Passageiro';
              phoneNumber = snapshot.data!['phone'] ?? 'Não informado';
            }
            
            final imageUrl = 'assets/images/profile1.png';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: AvailablePassengerCard(
                name: name,
                location: request['startLocation'] ?? 'Local não informado',
                phoneNumber: phoneNumber,
                imageUrl: imageUrl,
                rating: (request['rating'] as num? ?? 4.0).toDouble(),
                onAccept: () {
                  _acceptRequest(request);
                },
                onReject: () {
                  _rejectRequest(request);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                onPressed: () {
                  _showCancelConfirmation();
                },
                variant: ButtonVariant.secondary,
                height: 48,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Iniciar',
                onPressed: () {
                  try {
                    print('🚀 Botão "Iniciar Corrida" pressionado');
                    print('📊 _rideData: $_rideData');
                    print('📊 _acceptedPassengers: ${_acceptedPassengers.length}');
                    
                    if (_rideData != null) {
                      _startRide();
                    } else {
                      print('❌ _rideData é null');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erro: Dados da viagem não carregados'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('❌ ERRO no botão Iniciar Corrida: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao iniciar corrida: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                variant: ButtonVariant.primary,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      // Extrair o ID da solicitação
      final requestId = request['id'] ?? request['requestId'] ?? request['rideRequestId'];
      if (requestId == null) {
        print('RideStartPage: ID da solicitação não encontrado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da solicitação não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Verificar status da solicitação
      final status = request['status']?.toString()?.toUpperCase();
      if (status != null && status != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta solicitação já foi processada.'), backgroundColor: Colors.red),
        );
        return;
      }
      
      // Verificar status da viagem
      final rideStatus = _rideData?['status']?.toString()?.toUpperCase() ?? 'PENDING';
      if (rideStatus != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não é possível aceitar solicitações para uma viagem já iniciada, finalizada ou cancelada.'), backgroundColor: Colors.red),
        );
        return;
      }

      // VALIDAÇÃO CRÍTICA: Verificar se a viagem já passou do horário de partida
      final departureTimeStr = _rideData?['departureTime'];
      if (departureTimeStr != null) {
        try {
          final departureTime = DateTime.parse(departureTimeStr);
          final currentTime = DateTime.now();
          
          print('RideStartPage: Horário de partida: $departureTime');
          print('RideStartPage: Horário atual: $currentTime');
          print('RideStartPage: Diferença: ${currentTime.difference(departureTime).inMinutes} minutos');
          
          // Se já passou mais de 5 minutos do horário de partida, não permitir aceitar
          if (currentTime.isAfter(departureTime.add(const Duration(minutes: 5)))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Não é possível aceitar solicitações após o horário de partida.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        } catch (e) {
          print('RideStartPage: Erro ao parsear horário de partida: $e');
        }
      }

      // Verificar se há vagas disponíveis
      final totalSeats = _rideData?['totalSeats'] ?? _rideData?['seats'] ?? 0;
      final acceptedCount = _acceptedPassengers.length;
      final availableSeats = totalSeats - acceptedCount;
      
      if (availableSeats <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há vagas disponíveis nesta viagem.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('RideStartPage: Aceitando solicitação com ID: $requestId');
      print('RideStartPage: Vagas disponíveis: $availableSeats/$totalSeats');
      
      // Converter para int se necessário
      final int requestIdInt = requestId is int ? requestId : int.parse(requestId.toString());
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aceitando...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Aceitar a solicitação no backend
      print('RideStartPage: Aceitando solicitação no backend...');
      final success = await RideService.updateRideRequestStatus(requestIdInt, 'APPROVED');
      
      Navigator.of(context).pop(); // Remove o loading

      if (!success) {
        print('❌ RideStartPage: Falha ao aceitar solicitação no backend');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aceitar solicitação'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('✅ RideStartPage: Solicitação aceita com sucesso');
      
      // Adicionar à lista de passageiros aceitos
      final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
      final passengerUserId = passenger['userId'];
      
      final newAcceptedPassenger = {
        'id': request['id'],
        'userId': passengerUserId,
        'name': 'Passageiro ${passengerUserId ?? 'Desconhecido'}',
        'phone': 'Não informado',
        'startLocation': request['startLocation'] ?? 'Não informado',
        'endLocation': request['endLocation'] ?? 'Não informado',
        'status': 'APPROVED',
      };
      
      setState(() {
        _acceptedPassengers.add(newAcceptedPassenger);
        _rideRequests.removeWhere((req) => req['id'] == requestId);
      });
      
      // Buscar dados completos do passageiro aceito
      if (passengerUserId != null) {
        await _loadPassengerData(newAcceptedPassenger, passengerUserId);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitação aceita'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      
    } catch (e) {
      print('❌ RideStartPage: ERRO ao aceitar solicitação: $e');
      Navigator.of(context).pop(); // Remove o loading se ainda estiver aberto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar solicitação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    try {
      print('RideStartPage: Rejeitando solicitação...');
      print('RideStartPage: Request data: $request');
      
      final requestId = request['id'];
      if (requestId == null) {
        print('❌ RideStartPage: ID da solicitação é null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da solicitação não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Verificar status da solicitação
      final status = request['status']?.toString()?.toUpperCase();
      if (status != null && status != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta solicitação já foi processada.'), backgroundColor: Colors.red),
        );
        return;
      }
      
      // Verificar status da viagem
      final rideStatus = _rideData?['status']?.toString()?.toUpperCase() ?? 'PENDING';
      if (rideStatus != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não é possível rejeitar solicitações para uma viagem já iniciada, finalizada ou cancelada.'), backgroundColor: Colors.red),
        );
        return;
      }

      // VALIDAÇÃO CRÍTICA: Verificar se a viagem já passou do horário de partida
      final departureTimeStr = _rideData?['departureTime'];
      if (departureTimeStr != null) {
        try {
          final departureTime = DateTime.parse(departureTimeStr);
          final currentTime = DateTime.now();
          
          print('RideStartPage: Horário de partida: $departureTime');
          print('RideStartPage: Horário atual: $currentTime');
          print('RideStartPage: Diferença: ${currentTime.difference(departureTime).inMinutes} minutos');
          
          // Se já passou mais de 5 minutos do horário de partida, não permitir rejeitar
          if (currentTime.isAfter(departureTime.add(const Duration(minutes: 5)))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Não é possível rejeitar solicitações após o horário de partida.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        } catch (e) {
          print('RideStartPage: Erro ao parsear horário de partida: $e');
        }
      }
      
      final int requestIdInt = requestId is int ? requestId : int.parse(requestId.toString());
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 12),
                Text(
                  'Rejeitando...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Rejeitar a solicitação no backend
      print('RideStartPage: Rejeitando solicitação no backend...');
      final success = await RideService.updateRideRequestStatus(requestIdInt, 'REJECTED');
      
      Navigator.of(context).pop(); // Remove o loading

      if (!success) {
        print('❌ RideStartPage: Falha ao rejeitar solicitação no backend');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao rejeitar solicitação'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('✅ RideStartPage: Solicitação rejeitada com sucesso');
      
      // Remover da lista local
      setState(() {
        _rideRequests.removeWhere((req) => req['id'] == requestId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitação rejeitada'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      
    } catch (e) {
      print('❌ RideStartPage: ERRO ao rejeitar solicitação: $e');
      Navigator.of(context).pop(); // Remove o loading se ainda estiver aberto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao rejeitar solicitação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPassengerData(Map<String, dynamic> passenger, dynamic userId) async {
    try {
      final int userIdInt = userId is int ? userId : int.parse(userId.toString());
      final user = await UserService.getUserById(userIdInt);
      
      setState(() {
        passenger['name'] = user.name;
        passenger['phone'] = user.phone ?? 'Não informado';
      });
      
      print('RideStartPage: Dados do passageiro $userIdInt carregados: ${user.name}');
    } catch (e) {
      print('RideStartPage: Erro ao carregar dados do passageiro $userId: $e');
    }
  }

  Future<Map<String, String>> _getPassengerInfo(dynamic request) async {
    try {
      // Extrair o userId do passageiro da estrutura da API
      final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
      final userId = passenger['userId'];
      
      if (userId == null) {
        return {
          'name': 'Passageiro',
          'phone': 'Não informado',
        };
      }
      
      final int userIdInt = userId is int ? userId : int.parse(userId.toString());
      final user = await UserService.getUserById(userIdInt);
      
      return {
        'name': user.name,
        'phone': user.phone ?? 'Não informado',
      };
    } catch (e) {
      print('Erro ao buscar dados do passageiro: $e');
      return {
        'name': 'Passageiro',
        'phone': 'Não informado',
      };
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Cancelar Viagem?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Esta ação não pode ser desfeita.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Não',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      variant: ButtonVariant.secondary,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Sim',
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _cancelRide();
                      },
                      variant: ButtonVariant.primary,
                      height: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelRide() async {
    // Verificar status da viagem
    final rideStatus = _rideData?['status']?.toString()?.toUpperCase() ?? 'PENDING';
    if (rideStatus != 'PENDING') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível cancelar uma viagem já iniciada, finalizada ou cancelada.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cancelando...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Extrair o rideId dos dados da viagem com validação robusta
      final rideId = RideService.extractRideId(_rideData);
      if (!RideService.isValidRideId(rideId)) {
        Navigator.of(context).pop(); // Remove o loading
        print('RideStartPage: ERRO - RideId não encontrado ou inválido para cancelamento');
        print('RideStartPage: Dados disponíveis: ${_rideData?.keys.toList()}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da viagem não encontrado ou inválido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('RideStartPage: RideId extraído para cancelamento: $rideId');

      // Converter para int se necessário
      final int rideIdInt = rideId!;
      print('RideStartPage: RideId convertido para int: $rideIdInt');
      
      // Cancelar a viagem no backend
      final success = await RideService.cancelRide(rideIdInt);
      
      Navigator.of(context).pop(); // Remove o loading

      if (success) {
        print('RideStartPage: Viagem cancelada com sucesso no backend');
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem cancelada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Voltar para a tela inicial mostrando informações
        final authService = AuthService();
        final driver = authService.currentUser;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/driverHome',
          (route) => false,
          arguments: {
            'rideCancelled': true,
            'rideId': rideIdInt, // Incluir rideId nos argumentos
            'acceptedPassengers': _acceptedPassengers,
            'startLocation': _rideData!['startLocation'],
            'endLocation': _rideData!['endLocation'],
            'driver': driver != null ? {
              'userId': driver.userId,
              'name': driver.name,
              'phone': driver.phone,
              'email': driver.email,
            } : null,
          }
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao cancelar viagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Remove o loading
      print('RideStartPage: Erro ao cancelar viagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar viagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startRide() async {
    // Verificar se _rideData existe
    if (_rideData == null) {
      print('❌ ERRO: _rideData é null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Dados da viagem não encontrados'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Verificar se há pelo menos um passageiro aceito
    if (_acceptedPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('É necessário pelo menos um passageiro aceito para iniciar a viagem.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Verificar status da viagem
    final rideStatus = _rideData?['status']?.toString()?.toUpperCase() ?? 'PENDING';
    if (rideStatus != 'PENDING') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível iniciar uma viagem já iniciada, finalizada ou cancelada.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: 12),
              Text(
                'Iniciando...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      // Extrair o rideId dos dados da viagem com validação robusta
      final rideId = RideService.extractRideId(_rideData);
      if (!RideService.isValidRideId(rideId)) {
        Navigator.of(context).pop(); // Remove o loading
        print('RideStartPage: ERRO - RideId não encontrado ou inválido para iniciar viagem');
        print('RideStartPage: Dados disponíveis: ${_rideData!.keys.toList()}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da viagem não encontrado ou inválido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('RideStartPage: RideId extraído para iniciar viagem: $rideId');

      // Converter para int se necessário
      final int rideIdInt = rideId!;
      print('RideStartPage: RideId convertido para int: $rideIdInt');
      
      // Chamar o backend para iniciar a viagem
      print('RideStartPage: Chamando backend para iniciar viagem...');
      final success = await RideService.startRide(rideIdInt);
      
      Navigator.of(context).pop(); // Remove o loading

      if (!success) {
        print('RideStartPage: Falha ao iniciar viagem no backend');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao iniciar viagem no servidor'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('RideStartPage: Viagem iniciada com sucesso no backend');
      
      // Mostrar mensagem de sucesso
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
                  'Corrida iniciada com ${_acceptedPassengers.length} passageiro(s)! 🚀',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Coordenadas do motorista (origem e destino da viagem)
      final startLocation = _rideData!['startLocation'] ?? 'Não informado';
      final endLocation = _rideData!['endLocation'] ?? 'Não informado';
      
      print('=== INICIANDO CORRIDA ===');
      print('📍 Ponto inicial do motorista: $startLocation');
      print('🎯 Ponto final do motorista: $endLocation');
      print('📊 Total de passageiros aceitos: ${_acceptedPassengers.length}');
      
      // Coordenadas dos passageiros aceitos
      if (_acceptedPassengers.isNotEmpty) {
        print('👥 COORDENADAS DOS PASSAGEIROS:');
        for (int i = 0; i < _acceptedPassengers.length; i++) {
          final passenger = _acceptedPassengers[i];
          print('Passageiro ${i + 1} - ${passenger['name'] ?? 'Sem nome'}:');
          print('  📍 Ponto inicial: ${passenger['startLocation'] ?? 'Não informado'}');
          print('  🎯 Ponto final: ${passenger['endLocation'] ?? 'Não informado'}');
          print('  📞 Telefone: ${passenger['phone'] ?? 'Não informado'}');
          print('  ---');
        }
      } else {
        print('⚠️ Nenhum passageiro aceito para esta corrida');
      }
      
      print('=== FIM DAS COORDENADAS ===');
      
      // Navegar para a tela home e fechar todas as telas anteriores
      final authService = AuthService();
      final driver = authService.currentUser;
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/driverHome', 
        (route) => false,
        arguments: {
          'rideStarted': true,
          'rideId': rideIdInt, // Incluir rideId nos argumentos
          'acceptedPassengers': _acceptedPassengers,
          'startLocation': startLocation,
          'endLocation': endLocation,
          'driver': driver != null ? {
            'userId': driver.userId,
            'name': driver.name,
            'phone': driver.phone,
            'email': driver.email,
          } : null,
        }
      );
    } catch (e) {
      Navigator.of(context).pop(); // Remove o loading
      print('❌ ERRO na navegação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar corrida: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
