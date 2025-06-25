import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_app/components/available_passenger_card.dart';
import 'package:mobile_app/services/ride_service.dart';

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
      if (args is Map<String, dynamic>) {
        final rideId = args['rideId'];
        if (rideId == null) {
          setState(() {
            _errorMessage = 'ID da viagem não encontrado ou inválido';
            _isLoadingRequests = false;
          });
          return;
        }

        setState(() {
          _rideData = args;
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadRideRequests(showLoading: false);
    });
  }

  Future<void> _loadRideRequests({bool showLoading = true}) async {
    if (_rideData == null) {
      setState(() {
        _isLoadingRequests = false;
        _errorMessage = 'Dados da viagem não encontrados';
      });
      return;
    }

    final driverId = _rideData!['driverId'];
    if (driverId == null) {
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

      final requests = await RideService.getRideRequestsByDriver(driverId);
      if (mounted) {
        final pendingRequests =
            requests.where((request) {
              final status = request['status']?.toString().toUpperCase();
              return status == 'PENDING';
            }).toList();

        final approvedRequests =
            requests.where((request) {
              final status = request['status']?.toString().toUpperCase();
              return status == 'APPROVED';
            }).toList();

        setState(() {
          _rideRequests = pendingRequests;
          _acceptedPassengers =
              approvedRequests.map((request) {
                final passenger =
                    request['passenger'] as Map<String, dynamic>? ?? {};
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRequests = false;
          _errorMessage = 'Erro ao carregar solicitações: $e';
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Viagem'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            if (_rideData != null) ...[
              _buildRideInfoCard(),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildRequestsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalhes da Viagem'),
          Text('De: ${_rideData?['startLocation']}'),
          Text('Para: ${_rideData?['endLocation']}'),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_rideRequests.isEmpty) {
      return const Center(child: Text('Nenhuma solicitação de carona ainda'));
    }

    return ListView.builder(
      itemCount: _rideRequests.length,
      itemBuilder: (context, index) {
        final request = _rideRequests[index];
        final passenger = request['passenger'] as Map<String, dynamic>? ?? {};
        final name = passenger['name'] ?? 'Passageiro';
        final phoneNumber = passenger['phone'] ?? 'Não informado';

        return AvailablePassengerCard(
          name: name,
          location: request['startLocation'] ?? 'Local não informado',
          phoneNumber: phoneNumber,
          imageUrl:
              passenger['profileImageUrl'] ?? 'assets/images/profile1.png',
          rating: (request['rating'] as num? ?? 4.0).toDouble(),
          onAccept: () => _acceptRequest(request),
          onReject: () => debugPrint('Rejected request'),
        );
      },
    );
  }
}
