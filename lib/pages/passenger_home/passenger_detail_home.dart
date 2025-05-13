import 'package:flutter/material.dart';

class PassengerDetailHome extends StatelessWidget {
  final Map<String, dynamic> carona;

  const PassengerDetailHome({super.key, required this.carona});

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
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(carona['avatar']),
          radius: 25,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                carona['nome'],
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Veículo: Sonic 3.0 Turbo',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
              ),
              Text(
                'Cor: Branco',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvaliacao(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            'Avaliação do motorista: ',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < carona['estrelas'] ? Icons.star : Icons.star_border,
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
    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: RoutePainter(),
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildInformacoesViagem(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoLine('Saída', carona['local'], theme),
        _buildInfoLine('Horário de saída', carona['horario'], theme),
        _buildInfoLine('Celular', '45 98432-3230', theme),
        if (carona.containsKey('preco'))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Valor máximo da viagem: ${carona['preco']}',
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
