import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/ride.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_map.dart';
import 'package:mobile_app/services/maps_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PassengerDetailHome extends StatefulWidget {
  final Ride ride;

  const PassengerDetailHome({super.key, required this.ride});

  @override
  State<PassengerDetailHome> createState() => _PassengerDetailHomeState();
}

class _PassengerDetailHomeState extends State<PassengerDetailHome> {
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  String? _translatedStartLocation;
  final MapsService _mapsService = MapsService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _translateStartLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
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
      debugPrint('Erro ao obter localização: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _translateStartLocation() async {
    try {
      final startLocation = widget.ride.startLocation;
      
      // Verificar se startLocation contém coordenadas (formato: "lat,lng")
      if (startLocation.contains(',')) {
        final coords = startLocation.split(',');
        if (coords.length == 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());
          
          if (lat != null && lng != null) {
            // Traduzir coordenadas para endereço
            final address = await _mapsService.getAddressFromLatLng(lat, lng);
            
            if (mounted && address != null) {
              setState(() {
                _translatedStartLocation = address;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao traduzir localização de origem: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header com botão de fechar
          _buildHeader(context, theme),

          // Conteúdo principal
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do motorista
                  _buildMotoristaInfo(theme),
                  const SizedBox(height: 20),

                  // Avaliação
                  _buildAvaliacao(theme),
                  const SizedBox(height: 20),

                  // Mapa placeholder
                  _buildMapaPlaceholder(theme),
                  const SizedBox(height: 20),

                  // Informações da viagem
                  _buildInformacoesViagem(theme),
                  const SizedBox(height: 20),

                  // Botões de ação
                  _buildBotoesAcao(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Detalhes da Carona',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMotoristaInfo(ThemeData theme) {
    return FutureBuilder<User>(
      future: UserService.getUserById(widget.ride.driver.userId),
      builder: (context, snapshot) {
        final userName =
            snapshot.hasData ? snapshot.data!.name : 'Carregando...';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Avatar do motorista
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Informações do motorista
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Motorista',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.ride.vehicle.brand} ${widget.ride.vehicle.model}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.confirmation_number,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.ride.vehicle.plate,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvaliacao(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(width: 8),
          Text(
            'Avaliação do motorista',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < 4 ? Icons.star : Icons.star_border,
                color: const Color(0xFFFFD700),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaPlaceholder(ThemeData theme) {
    // Coordenadas do Biopark Educação (destino fixo)
    const LatLng bioParkLocation = LatLng(-25.4284, -49.2733);
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoadingLocation || _currentLocation == null
            ? Container(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoadingLocation) ...[
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Obtendo localização...',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.location_off,
                          size: 32,
                          color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Localização não disponível',
                          style: TextStyle(
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : CustomMap(
                height: 200,
                initialPosition: _currentLocation!,
                destinationPosition: bioParkLocation,
                waypoints: _parseWaypoints(),
              ),
      ),
    );
  }

  List<LatLng>? _parseWaypoints() {
    try {
      // Se houver coordenadas na localização de início, usar como waypoint
      final startLocation = widget.ride.startLocation;
      if (startLocation.contains(',')) {
        final coords = startLocation.split(',');
        if (coords.length == 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());
          if (lat != null && lng != null) {
            return [LatLng(lat, lng)];
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao parsear waypoints: $e');
      return null;
    }
  }

  Widget _buildInformacoesViagem(ThemeData theme) {
    final formattedTime = DateFormat('HH:mm').format(widget.ride.departureTime);
    final formattedPrice = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(widget.ride.pricePerMember ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações da Viagem',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            theme,
            Icons.location_on,
            'Origem',
            _translatedStartLocation ?? widget.ride.startLocation,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            theme,
            Icons.location_on_outlined,
            'Destino',
            widget.ride.endLocation,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            theme,
            Icons.access_time,
            'Horário de Saída',
            formattedTime,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            theme,
            Icons.event_seat,
            'Assentos Disponíveis',
            '${widget.ride.availableSeats}/${widget.ride.totalSeats}',
          ),

          if (widget.ride.pricePerMember != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Valor por pessoa:',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedPrice,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotoesAcao(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Enviar Mensagem',
        onPressed: () {},
        variant: ButtonVariant.secondary,
        height: 48,
      ),
    );
  }


}
