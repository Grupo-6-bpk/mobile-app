import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/ride.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/user_service.dart';

class PassengerDetailHome extends StatelessWidget {
  final Ride ride;

  const PassengerDetailHome({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCloseButton(context, theme),
            _buildMotoristaInfo(theme),
            const SizedBox(height: 8),
            _buildAvaliacao(theme),
            _buildMapaPlaceholder(theme),
            _buildInformacoesViagem(theme),
            const SizedBox(height: 16),
            _buildBotoesAcao(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, ThemeData theme) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildMotoristaInfo(ThemeData theme) {
    return FutureBuilder<User>(
        future: UserService.getUserById(ride.driver.userId),
        builder: (context, snapshot) {
          final userName = snapshot.hasData ? snapshot.data!.name : 'Carregando...';
          return Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade800,
                radius: 25,
                child: const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Veículo: ${ride.vehicle.brand} ${ride.vehicle.model}',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface, fontSize: 12),
                    ),
                    Text(
                      'Placa: ${ride.vehicle.plate}',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  Widget _buildAvaliacao(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'Avaliação do motorista: ',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
            ),
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < 4 ? Icons.star : Icons.star_border, // Placeholder
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaPlaceholder(ThemeData theme) {
    // This can be replaced with a real map later
    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surface,
      ),
      child: const Center(child: Text('Placeholder para o Mapa da Rota')),
    );
  }

  Widget _buildInformacoesViagem(ThemeData theme) {
    final formattedTime = DateFormat('HH:mm').format(ride.departureTime);
    final formattedPrice = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(ride.pricePerMember ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoLine('Saída', ride.startLocation, theme),
        _buildInfoLine('Destino', ride.endLocation, theme),
        _buildInfoLine('Horário de saída', formattedTime, theme),
        _buildInfoLine('Assentos disponíveis', ride.availableSeats.toString(), theme),
        if (ride.pricePerMember != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Valor por pessoa: $formattedPrice',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoLine(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
      ),
    );
  }

  Widget _buildBotoesAcao(BuildContext context, ThemeData theme) {
    // The logic for these buttons can be implemented similarly to the request button.
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Enviar Mensagem'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Solicitar'),
          ),
        ),
      ],
    );
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.4);

    canvas.drawPath(path, paint);

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.5), 5, Paint()..color = Colors.green);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.4), 5, Paint()..color = Colors.red);

    for (double i = 0.2; i < 0.9; i += 0.2) {
      canvas.drawCircle(
        Offset(size.width * i, size.height * (i < 0.5 ? 0.4 : 0.3)),
        3,
        Paint()..color = Colors.blue,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
