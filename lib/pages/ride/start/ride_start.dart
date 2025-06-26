import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/components/available_passenger_card.dart';
import 'package:mobile_app/services/ride_service.dart';
import 'package:mobile_app/pages/home/driver_home_page.dart';
import 'package:mobile_app/main.dart';

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
  bool _isRefreshing = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  DateTime? _lastUpdate;
  String _rideStatus = 'PENDING'; // PENDING, STARTED, COMPLETED, CANCELLED
  bool _isUpdatingRideStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final rideId = args['rideId'];
        if (rideId == null) {
          setState(() {
            _errorMessage = 'ID da viagem não encontrado ou inválido';
            _isLoadingRequests = false;
          });
          return;
        }

        if (kDebugMode) {
          debugPrint('📋 === DADOS DA CORRIDA ===');
          debugPrint('📋 Todos os dados: $args');
          debugPrint('📋 departureTime: ${args['departureTime']}');
          debugPrint('📋 departureTime type: ${args['departureTime'].runtimeType}');
          debugPrint('📋 status: ${args['status']}');
          debugPrint('📋 === FIM DADOS ===');
        }

        setState(() {
          _rideData = args;
          _rideStatus = args['status']?.toString().toUpperCase() ?? 'PENDING';
          _acceptedPassengers = List<Map<String, dynamic>>.from(
            args['acceptedPassengers'] ?? [],
          );
        });

        _loadRideRequests();
        _startRefreshTimer();
      } else {
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadRideRequests(showLoading: false, isAutoRefresh: true);
      }
    });
  }

  Future<void> _loadRideRequests({
    bool showLoading = true, 
    bool isAutoRefresh = false,
    bool forceRefresh = false
  }) async {
    if (_rideData == null) {
      if (kDebugMode) {
        debugPrint('❌ _rideData é null');
      }
      setState(() {
        _isLoadingRequests = false;
        _errorMessage = 'Dados da viagem não encontrados. Tente voltar e selecionar a viagem novamente.';
      });
      return;
    }

    final driverId = _rideData!['driverId'];
    if (driverId == null) {
      if (kDebugMode) {
        debugPrint('❌ driverId é null em _rideData');
        debugPrint('❌ _rideData keys: ${_rideData!.keys.toList()}');
      }
      setState(() {
        _isLoadingRequests = false;
        _errorMessage = 'ID do motorista não encontrado nos dados da viagem.';
      });
      return;
    }

    if (kDebugMode) {
      debugPrint('🔍 === CARREGANDO SOLICITAÇÕES ===');
      debugPrint('🔍 DriverId: $driverId');
      debugPrint('🔍 RideId: ${_rideData!['id']}');
      debugPrint('🔍 ShowLoading: $showLoading');
      debugPrint('🔍 IsAutoRefresh: $isAutoRefresh');
      debugPrint('🔍 ForceRefresh: $forceRefresh');
    }

    try {
      if (showLoading) {
        setState(() {
          _isLoadingRequests = true;
          _errorMessage = null;
        });
      } else if (isAutoRefresh) {
        setState(() {
          _isRefreshing = true;
        });
      }

      if (forceRefresh) {
        if (kDebugMode) {
          debugPrint('🔄 Forçando atualização dos dados...');
        }
      }

      final requests = await RideService.getRideRequestsByDriver(driverId);
      
      if (kDebugMode) {
        debugPrint('✅ Solicitações recebidas: ${requests.length}');
        for (int i = 0; i < requests.length; i++) {
          final req = requests[i];
          debugPrint('  [$i] ID: ${req['id']}, Status: ${req['status']}, Passenger: ${req['passenger']?['name']}');
        }
      }
      
      if (mounted) {
        final pendingRequests = requests.where((request) {
          final status = request['status']?.toString().toUpperCase();
          return status == 'PENDING';
        }).toList();

        final approvedRequests = requests.where((request) {
          final status = request['status']?.toString().toUpperCase();
          return status == 'APPROVED';
        }).toList();

        if (kDebugMode) {
          debugPrint('📊 Pendentes: ${pendingRequests.length}, Aprovadas: ${approvedRequests.length}');
        }

        final hasChanges = _hasDataChanged(pendingRequests, approvedRequests);
        
        if (hasChanges || !isAutoRefresh) {
          setState(() {
            _rideRequests = pendingRequests;
            _acceptedPassengers = approvedRequests.map((request) {
              final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
              return {
                'id': request['id'],
                'userId': passenger['userId'],
                'name': passenger['name'] ?? 'Passageiro',
                'phone': passenger['phone'] ?? 'Não informado',
                'startLocation': request['startLocation'] ?? 'Não informado',
                'endLocation': request['endLocation'] ?? 'Não informado',
                'status': 'APPROVED',
              };
            }).toList();
            _isLoadingRequests = false;
            _isRefreshing = false;
            _lastUpdate = DateTime.now();
            _errorMessage = null; // Limpar erro em caso de sucesso
          });

          if (kDebugMode && hasChanges) {
            debugPrint('✅ Dados atualizados - Pendentes: ${pendingRequests.length}, Aprovados: ${approvedRequests.length}');
          }
        } else {
          setState(() {
            _isLoadingRequests = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ === ERRO AO CARREGAR SOLICITAÇÕES ===');
        debugPrint('❌ Erro: $e');
        debugPrint('❌ Tipo do erro: ${e.runtimeType}');
        debugPrint('❌ StackTrace será mostrado no próximo log');
      }
      
      if (mounted) {
        String errorMessage = 'Erro ao carregar solicitações';
        
        // Personalizar mensagem baseada no tipo de erro
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('não encontrada') || errorStr.contains('not found')) {
          errorMessage = 'Corrida não encontrada no servidor. Verifique se a corrida ainda existe.';
        } else if (errorStr.contains('não autenticado') || errorStr.contains('unauthorized')) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (errorStr.contains('connection') || errorStr.contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
        } else if (errorStr.contains('timeout')) {
          errorMessage = 'Tempo esgotado. Tente novamente em alguns segundos.';
        } else {
          errorMessage = 'Erro inesperado: ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        setState(() {
          _isLoadingRequests = false;
          _isRefreshing = false;
          _errorMessage = errorMessage;
        });
      }
      
      if (kDebugMode) {
        debugPrint('❌ === FIM ERRO ===');
      }
    }
  }

  bool _hasDataChanged(List<Map<String, dynamic>> newPending, List<Map<String, dynamic>> newApproved) {
    if (_rideRequests.length != newPending.length || _acceptedPassengers.length != newApproved.length) {
      return true;
    }

    final currentPendingIds = _rideRequests.map((r) => r['id']).toSet();
    final newPendingIds = newPending.map((r) => r['id']).toSet();
    if (!currentPendingIds.containsAll(newPendingIds) || !newPendingIds.containsAll(currentPendingIds)) {
      return true;
    }

    final currentApprovedIds = _acceptedPassengers.map((r) => r['id']).toSet();
    final newApprovedIds = newApproved.map((r) => r['id']).toSet();
    if (!currentApprovedIds.containsAll(newApprovedIds) || !newApprovedIds.containsAll(currentApprovedIds)) {
      return true;
    }

    return false;
  }

  Future<void> _onRefresh() async {
    await _loadRideRequests(showLoading: false, forceRefresh: true);
  }

  bool _canStartRide() {
    if (_rideData == null) return false;
    
    if (kDebugMode) {
      debugPrint('🕒 === VERIFICAÇÃO DE HORÁRIO ===');
      debugPrint('🕒 Partida liberada a qualquer momento!');
      debugPrint('🕒 === FIM VERIFICAÇÃO ===');
    }
    
    // Permitir iniciar a qualquer momento
    return true;
  }

  String _getTimeUntilDeparture() {
    if (_rideData == null) return '';
    
    final departureTimeStr = _rideData!['departureTime'];
    if (departureTimeStr == null) return '';
    
    try {
      final timeStr = departureTimeStr.toString();
      DateTime? departureTime;
      final now = DateTime.now();
      
      // Formato HH:mm
      if (timeStr.contains(':')) {
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          final departureHour = int.parse(timeParts[0]);
          final departureMinute = int.parse(timeParts[1]);
          
          departureTime = DateTime(
            now.year,
            now.month,
            now.day,
            departureHour,
            departureMinute,
          );
        }
      }
      // Formato ISO 8601 ou similar
      else if (timeStr.contains('T') || timeStr.contains('-')) {
        departureTime = DateTime.tryParse(timeStr);
      }
      
      if (departureTime == null) return '';
      
      final difference = departureTime.difference(now);
      
      if (difference.isNegative) return 'Horário já passou';
      
      if (difference.inHours > 0) {
        return 'em ${difference.inHours}h ${difference.inMinutes.remainder(60)}min';
      } else if (difference.inMinutes > 0) {
        return 'em ${difference.inMinutes}min';
      } else {
        return 'agora';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _startRide() async {
    if (_rideData == null) return;

    // Verificar se há passageiros aceitos
    if (_acceptedPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar pelo menos um passageiro para iniciar a corrida.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    
    // Confirmar ação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Corrida'),
        content: Text(
          'Tem certeza que deseja iniciar a corrida?\n\n'
          'Passageiros aceitos: ${_acceptedPassengers.length}\n'
          'Esta ação será enviada para o servidor e o status será alterado para "STARTED".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUpdatingRideStatus = true;
    });

    try {
      final rideId = _rideData!['id'];
      final success = await RideService.startRide(rideId);
      
      if (success && mounted) {
        setState(() {
          _rideStatus = 'STARTED';
          _isUpdatingRideStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Corrida iniciada com sucesso! Status atualizado no servidor.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        setState(() {
          _isUpdatingRideStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao iniciar corrida'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingRideStatus = false;
        });
        
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        Color backgroundColor = Colors.red;
        IconData icon = Icons.error;
        
        // Personalizar mensagem baseada no tipo de erro
        if (errorMessage.contains('não autenticado')) {
          backgroundColor = Colors.red;
          icon = Icons.lock;
        } else if (errorMessage.contains('inválido')) {
          backgroundColor = Colors.red;
          icon = Icons.warning;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(errorMessage),
                ),
              ],
            ),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancelRide() async {
    if (_rideData == null) {
      if (kDebugMode) {
        debugPrint('❌ _rideData é null - não é possível cancelar');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados da corrida não encontrados'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmar ação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Corrida'),
        content: const Text(
          'Deseja realmente cancelar esta corrida?\n\n'
          'Esta ação irá cancelar a corrida e notificar todos os passageiros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUpdatingRideStatus = true;
    });

    try {
      final rideId = _rideData!['id'];
      
      if (kDebugMode) {
        debugPrint('🚫 === INICIANDO CANCELAMENTO ===');
        debugPrint('🚫 RideId: $rideId');
        debugPrint('🚫 RideData: $_rideData');
      }
      
      if (rideId == null) {
        throw Exception('ID da corrida não encontrado nos dados da viagem');
      }
      
      final success = await RideService.cancelRide(rideId);
      
      if (kDebugMode) {
        debugPrint('🚫 Resultado do cancelamento: $success');
      }
      
      if (success && mounted) {
        setState(() {
          _rideStatus = 'CANCELLED';
          _isUpdatingRideStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Corrida cancelada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        // Voltar para a tela inicial do motorista após alguns segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _safeNavigateToDriverHome();
          }
        });
      } else if (mounted) {
        setState(() {
          _isUpdatingRideStatus = false;
        });
        
        if (kDebugMode) {
          debugPrint('❌ Cancelamento retornou false');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao cancelar corrida - serviço retornou falso'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ === ERRO NO CANCELAMENTO ===');
        debugPrint('❌ Erro: $e');
        debugPrint('❌ Tipo do erro: ${e.runtimeType}');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
      }
      
      if (mounted) {
        setState(() {
          _isUpdatingRideStatus = false;
        });
        
        String errorMessage = 'Erro desconhecido ao cancelar corrida';
        
        if (e.toString().contains('não autenticado')) {
          errorMessage = 'Sessão expirada. Faça login novamente';
        } else if (e.toString().contains('não encontrado')) {
          errorMessage = 'Corrida não encontrada no servidor';
        } else if (e.toString().contains('connection') || e.toString().contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Tempo esgotado. Tente novamente';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erro ao cancelar corrida:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(errorMessage),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _cancelRide();
              },
            ),
          ),
        );
      }
    }
  }

  void _viewOnMap() {
    if (_rideData != null) {
      Navigator.pushNamed(
        context,
        '/started_ride',
        arguments: _rideData,
      );
    }
  }

  Future<void> _completeRide() async {
    if (_rideData == null) return;

    // Confirmar ação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Viagem'),
        content: Text(
          'Tem certeza que deseja finalizar esta viagem?\n\n'
          'Passageiros na viagem: ${_acceptedPassengers.length}\n'
          'Esta ação marcará a viagem como concluída.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUpdatingRideStatus = true;
    });

    try {
      final rideId = _rideData!['id'];
      final success = await RideService.updateRideStatus(rideId, 'COMPLETED');
      
      if (success && mounted) {
        setState(() {
          _rideStatus = 'COMPLETED';
          _isUpdatingRideStatus = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Viagem finalizada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Voltar para a tela inicial do motorista após alguns segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _safeNavigateToDriverHome();
          }
        });
      } else if (mounted) {
        setState(() {
          _isUpdatingRideStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao finalizar viagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingRideStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar viagem: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      final requestId = request['id'];
      if (requestId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da solicitação não encontrado'),
          ),
        );
        return;
      }

      final status = request['status']?.toString().toUpperCase();
      if (status != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta solicitação já foi processada.')),
        );
        return;
      }

      final totalSeats = _rideData?['totalSeats'] ?? 0;
      final acceptedCount = _acceptedPassengers.length;
      final availableSeats = totalSeats - acceptedCount;

      if (availableSeats <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há vagas disponíveis nesta viagem.'),
          ),
        );
        return;
      }

      final success = await RideService.updateRideRequestStatus(
        requestId,
        'APPROVED',
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao aceitar solicitação')),
        );
        return;
      }

      setState(() {
        _acceptedPassengers.add({
          'id': request['id'],
          'userId': request['passenger']['userId'],
          'name': request['passenger']['name'] ?? 'Passageiro',
          'phone': request['passenger']['phone'] ?? 'Não informado',
          'startLocation': request['startLocation'] ?? 'Não informado',
          'endLocation': request['endLocation'] ?? 'Não informado',
          'status': 'APPROVED',
        });
        _rideRequests.removeWhere((req) => req['id'] == requestId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitação aceita')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aceitar solicitação: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    try {
      final requestId = request['id'];
      if (requestId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID da solicitação não encontrado'),
          ),
        );
        return;
      }

      final status = request['status']?.toString().toUpperCase();
      if (status != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta solicitação já foi processada.')),
        );
        return;
      }

      final success = await RideService.updateRideRequestStatus(
        requestId,
        'REJECTED',
      );
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao rejeitar solicitação')),
        );
        return;
      }

      setState(() {
        _rideRequests.removeWhere((req) => req['id'] == requestId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação rejeitada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao rejeitar solicitação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Viagem'), 
        centerTitle: true,
        actions: [
          // Botão Cancelar na AppBar - visível apenas quando aplicável
          if (_rideStatus == 'PENDING' || _rideStatus == 'STARTED' || _rideStatus == 'IN_PROGRESS') ...[
            IconButton(
              icon: Icon(
                Icons.cancel_outlined,
                color: Colors.red[600],
              ),
              onPressed: _isUpdatingRideStatus ? null : _cancelRide,
              tooltip: 'Cancelar Corrida',
            ),
          ],
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadRideRequests(showLoading: false, forceRefresh: true),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Column(
            children: [
              if (_rideData != null) ...[
                _buildRideInfoCard(),
                const SizedBox(height: 16),
              ],
              // Botões de ação da corrida
              if (_rideData != null) ...[
                _buildRideActionButtons(),
                const SizedBox(height: 16),
              ],
              if (_lastUpdate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Última atualização: ${_formatLastUpdate()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_isRefreshing)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(child: _buildRequestsList()),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastUpdate() {
    if (_lastUpdate == null) return 'Nunca';
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdate!);
    
    if (difference.inSeconds < 60) {
      return 'há ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes}min';
    } else {
      return 'há ${difference.inHours}h';
    }
  }

  Widget _buildRideInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Detalhes da Viagem',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'De', _rideData?['startLocation'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, 'Para', _rideData?['endLocation'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.schedule, 'Partida', _rideData?['departureTime'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.people, 'Passageiros aceitos', '${_acceptedPassengers.length}'),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (_rideStatus) {
      case 'PENDING':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[700]!;
        icon = Icons.schedule;
        text = 'Aguardando';
        break;
      case 'STARTED':
      case 'IN_PROGRESS':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        icon = Icons.play_arrow;
        text = 'Em Andamento';
        break;
      case 'COMPLETED':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[700]!;
        icon = Icons.check_circle;
        text = 'Concluída';
        break;
      case 'CANCELLED':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        text = 'Cancelada';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
        text = 'Desconhecido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            '$label: ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildRideActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Linha principal de ações
          Row(
            children: [
              // Botão Iniciar Corrida (quando PENDING)
              if (_rideStatus == 'PENDING') ...[
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingRideStatus ? null : _startRide,
                    icon: _isUpdatingRideStatus
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isUpdatingRideStatus 
                        ? 'Iniciando...' 
                        : 'Iniciar Corrida'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Botões quando viagem está em andamento
              if (_rideStatus == 'STARTED' || _rideStatus == 'IN_PROGRESS') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingRideStatus ? null : _completeRide,
                    icon: _isUpdatingRideStatus
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.flag),
                    label: Text(_isUpdatingRideStatus ? 'Finalizando...' : 'Finalizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingRideStatus ? null : _viewOnMap,
                    icon: const Icon(Icons.map),
                    label: const Text('Mapa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Mensagem quando corrida foi cancelada ou concluída
              if (_rideStatus == 'CANCELLED' || _rideStatus == 'COMPLETED') ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: (_rideStatus == 'CANCELLED' ? Colors.red : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_rideStatus == 'CANCELLED' ? Colors.red : Colors.blue).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _rideStatus == 'CANCELLED' ? Icons.cancel : Icons.check_circle,
                          color: _rideStatus == 'CANCELLED' ? Colors.red[700] : Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _rideStatus == 'CANCELLED' ? 'Corrida Cancelada' : 'Corrida Concluída',
                          style: TextStyle(
                            color: _rideStatus == 'CANCELLED' ? Colors.red[700] : Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          // Informação sobre partida livre
          if (_rideStatus == 'PENDING') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Você pode iniciar a corrida a qualquer momento',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Botão Cancelar - sempre visível na parte inferior quando aplicável
          if (_rideStatus == 'PENDING' || _rideStatus == 'STARTED' || _rideStatus == 'IN_PROGRESS') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUpdatingRideStatus ? null : _cancelRide,
                icon: _isUpdatingRideStatus
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, size: 20),
                label: Text(
                  _isUpdatingRideStatus ? 'Cancelando Corrida...' : 'Cancelar Corrida',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[600]!, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadRideRequests(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_rideRequests.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma solicitação de carona ainda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puxe para baixo para atualizar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _rideRequests.length + (_acceptedPassengers.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // Mostrar passageiros aceitos primeiro, se houver
        if (_acceptedPassengers.isNotEmpty && index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.route, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Paradas da Viagem (${_acceptedPassengers.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_acceptedPassengers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ATIVO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ..._acceptedPassengers.asMap().entries.map((entry) {
                final index = entry.key;
                final passenger = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Colors.green[50]!,
                          Colors.green[100]!.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              passenger['name'] ?? 'Passageiro',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.green[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  passenger['startLocation'] ?? 'Local não informado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (passenger['phone'] != null && passenger['phone'] != 'Não informado') ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.green[600]),
                                const SizedBox(width: 4),
                                Text(
                                  passenger['phone'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              'PARADA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              if (_rideRequests.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Solicitações Pendentes (${_rideRequests.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        // Ajustar índice se houver passageiros aceitos
        final requestIndex = _acceptedPassengers.isNotEmpty ? index - 1 : index;
        final request = _rideRequests[requestIndex];
        final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
        final name = passenger['name'] ?? 'Passageiro';
        final phoneNumber = passenger['phone'] ?? 'Não informado';

        return AvailablePassengerCard(
          name: name,
          location: request['startLocation'] ?? 'Local não informado',
          phoneNumber: phoneNumber,
          imageUrl: passenger['profileImageUrl'] ?? 'assets/images/profile1.png',
          rating: (request['rating'] as num? ?? 4.0).toDouble(),
          onAccept: () => _acceptRequest(request),
          onReject: () => _rejectRequest(request),
        );
      },
    );
  }

  /// Função utilitária para navegação segura
  void _safeNavigateToDriverHome() {
    if (!mounted) return;
    
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/driverHome',
        (route) => false,
        arguments: {'refreshRides': true},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro na navegação: $e');
      }
      // Fallback: navegação simples
      try {
        Navigator.of(context).pushReplacementNamed('/driverHome');
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('❌ Erro na navegação fallback: $e2');
        }
      }
    }
  }
}
