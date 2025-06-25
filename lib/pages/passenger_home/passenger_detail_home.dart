import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/ride.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/ride_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/config/app_config.dart';

class PassengerDetailHome extends StatefulWidget {
  final Ride ride;

  const PassengerDetailHome({super.key, required this.ride});

  @override
  State<PassengerDetailHome> createState() => _PassengerDetailHomeState();
}

class _PassengerDetailHomeState extends State<PassengerDetailHome> {
  bool _isRequested = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRequested();
  }

  Future<void> _checkIfAlreadyRequested() async {
    try {
      final authService = AuthService();
      final passengerId = authService.currentUser?.passenger?.id;

      if (passengerId != null) {
        final requests = await RideService.getRideRequestsByPassenger(
          passengerId,
        );
        final alreadyRequested = requests.any(
          (req) =>
              (req['rideId'] == widget.ride.id) &&
              (req['status'] == null ||
                  req['status'].toString().toUpperCase() == 'PENDING' ||
                  req['status'].toString().toUpperCase() == 'APPROVED'),
        );

        if (mounted) {
          setState(() {
            _isRequested = alreadyRequested;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar solicitações: $e');
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
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          // Placeholder do mapa
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 32,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rota da Viagem',
                    style: TextStyle(
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Indicadores de origem e destino
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Origem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Destino',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            widget.ride.startLocation,
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
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Enviar Mensagem',
            onPressed: () {},
            variant: ButtonVariant.secondary,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildRequestButton(context, theme)),
      ],
    );
  }

  Widget _buildRequestButton(BuildContext context, ThemeData theme) {
    if (_isLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_isRequested) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Solicitado',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomButton(
      text: 'Solicitar',
      onPressed: () => _onSolicitarPressed(context),
      variant: ButtonVariant.primary,
      height: 48,
    );
  }

  Future<void> _onSolicitarPressed(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verifica e solicita permissão de localização, se necessário
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização permanentemente negada.'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtém a localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String startLocation = '${position.latitude},${position.longitude}';
      String endLocation = 'bpkedu';

      // Pegue o id do passageiro autenticado
      final authService = AuthService();
      final passengerId = authService.currentUser?.passenger?.id;

      if (passengerId == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não autenticado ou não é passageiro!'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Buscar status da viagem e vagas disponíveis antes de solicitar
      final rideDetails = await RideService.getRideById(widget.ride.id);
      if (rideDetails == null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Viagem não encontrada.')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verificar status da viagem
      final status =
          rideDetails!['status']?.toString().toUpperCase() ?? 'PENDING';
      if (status != 'PENDING' && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não é possível solicitar carona para uma viagem já iniciada, finalizada ou cancelada (status: $status).',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verificar se já existe solicitação pendente/aprovada para o passageiro nesta viagem
      final requests = await RideService.getRideRequestsByPassenger(
        passengerId!,
      );
      final alreadyRequested = requests.any(
        (req) =>
            (req['rideId'] == widget.ride.id) &&
            (req['status'] == null ||
                req['status'].toString().toUpperCase() == 'PENDING' ||
                req['status'].toString().toUpperCase() == 'APPROVED'),
      );
      if (alreadyRequested && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Você já possui uma solicitação pendente ou aprovada para esta viagem.',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
          _isRequested = true;
        });
        return;
      }

      await criarSolicitacaoCarona(
        startLocation,
        endLocation,
        widget.ride.id,
        passengerId,
      );

      if (context.mounted) {
        setState(() {
          _isLoading = false;
          _isRequested = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solicitação enviada com sucesso!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Fechar o diálogo após alguns segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar solicitação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final path =
        Path()
          ..moveTo(size.width * 0.1, size.height * 0.5)
          ..lineTo(size.width * 0.3, size.height * 0.3)
          ..lineTo(size.width * 0.5, size.height * 0.6)
          ..lineTo(size.width * 0.7, size.height * 0.2)
          ..lineTo(size.width * 0.9, size.height * 0.4);

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.5),
      5,
      Paint()..color = Colors.green,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.4),
      5,
      Paint()..color = Colors.red,
    );

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

Future<void> criarSolicitacaoCarona(
  String startLocation,
  String endLocation,
  int rideId,
  int passengerId,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(AppConfig.tokenKey);

  final headers = {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  final body = jsonEncode({
    'rideId': rideId,
    'startLocation': startLocation,
    'endLocation': endLocation,
    'passengerId': passengerId,
  });

  final url = Uri.parse('${AppConfig.baseUrl}/api/ride-requests/');
  final response = await http.post(url, headers: headers, body: body);

  debugPrint('Status: ${response.statusCode}');
  debugPrint('Response: ${response.body}');

  if (response.statusCode == 201 || response.statusCode == 200) {
    // sucesso
  } else {
    // erro
  }
}
