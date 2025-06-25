import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CustomMap extends StatefulWidget {
  final double height;

  final LatLng destinationPosition;
  final List<LatLng>? waypoints;

  const CustomMap({
    super.key,
    required this.destinationPosition,
    this.waypoints,

    this.height = 200,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  LatLng? initialPosition;

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  final Map<PolylineId, Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];

  @override
  void initState() {
    super.initState();
    _setInitialPositionBasedOnLocation().then((_) {
      _getPolyLinePoints().then((coordinates) {
        _polylineCoordinates = coordinates;
        _generatePolylineFromPoints(_polylineCoordinates);
      });
    });
  }

  Future<void> _setInitialPositionBasedOnLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço de localização desativado.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização permanentemente negada.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        initialPosition = LatLng(position.latitude, position.longitude);
      });

      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(initialPosition!));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localização inicial definida com sucesso.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao obter localização: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child:
          initialPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                },
                initialCameraPosition: CameraPosition(
                  target: widget.destinationPosition,
                  zoom: 10,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('start'),
                    position: initialPosition!,
                    infoWindow: InfoWindow(title: 'Início'),
                  ),
                  Marker(
                    markerId: const MarkerId('end'),
                    position: widget.destinationPosition,
                    infoWindow: InfoWindow(title: 'Destino'),
                  ),
                  ...widget.waypoints?.map((waypoint) {
                        return Marker(
                          markerId: MarkerId(
                            'waypoint_${waypoint.latitude}_${waypoint.longitude}',
                          ),
                          position: waypoint,
                          infoWindow: InfoWindow(title: 'Ponto de Parada'),
                        );
                      }) ??
                      {},
                },
                polylines: Set<Polyline>.of(_polylines.values),
              ),
    );
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
        location: '${initialPosition!.latitude},${initialPosition!.longitude}',
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
          initialPosition!.latitude,
          initialPosition!.longitude,
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
