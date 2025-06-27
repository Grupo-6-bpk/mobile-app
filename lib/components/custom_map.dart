import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMap extends StatefulWidget {
  final double height;
  final LatLng initialPosition;
  final LatLng destinationPosition;
  final List<LatLng>? waypoints;

  const CustomMap({
    super.key,
    required this.initialPosition,
    required this.destinationPosition,
    this.waypoints,
    this.height = 200,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  final Map<PolylineId, Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _getPolyLinePoints().then((coordinates) {
      _polylineCoordinates = coordinates;
      _generatePolylineFromPoints(_polylineCoordinates);
      setState(() {
        _isLoadingRoute = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              _fitMapToRoute();
            },
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 10,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('start'),
                position: widget.initialPosition,
                infoWindow: const InfoWindow(title: 'Início'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: const MarkerId('end'),
                position: widget.destinationPosition,
                infoWindow: const InfoWindow(title: 'Destino'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
              ...widget.waypoints?.asMap().entries.map((entry) {
                    return Marker(
                      markerId: MarkerId('waypoint_${entry.key}'),
                      position: entry.value,
                      infoWindow: InfoWindow(title: 'Ponto ${entry.key + 1}'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                    );
                  }) ??
                  {},
            },
            polylines: Set<Polyline>.of(_polylines.values),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          if (_isLoadingRoute)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Carregando rota...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _fitMapToRoute() async {
    if (_polylineCoordinates.isEmpty) return;

    final controller = await _mapController.future;
    
    // Calcular bounds para incluir todos os pontos
    double minLat = _polylineCoordinates.first.latitude;
    double maxLat = _polylineCoordinates.first.latitude;
    double minLng = _polylineCoordinates.first.longitude;
    double maxLng = _polylineCoordinates.first.longitude;

    for (LatLng point in _polylineCoordinates) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Adicionar padding
    const double padding = 0.01;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  Future<List<LatLng>> _getPolyLinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    List<PolylineWayPoint> waypoints = [];

    if (widget.waypoints != null && widget.waypoints!.isNotEmpty) {
      waypoints.addAll(
        widget.waypoints!.map(
          (waypoint) => PolylineWayPoint(
            location: '${waypoint.latitude},${waypoint.longitude}',
          ),
        ),
      );
    }

    waypoints.insert(
      0,
      PolylineWayPoint(
        location: '${widget.initialPosition.latitude},${widget.initialPosition.longitude}',
      ),
    );

    waypoints.add(
      PolylineWayPoint(
        location:
            '${widget.destinationPosition.latitude},${widget.destinationPosition.longitude}',
      ),
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _apiKey,
      request: PolylineRequest(
        origin: PointLatLng(
          widget.initialPosition.latitude,
          widget.initialPosition.longitude,
        ),
        destination: PointLatLng(
          widget.destinationPosition.latitude,
          widget.destinationPosition.longitude,
        ),
        wayPoints: waypoints,
        mode: TravelMode.driving,
        optimizeWaypoints: true,
      ),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      return polylineCoordinates;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum ponto de rota encontrado.')),
        );
      }
      return [];
    }
  }

  Future<void> _generatePolylineFromPoints(
    List<LatLng> polylineCoordinates,
  ) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      width: 8,
      points: polylineCoordinates,
    );
    setState(() {
      _polylines[id] = polyline;
    });
  }
}
