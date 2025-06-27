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
  String _rideStatus = 'PENDING'; // PENDING, STARTED, COMPLETED, CANCELED
  bool _isUpdatingRideStatus = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        // Usar o método utilitário para validar se temos um rideId válido
        final extractedRideId = RideService.safeExtractRideId(args);
        if (extractedRideId == null) {
          setState(() {
            _errorMessage = 'ID da viagem não encontrado ou inválido nos dados: $args';
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
    
    // Durante auto-refresh, sincronizar status da corrida
    if (isAutoRefresh) {
      await _syncRideStatusFromBackend();
      
      // Se a corrida foi cancelada/finalizada, não precisamos carregar mais requests
      if (['CANCELED', 'CANCELLED', 'COMPLETED'].contains(_rideStatus.toUpperCase())) {
        if (kDebugMode) {
          debugPrint('🛑 Corrida em estado final ($_rideStatus), parando carregamento de requests');
        }
        return;
      }
    }
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
        
        // Sincronizar passageiros aprovados que podem não estar na lista local
        for (final approvedRequest in approvedRequests) {
          final requestId = approvedRequest['id'];
          final alreadyInAccepted = _acceptedPassengers.any((p) => p['id'] == requestId);
          
          if (!alreadyInAccepted) {
            if (kDebugMode) {
              debugPrint('🔄 Adicionando passageiro aprovado à lista local: $requestId');
            }
            
            final passenger = approvedRequest['passenger'] as Map<String, dynamic>? ?? {};
            _acceptedPassengers.add({
              'id': approvedRequest['id'],
              'userId': passenger['userId'] ?? approvedRequest['passengerId'],
              'name': passenger['name'] ?? 'Passageiro $requestId',
              'phone': passenger['phone'] ?? 'Não informado',
              'startLocation': approvedRequest['startLocation'] ?? 'Não informado',
              'endLocation': approvedRequest['endLocation'] ?? 'Não informado',
              'status': 'APPROVED',
            });
          }
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
            debugPrint('🔄 Lista de passageiros aceitos atual: ${_acceptedPassengers.map((p) => 'ID:${p['id']} Nome:${p['name']}').join(', ')}');
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
    if (kDebugMode) {
      debugPrint('🔍 === VERIFICANDO MUDANÇAS ===');
      debugPrint('🔍 Pendentes: local ${_rideRequests.length} vs novo ${newPending.length}');
      debugPrint('🔍 Aprovados: local ${_acceptedPassengers.length} vs novo ${newApproved.length}');
    }
    
    if (_rideRequests.length != newPending.length || _acceptedPassengers.length != newApproved.length) {
      if (kDebugMode) {
        debugPrint('✅ Mudança detectada: diferença de tamanho');
      }
      return true;
    }

    final currentPendingIds = _rideRequests.map((r) => r['id']).toSet();
    final newPendingIds = newPending.map((r) => r['id']).toSet();
    
    if (kDebugMode) {
      debugPrint('🔍 IDs Pendentes atuais: $currentPendingIds');
      debugPrint('🔍 IDs Pendentes novos: $newPendingIds');
    }
    
    if (!currentPendingIds.containsAll(newPendingIds) || !newPendingIds.containsAll(currentPendingIds)) {
      if (kDebugMode) {
        debugPrint('✅ Mudança detectada nas solicitações pendentes');
      }
      return true;
    }

    final currentApprovedIds = _acceptedPassengers.map((r) => r['id']).toSet();
    final newApprovedIds = newApproved.map((r) => r['id']).toSet();
    
    if (kDebugMode) {
      debugPrint('🔍 IDs Aprovados atuais: $currentApprovedIds');
      debugPrint('🔍 IDs Aprovados novos: $newApprovedIds');
    }
    
    if (!currentApprovedIds.containsAll(newApprovedIds) || !newApprovedIds.containsAll(currentApprovedIds)) {
      if (kDebugMode) {
        debugPrint('✅ Mudança detectada nos passageiros aprovados');
      }
      return true;
    }

    if (kDebugMode) {
      debugPrint('📊 Nenhuma mudança detectada');
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
      final success = await RideService.startRideFlexible(_rideData);
      
      if (success && mounted) {
        setState(() {
          _rideStatus = 'STARTED';
          _isUpdatingRideStatus = false;
        });

        _clearRelatedCaches(); // Limpar cache após mudança de status

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

    // Evitar cancelamentos duplicados
    if (_isCancelling) {
      if (kDebugMode) {
        debugPrint('⚠️ Cancelamento já em andamento, ignorando nova tentativa');
      }
      return;
    }

    // Sincronizar status com backend antes de tentar cancelar
    final wasSynced = await _syncRideStatusFromBackend();
    if (wasSynced) {
      // Se o status foi sincronizado, verificar se a corrida já está cancelada
      if (['CANCELED', 'CANCELLED', 'COMPLETED'].contains(_rideStatus.toUpperCase())) {
        if (kDebugMode) {
          debugPrint('✅ Corrida já está em estado final: $_rideStatus');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corrida já está ${_rideStatus.toLowerCase()}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
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
      _isCancelling = true;
    });

    try {
      if (kDebugMode) {
        debugPrint('🚫 === INICIANDO CANCELAMENTO ===');
        debugPrint('🚫 RideData: $_rideData');
        debugPrint('🚫 Status atual: $_rideStatus');
      }
      
      final success = await RideService.cancelRideFlexible(_rideData);
      
      if (kDebugMode) {
        debugPrint('🚫 Resultado do cancelamento: $success');
      }
      
      if (success && mounted) {
        setState(() {
          _rideStatus = 'CANCELED';
          _isUpdatingRideStatus = false;
          _isCancelling = false;
        });

        _clearRelatedCaches(); // Limpar cache após cancelamento

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

        // Voltar para a tela inicial do motorista imediatamente após cancelamento
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _safeNavigateToDriverHome(clearActiveRide: true);
          }
        });
      } else if (mounted) {
        setState(() {
          _isUpdatingRideStatus = false;
          _isCancelling = false;
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
          _isCancelling = false;
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
    
    // // Verificar se a corrida foi iniciada
    // if (!['STARTED', 'IN_PROGRESS'].contains(_rideStatus.toUpperCase())) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('A corrida deve estar em andamento para ser finalizada. Status atual: $_rideStatus'),
    //       backgroundColor: Colors.orange,
    //       duration: const Duration(seconds: 4),
    //     ),
    //   );
    //   return;
    // }
    
    // Verificar se há passageiros aceitos
    if (_acceptedPassengers.isEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finalizar sem Passageiros'),
          content: const Text(
            'Esta viagem não tem passageiros aceitos.\n\n'
            'Deseja realmente finalizar a viagem vazia?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Finalizar Mesmo Assim'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    }

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
      if (kDebugMode) {
        debugPrint('🏁 === INICIANDO FINALIZAÇÃO ===');
        debugPrint('🏁 RideData: $_rideData');
        debugPrint('🏁 Status atual: $_rideStatus');
      }
      
      final success = await RideService.completeRideFlexible(_rideData);
      
      if (success && mounted) {
        setState(() {
          _rideStatus = 'COMPLETED'; // Normalizar para uppercase no frontend
          _isUpdatingRideStatus = false;
        });

        _clearRelatedCaches(); // Limpar cache após finalização

        if (kDebugMode) {
          debugPrint('✅ === FINALIZAÇÃO CONCLUÍDA ===');
          debugPrint('✅ Status atualizado para: COMPLETED');
          debugPrint('✅ Retornando para tela principal em 3 segundos...');
        }

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
      if (kDebugMode) {
        debugPrint('❌ === ERRO AO FINALIZAR ===');
        debugPrint('❌ Erro: $e');
        debugPrint('❌ Tipo do erro: ${e.runtimeType}');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
      }
      
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
      
      if (kDebugMode) {
        debugPrint('👥 === ACEITANDO SOLICITAÇÃO ===');
        debugPrint('👥 Request ID: $requestId');
        debugPrint('👥 Status atual: $status');
        debugPrint('👥 Request completo: $request');
      }
      
      // Verificar se já está aprovada
      if (status == 'APPROVED') {
        if (kDebugMode) {
          debugPrint('✅ Solicitação já está aprovada, apenas atualizando UI local');
        }
        
        // Adicionar à lista de aceitos se não estiver lá
        final alreadyAccepted = _acceptedPassengers.any((p) => p['id'] == requestId);
        if (!alreadyAccepted) {
          final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
          setState(() {
            _acceptedPassengers.add({
              'id': request['id'],
              'userId': passenger['userId'] ?? request['passengerId'],
              'name': passenger['name'] ?? 'Passageiro ${requestId}',
              'phone': passenger['phone'] ?? 'Não informado',
              'startLocation': request['startLocation'] ?? 'Não informado',
              'endLocation': request['endLocation'] ?? 'Não informado',
              'status': 'APPROVED',
            });
            _rideRequests.removeWhere((req) => req['id'] == requestId);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitação já aprovada, adicionada à lista')),
          );
        }
        return;
      }
      
      if (status != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esta solicitação já foi processada (status: $status).')),
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

      if (kDebugMode) {
        debugPrint('👥 Tentando aprovar solicitação...');
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

      if (kDebugMode) {
        debugPrint('✅ Solicitação aprovada com sucesso');
      }

      // Atualizar UI local
      final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
      setState(() {
        _acceptedPassengers.add({
          'id': request['id'],
          'userId': passenger['userId'] ?? request['passengerId'],
          'name': passenger['name'] ?? 'Passageiro ${requestId}',
          'phone': passenger['phone'] ?? 'Não informado',
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
      if (kDebugMode) {
        debugPrint('❌ === ERRO AO ACEITAR SOLICITAÇÃO ===');
        debugPrint('❌ Erro: $e');
      }
      
      if (mounted) {
        String errorMessage = 'Erro ao aceitar solicitação: $e';
        
        // Tratar erro específico de status já definido
        if (e.toString().contains('já está definido como APPROVED')) {
          errorMessage = 'Solicitação já foi aprovada anteriormente';
          // Força um refresh para sincronizar o estado
          _loadRideRequests(showLoading: false, forceRefresh: true);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
      
      if (kDebugMode) {
        debugPrint('❌ === REJEITANDO SOLICITAÇÃO ===');
        debugPrint('❌ Request ID: $requestId');
        debugPrint('❌ Status atual: $status');
      }
      
      // Verificar se já está rejeitada
      if (status == 'REJECTED') {
        if (kDebugMode) {
          debugPrint('✅ Solicitação já está rejeitada, apenas removendo da UI');
        }
        setState(() {
          _rideRequests.removeWhere((req) => req['id'] == requestId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação já foi rejeitada anteriormente')),
        );
        return;
      }
      
      if (status != 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esta solicitação já foi processada (status: $status).')),
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
      if (kDebugMode) {
        debugPrint('❌ === ERRO AO REJEITAR SOLICITAÇÃO ===');
        debugPrint('❌ Erro: $e');
      }
      
      if (mounted) {
        String errorMessage = 'Erro ao rejeitar solicitação: $e';
        
        // Tratar erro específico de status já definido
        if (e.toString().contains('já está definido como REJECTED')) {
          errorMessage = 'Solicitação já foi rejeitada anteriormente';
          // Força um refresh para sincronizar o estado
          _loadRideRequests(showLoading: false, forceRefresh: true);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  /// Sincroniza o status da corrida com o backend para evitar inconsistências
  Future<bool> _syncRideStatusFromBackend() async {
    if (_rideData == null) return false;
    
    try {
      final rideId = RideService.safeExtractRideId(_rideData);
      if (rideId == null) return false;
      
      if (kDebugMode) {
        debugPrint('🔄 === SINCRONIZANDO STATUS ===');
        debugPrint('🔄 RideId: $rideId');
        debugPrint('🔄 Status local atual: $_rideStatus');
      }
      
      // Buscar dados atualizados da corrida do backend
      final driverId = _rideData!['driverId'];
      if (driverId == null) return false;
      
      final activeRide = await RideService.getActiveRideForDriver(driverId);
      
      if (activeRide != null) {
        final backendStatus = activeRide['status']?.toString().toUpperCase() ?? 'PENDING';
        final backendRideId = RideService.safeExtractRideId(activeRide);
        
        if (kDebugMode) {
          debugPrint('🔄 Status do backend: $backendStatus');
          debugPrint('🔄 RideId do backend: $backendRideId');
        }
        
        // Verificar se é a mesma corrida
        if (backendRideId == rideId) {
          if (backendStatus != _rideStatus) {
            if (kDebugMode) {
              debugPrint('⚠️ Status desincronizado! Local: $_rideStatus, Backend: $backendStatus');
            }
            
            setState(() {
              _rideStatus = backendStatus;
              // Atualizar também os dados locais
              if (_rideData != null) {
                _rideData!['status'] = backendStatus;
              }
            });
            
            return true; // Indica que houve sincronização
          }
        } else {
          // A corrida ativa no backend é diferente - redirecionar para a corrida correta
          if (kDebugMode) {
            debugPrint('🚨 CORRIDA DIFERENTE DETECTADA!');
            debugPrint('🚨 Local: $rideId, Backend: $backendRideId');
            debugPrint('🚨 Redirecionando para corrida ativa...');
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecionando para a corrida ativa mais recente...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            
            // Aguardar um pouco para mostrar a mensagem
            await Future.delayed(const Duration(seconds: 1));
            
            if (mounted) {
              // Redirecionar para a corrida ativa do backend
              final newRideData = {
                'driverId': activeRide['driverId'] ?? driverId,
                'rideId': backendRideId,
                'id': backendRideId,
                'startLocation': activeRide['startLocation'] ?? 'Não informado',
                'endLocation': activeRide['endLocation'] ?? 'Não informado',
                'departureTime': activeRide['departureTime'] ?? 'Não informado',
                'date': 'Hoje',
                'totalSeats': activeRide['totalSeats'] ?? 4,
                'distance': activeRide['distance']?.toString() ?? 'N/A',
                'vehicleBrand': activeRide['vehicle']?['brand'] ?? 'N/A',
                'vehicleModel': activeRide['vehicle']?['model'] ?? 'N/A',
                'acceptedPassengers': [],
                'status': backendStatus,
              };
              
              Navigator.pushReplacementNamed(
                context, 
                '/ride_start', 
                arguments: newRideData,
              );
            }
          }
          
          return false;
        }
      } else {
        // Não há corrida ativa no backend - a corrida pode ter sido cancelada/finalizada
        if (kDebugMode) {
          debugPrint('⚠️ Nenhuma corrida ativa encontrada no backend');
          debugPrint('⚠️ Corrida local $rideId pode ter sido cancelada/finalizada');
        }
        
        // Verificar se a corrida local não está em um estado final
        if (!['CANCELED', 'CANCELLED', 'COMPLETED'].contains(_rideStatus.toUpperCase())) {
          if (kDebugMode) {
            debugPrint('🔄 Marcando corrida local como cancelada');
          }
          
          setState(() {
            _rideStatus = 'CANCELED';
            if (_rideData != null) {
              _rideData!['status'] = 'CANCELED';
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Esta corrida foi finalizada. Retornando ao início...'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            
            // Voltar para home após alguns segundos
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                _safeNavigateToDriverHome(clearActiveRide: true);
              }
            });
          }
          
          return true;
        }
      }
      
      return false; // Nenhuma sincronização necessária
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao sincronizar status: $e');
      }
      return false;
    }
  }

  /// Limpa caches relacionados quando há mudança de status
  void _clearRelatedCaches() {
    if (kDebugMode) {
      debugPrint('🧹 Limpando caches relacionados à corrida');
    }
    RideService.clearRidesCache();
  }

  /// Verifica se a corrida já passou do horário de partida
  bool _hasRideDeparted() {
    if (_rideData == null) return false;
    
    final departureTimeStr = _rideData!['departureTime'];
    if (departureTimeStr == null) return false;
    
    try {
      DateTime? departureTime;
      final now = DateTime.now();
      
      // Tentar converter diferentes formatos de data/hora
      if (departureTimeStr.toString().contains('T')) {
        // Formato ISO 8601 (ex: 2025-06-26T18:30:00.000Z)
        departureTime = DateTime.tryParse(departureTimeStr.toString());
      } else if (departureTimeStr.toString().contains(':')) {
        // Formato HH:mm (ex: 18:30)
        final timeParts = departureTimeStr.toString().split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          if (hour != null && minute != null) {
            departureTime = DateTime(
              now.year, now.month, now.day,
              hour, minute,
            );
          }
        }
      }
      
      if (departureTime == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Não foi possível converter horário de partida: $departureTimeStr');
        }
        return false;
      }
      
      final hasDeparted = now.isAfter(departureTime);
      
      if (kDebugMode) {
        debugPrint('🕒 === VERIFICAÇÃO DE HORÁRIO ===');
        debugPrint('🕒 Horário atual: $now');
        debugPrint('🕒 Horário de partida: $departureTime');
        debugPrint('🕒 Já partiu: $hasDeparted');
      }
      
      return hasDeparted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao verificar horário de partida: $e');
      }
      return false;
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
          if (!['CANCELED', 'CANCELLED', 'COMPLETED', 'completed'].contains(_rideStatus.toUpperCase()) && !_isCancelling) ...[
            IconButton(
              icon: Icon(
                Icons.cancel_outlined,
                color: Colors.red[600],
              ),
              onPressed: _isUpdatingRideStatus || _isCancelling ? null : _cancelRide,
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

    switch (_rideStatus.toUpperCase()) {
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
      case 'CANCELED':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        text = 'Cancelada';
        break;
      default:
        // Para casos como "completed", "canceled" em lowercase
        if (_rideStatus.toLowerCase() == 'completed') {
          backgroundColor = Colors.blue.withOpacity(0.1);
          textColor = Colors.blue[700]!;
          icon = Icons.check_circle;
          text = 'Concluída';
        } else if (_rideStatus.toLowerCase() == 'canceled') {
          backgroundColor = Colors.red.withOpacity(0.1);
          textColor = Colors.red[700]!;
          icon = Icons.cancel;
          text = 'Cancelada';
        } else {
          backgroundColor = Colors.grey.withOpacity(0.1);
          textColor = Colors.grey[700]!;
          icon = Icons.help_outline;
          text = 'Desconhecido';
        }
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
                    onPressed: (_isUpdatingRideStatus || _isCancelling) ? null : _startRide,
                    icon: _isUpdatingRideStatus
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isUpdatingRideStatus 
                        ? 'Iniciando...' 
                        : _isCancelling 
                        ? 'Aguarde...'
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
                    onPressed: (_isUpdatingRideStatus || _isCancelling) ? null : _completeRide,
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
                    onPressed: (_isUpdatingRideStatus || _isCancelling) ? null : _viewOnMap,
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
              if (['CANCELED', 'CANCELLED', 'COMPLETED', 'completed'].contains(_rideStatus.toUpperCase()) || _rideStatus.toLowerCase() == 'completed') ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: (['CANCELED', 'CANCELLED'].contains(_rideStatus.toUpperCase()) ? Colors.red : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (['CANCELED', 'CANCELLED'].contains(_rideStatus.toUpperCase()) ? Colors.red : Colors.blue).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          ['CANCELED', 'CANCELLED'].contains(_rideStatus.toUpperCase()) ? Icons.cancel : Icons.check_circle,
                          color: ['CANCELED', 'CANCELLED'].contains(_rideStatus.toUpperCase()) ? Colors.red[700] : Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ['CANCELED', 'CANCELLED'].contains(_rideStatus.toUpperCase()) ? 'Corrida Cancelada' : 'Corrida Concluída',
                          style: TextStyle(
                            color: ['CANCELED', 'CANCELLED'].contains(_rideStatus.toUpperCase()) ? Colors.red[700] : Colors.blue[700],
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
          if (!['CANCELED', 'CANCELLED', 'COMPLETED', 'completed'].contains(_rideStatus.toLowerCase())) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_isUpdatingRideStatus || _isCancelling) ? null : _cancelRide,
                icon: (_isUpdatingRideStatus || _isCancelling)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, size: 20),
                label: Text(
                  (_isUpdatingRideStatus || _isCancelling) ? 'Cancelando Corrida...' : 'Cancelar Corrida',
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
  void _safeNavigateToDriverHome({bool clearActiveRide = false}) {
    if (!mounted) return;
    
    try {
      final arguments = {
        'refreshRides': true,
        if (clearActiveRide) 'rideCancelled': true,
      };
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/driverHome',
        (route) => false,
        arguments: arguments,
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
