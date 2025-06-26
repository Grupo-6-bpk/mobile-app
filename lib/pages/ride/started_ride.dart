import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_app/services/ride_service.dart';
import 'package:mobile_app/services/maps_service.dart';
import 'package:mobile_app/components/custom_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class StartedRidePage extends StatefulWidget {
  const StartedRidePage({super.key});

  @override
  State<StartedRidePage> createState() => _StartedRidePageState();
}

class _StartedRidePageState extends State<StartedRidePage> {
  Map<String, dynamic>? _rideData;
  List<Map<String, dynamic>> _rideRequests = [];
  List<LatLng> _stopPoints = [];
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  bool _isLoadingRequests = true;
  bool _isLoadingLocation = true;
  String? _errorMessage;
  final MapsService _mapsService = MapsService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _rideData = args;
        });
        _loadRideRequests();
        _getCurrentLocation();
        _setDestination();
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _loadRideRequests(showLoading: false);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao obter localização: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _setDestination() {
    // Coordenadas do Biopark Educação (destino padrão)
    setState(() {
      _destinationLocation = const LatLng(-25.4284, -49.2733);
    });
  }

  Future<void> _loadRideRequests({bool showLoading = true}) async {
    if (_rideData == null) return;

    final driverId = _rideData!['driverId'];
    if (driverId == null) return;

    try {
      if (showLoading) {
        setState(() {
          _isLoadingRequests = true;
          _errorMessage = null;
        });
      }

      final requests = await RideService.getRideRequestsByDriver(driverId);
      
      if (mounted) {
        // Filtrar apenas solicitações aprovadas
        final approvedRequests = requests.where((request) {
          final status = request['status']?.toString().toUpperCase();
          return status == 'APPROVED';
        }).toList();

        setState(() {
          _rideRequests = approvedRequests;
          _isLoadingRequests = false;
        });

        // Processar pontos de parada
        await _processStopPoints();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao carregar solicitações: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados: $e';
          _isLoadingRequests = false;
        });
      }
    }
  }

  Future<void> _processStopPoints() async {
    List<LatLng> points = [];

    for (final request in _rideRequests) {
      final startLocation = request['startLocation']?.toString();
      if (startLocation != null && startLocation.contains(',')) {
        final coords = startLocation.split(',');
        if (coords.length == 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());
          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _stopPoints = points;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrida em Andamento'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadRideRequests(),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomInfo(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingRequests || _isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando dados da corrida...'),
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
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRideRequests(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_currentLocation == null || _destinationLocation == null) {
      return const Center(
        child: Text('Localização não disponível'),
      );
    }

    return Column(
      children: [
        // Informações da corrida
        _buildRideInfo(),
        
        // Mapa com pontos de parada
        Expanded(
          child: _buildMap(),
        ),
      ],
    );
  }

  Widget _buildRideInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.green.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle, color: Colors.green[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Corrida Iniciada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.people,
                  'Passageiros',
                  '${_rideRequests.length}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.location_on,
                  'Paradas',
                  '${_stopPoints.length}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                  'Partida',
                  _rideData?['departureTime'] ?? 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: CustomMap(
        height: double.infinity,
        initialPosition: _currentLocation!,
        destinationPosition: _destinationLocation!,
        waypoints: _stopPoints,
      ),
    );
  }

  Widget _buildBottomInfo() {
    if (_rideRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border(
            top: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Nenhum passageiro confirmado ainda',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passageiros Confirmados (${_rideRequests.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _rideRequests.length,
              itemBuilder: (context, index) {
                final request = _rideRequests[index];
                return _buildPassengerCard(request, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(Map<String, dynamic> request, int stopNumber) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stopNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Parada $stopNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request['name'] ?? 'Passageiro',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 