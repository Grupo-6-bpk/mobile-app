import 'package:flutter/material.dart';
import 'package:mobile_app/components/map_placeholder.dart';
import 'package:mobile_app/models/ride_history.dart';
import 'package:intl/intl.dart';

class RideDetailPage extends StatelessWidget {
  final RideHistory ride;
  
  const RideDetailPage({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho com título e botão de fechar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          ride.type == 'driver' ? Icons.directions_car : Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.title ?? 'Viagem ${DateFormat('dd/MM/yyyy').format(ride.departureTime)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              ride.vehicleInfo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Mapa
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: const MapPlaceholder(height: 150),
              ),
              
              // Informações da viagem
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(context, 'Origem', ride.startAddress),
                    const SizedBox(height: 4),
                    _buildInfoRow(context, 'Destino', ride.endAddress),
                    const SizedBox(height: 4),
                    _buildInfoRow(context, 'Data/Hora', '${DateFormat('dd/MM/yyyy').format(ride.departureTime)} às ${DateFormat('HH:mm').format(ride.departureTime)}'),
                    const SizedBox(height: 4),
                    _buildInfoRow(context, 'Distância', '${ride.distance.toStringAsFixed(1)} km'),
                    const SizedBox(height: 4),
                    _buildInfoRow(context, 'Status', ride.statusText),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Custo total', 'R\$ ${ride.totalCost.toStringAsFixed(2)}', isHighlighted: true),
                    _buildInfoRow(context, 'Sua parte', 'R\$ ${ride.userShare.toStringAsFixed(2)}', isHighlighted: true),
                    if (ride.savings > 0)
                      _buildInfoRow(context, 'Economia', 'R\$ ${ride.savings.toStringAsFixed(2)}', isHighlighted: true, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Participantes:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista de participantes
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: ride.participants.map((participant) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildParticipantItem(context, participant),
                    ),
                  ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isHighlighted = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantItem(BuildContext context, ParticipantHistory participant) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          radius: 16,
          child: Text(
            participant.name[0],
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participant.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              Text(
                '${participant.role} - R\$ ${participant.share.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              // Navegar para o perfil do participante
            },
          ),
        ),
      ],
    );
  }
} 