import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_textfield.dart';
import 'package:mobile_app/components/map_placeholder.dart';
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/models/vehicle.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/group_service.dart';
import 'package:mobile_app/services/vehicle_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key});

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  bool _showGroupSelection = false;
  String? _selectedGroup;
  String _distanceInKm = 'Calculando...';
  double _calculatedDistance = 0.0;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  List<Group> _groups = [];
  Group? _selectedGroupObj;
  bool _isLoadingGroups = false;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _departureTimeController =
      TextEditingController(text: "18:30");
  final TextEditingController _estimatedArrivalController =
      TextEditingController(text: "18:55");
  final TextEditingController _seatsController = TextEditingController(text: "4");

  DateTime _selectedDate = DateTime.now();
  String get formattedDate {
    return "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCurrentLocationAsOrigin();
      _loadVehicles();
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _departureTimeController.dispose();
    _estimatedArrivalController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _setCurrentLocationAsOrigin() async {
    if (!mounted) return;

    bool serviceEnabled;
    LocationPermission permission;

    try {
      if (kDebugMode) {
        print('🔍 Verificando se o serviço de localização está habilitado...');
      }
      
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kDebugMode) {
        print('📍 Serviço de localização habilitado: $serviceEnabled');
      }
      
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço de localização desativado.')),
          );
        }
        return;
      }

      if (kDebugMode) {
        print('🔐 Verificando permissões de localização...');
      }
      
      permission = await Geolocator.checkPermission();
      if (kDebugMode) {
        print('📋 Permissão atual: $permission');
      }
      
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('❌ Permissão negada, solicitando permissão...');
        }
        permission = await Geolocator.requestPermission();
        if (kDebugMode) {
          print('📋 Nova permissão após solicitação: $permission');
        }
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permissão de localização negada.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('🚫 Permissão permanentemente negada');
        }
        if (mounted) {
          setState(() {
            _distanceInKm = 'N/A';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Permissão de localização permanentemente negada.')),
          );
        }
        return;
      }

      if (kDebugMode) {
        print('🎯 Obtendo posição atual...');
      }
      
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (kDebugMode) {
        print('📍 Posição obtida: ${position.latitude}, ${position.longitude}');
      }

      if (!mounted) return;

      const double endLatitude = -24.617581018219294;
      const double endLongitude = -53.71040973288294;
      final double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        endLatitude,
        endLongitude,
      );
      _calculatedDistance = distanceInMeters / 1000;

      if (kDebugMode) {
        print('📏 Distância calculada: ${_calculatedDistance.toStringAsFixed(2)} km');
      }

      // Usar apenas as coordenadas por enquanto
      final coordinates = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      
      if (kDebugMode) {
        print('📍 Usando coordenadas: $coordinates');
      }

      setState(() {
        _originController.text = coordinates;
        _distanceInKm = '${_calculatedDistance.toStringAsFixed(2)} km';
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro geral na obtenção de localização: $e');
      }
      if (mounted) {
        setState(() {
          _originController.text = 'Localização não encontrada';
          _distanceInKm = 'N/A';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao obter localização')),
        );
      }
    }
  }

  Future<void> _loadVehicles() async {
    try {
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        return;
      }

      final vehicles = await VehicleService.getVehiclesByDriverId();

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          if (vehicles.isNotEmpty) {
            _selectedVehicle = vehicles.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        if (!e.toString().contains('Usuário não autenticado')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar veículos: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadGroups() async {
    try {
      setState(() {
        _isLoadingGroups = true;
      });

      final authService = AuthService();
      if (!authService.isAuthenticated) {
        setState(() {
          _isLoadingGroups = false;
        });
        return;
      }

      final currentUser = authService.currentUser;
      if (currentUser?.userId == null) {
        setState(() {
          _isLoadingGroups = false;
        });
        return;
      }

      final groups =
          await GroupService.getGroupsByUser(currentUser!.userId!, 'driver');

      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar grupos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Criar Viagem"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 4,
              child: MapPlaceholder(height: double.infinity),
            ),
            Expanded(
              flex: 10,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateAndGroupSelector(colorScheme),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _originController,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: "Local de saída:",
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              "Horário de saída:",
                              _departureTimeController,
                              icon: IconButton(
                                icon: Icon(Icons.access_time,
                                    color: colorScheme.primary),
                                onPressed: () =>
                                    _selectTime(context, _departureTimeController),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              initialValue: "Biopark Educação",
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: "Local de chegada:",
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              "Horário estimado de chegada:",
                              _estimatedArrivalController,
                              icon: IconButton(
                                icon: Icon(Icons.access_time,
                                    color: colorScheme.primary),
                                onPressed: () => _selectTime(
                                    context, _estimatedArrivalController),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              "Vagas disponíveis:",
                              _seatsController,
                            ),
                            const SizedBox(height: 14),
                            _buildInfoSection(
                                colorScheme, "Distância:", _distanceInKm, null),
                            const SizedBox(height: 14),
                            
                            
                            const SizedBox(height: 18),
                            _buildActionButtons(colorScheme),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                    if (_showGroupSelection)
                      Positioned(
                        top: 60,
                        right: 20,
                        child: _buildGroupList(colorScheme),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndGroupSelector(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Data:",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: CustomButton(
              text: _selectedGroup ?? "Grupos",
              variant: ButtonVariant.primary,
              icon: _showGroupSelection
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              onPressed: () {
                setState(() {
                  _showGroupSelection = !_showGroupSelection;
                });
                if (_showGroupSelection && _groups.isEmpty) {
                  _loadGroups();
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              height: 40,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime;
    try {
      final parts = controller.text.split(':');
      initialTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      initialTime = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      controller.text = "$hour:$minute";
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {IconButton? icon}) {
    return CustomTextfield(
      label: label,
      controller: controller,
      obscureText: false,
      icon: icon,
    );
  }

  Widget _buildInfoSection(
      ColorScheme colorScheme, String title, String value, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CustomButton(
              text: "Cancelar",
              variant: ButtonVariant.secondary,
              onPressed: () {
                Navigator.pop(context);
              },
              height: 45,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CustomButton(
              text: "Criar viagem",
              variant: ButtonVariant.primary,
              onPressed: _createRide,
              height: 45,
            ),
          ),
        ),
      ],
    );
  }

  String _getDepartureDateTimeIso() {
    try {
      final parts = _departureTimeController.text.split(':');
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return dateTime.toUtc().toIso8601String();
    } catch (e) {
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  Future<void> _createRide() async {
    final authService = AuthService();
    if (!authService.isAuthenticated || authService.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para criar uma viagem.')),
      );
      return;
    }

    if (_selectedVehicle == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Nenhum veículo selecionado. Cadastre um veículo primeiro.')),
      );
      return;
    }

    if (_originController.text.contains('Erro') ||
        _originController.text.contains('não encontrada') ||
        _distanceInKm == 'N/A') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível obter a localização de partida.')),
      );
      return;
    }

    if (_selectedGroupObj != null) {
      try {
        final messageContent = '''
🚗 **Nova carona criada!**

📍 **De:** ${_originController.text}
🎯 **Para:** Biopark Educação
⏰ **Horário:** ${_departureTimeController.text}
📅 **Data:** $formattedDate
🚙 **Veículo:** ${_selectedVehicle!.brand} ${_selectedVehicle!.model}
💺 **Vagas:** ${_seatsController.text}
📏 **Distância:** $_distanceInKm

Interessados podem entrar em contato!
        '''
            .trim();

        if (kDebugMode) {
          print('Mensagem para grupo ${_selectedGroupObj!.name}: $messageContent');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao enviar mensagem para o grupo: $e');
        }
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'startLocation': _originController.text,
        'endLocation': "-24.617581018219294,-53.71040973288294",
        'distance': _calculatedDistance,
        'departureTime': _getDepartureDateTimeIso(),
        'fuelPrice': 5.5,
        'totalSeats': int.tryParse(_seatsController.text) ?? 4,
        'driverId': authService.currentUser!.userId,
        'vehicleId': _selectedVehicle!.id,
      });

      final url = Uri.parse('${AppConfig.baseUrl}/api/rides/');
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Viagem criada com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro ao criar viagem: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar viagem: $e')),
      );
    }
  }

  Widget _buildGroupList(ColorScheme colorScheme) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoadingGroups)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (_groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Nenhum grupo encontrado',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._groups.map(
              (group) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGroup = group.name;
                      _selectedGroupObj = group;
                      _showGroupSelection = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: TextStyle(
                              color: _selectedGroupObj?.id == group.id
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: _selectedGroupObj?.id == group.id
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_selectedGroupObj?.id == group.id)
                          Icon(Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
