import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_textfield.dart';
import 'package:mobile_app/components/map_placeholder.dart';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key});

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  bool _showGroupSelection = false;
  String? _selectedGroup;
  
  // Controladores para os campos de texto
  final TextEditingController _originController = TextEditingController(text: "Av. Maripa - 5498, Centro, Toledo - PR");
  final TextEditingController _destinationController = TextEditingController(text: "Biopark Educação");
  final TextEditingController _departureTimeController = TextEditingController(text: "18:30");
  final TextEditingController _estimatedArrivalController = TextEditingController(text: "18:55");
  final TextEditingController _seatsController = TextEditingController(text: "4");
  
  // Data selecionada
  DateTime _selectedDate = DateTime.now();
  String get formattedDate {
    return "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
  }
  
  // Dados mockados dos grupos
  final List<String> _mockGroups = [
    'Xander\'s Tur',
    'Maria\'s Tur',
    'Rossano\'s Tur',
  ];

  @override
  void dispose() {
    // Limpeza dos controladores quando a página for descartada
    _originController.dispose();
    _destinationController.dispose();
    _departureTimeController.dispose();
    _estimatedArrivalController.dispose();
    _seatsController.dispose();
    super.dispose();
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
            // Mapa (reduzindo o tamanho para acomodar todo o formulário)
            const Expanded(
              flex: 4, // Reduzido de 2 para 1 para dar mais espaço ao formulário
              child: MapPlaceholder(height: double.infinity),
            ),
            
            // Área de informações
            Expanded(
              flex: 10, 
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    // Conteúdo do formulário com scroll
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seletor de Data e Dropdown de Grupos
                            _buildDateAndGroupSelector(colorScheme),
                            
                            const SizedBox(height: 18),
                            
                            // Campo de origem
                            _buildTextField(
                              "Local de saída:",
                              _originController,
                            ),
                            
                            const SizedBox(height: 14),
                            
                            // Campo de horário de saída
                            _buildTextField(
                              "Horário de saída:",
                              _departureTimeController,
                              icon: IconButton(
                                icon: Icon(Icons.access_time, color: colorScheme.primary),
                                onPressed: () => _selectTime(context, _departureTimeController),
                              ),
                            ),
                            
                            const SizedBox(height: 14),
                            
                            // Campo de destino
                            _buildTextField(
                              "Local de chegada:",
                              _destinationController,
                            ),
                            
                            const SizedBox(height: 14),
                            
                            // Campo de horário estimado de chegada
                            _buildTextField(
                              "Horário estimado de chegada:",
                              _estimatedArrivalController,
                              icon: IconButton(
                                icon: Icon(Icons.access_time, color: colorScheme.primary),
                                onPressed: () => _selectTime(context, _estimatedArrivalController),
                              ),
                            ),
                            
                            const SizedBox(height: 14),
                            
                            // Campo de vagas
                            _buildTextField(
                              "Vagas disponíveis:",
                              _seatsController,
                            ),
                            
                            const SizedBox(height: 14),
                            
                            // Distância (somente leitura)
                            _buildInfoSection(
                              colorScheme,
                              "Distância:", 
                              "1,88 km",
                              null
                            ),
                            
                            // Botões de ação
                            const SizedBox(height: 18),
                            _buildActionButtons(colorScheme),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                    
                    // Dropdown de grupos (overlay)
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
  
  // Widget para data e seletor de grupos
  Widget _buildDateAndGroupSelector(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Data com seletor
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
          
          // Seletor de grupo
          SizedBox(
            height: 40,
            child: CustomButton(
              text: _selectedGroup ?? "Grupos",
              variant: ButtonVariant.primary,
              icon: _showGroupSelection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              onPressed: () {
                setState(() {
                  _showGroupSelection = !_showGroupSelection;
                });
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              height: 40,
            ),
          ),
        ],
      ),
    );
  }
  
  // Método para selecionar a data
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
  
  // Método para selecionar o horário
  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime;
    try {
      final parts = controller.text.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]), 
        minute: int.parse(parts[1])
      );
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
  
  // Widget para campos de texto
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    {IconButton? icon}
  ) {
    return CustomTextfield(
      label: label,
      controller: controller,
      obscureText: false,
      icon: icon,
    );
  }
  
  // Widget para as seções de informação (somente leitura)
  Widget _buildInfoSection(ColorScheme colorScheme, String title, String value, String? subtitle) {
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
  
  // Widget para os botões de ação
  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        // Botão Cancelar
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
        
        // Botão Criar viagem
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CustomButton(
              text: "Criar viagem",
              variant: ButtonVariant.primary,
              onPressed: () {
                // Aqui poderíamos validar e enviar os dados para o backend
                final rideData = {
                  'date': formattedDate,
                  'group': _selectedGroup,
                  'origin': _originController.text,
                  'departureTime': _departureTimeController.text,
                  'destination': _destinationController.text,
                  'estimatedArrival': _estimatedArrivalController.text,
                  'seats': _seatsController.text,
                  'distance': '1,88 km' // Em um caso real, isso seria calculado pelo backend
                };
                
                // Debug: exibir os dados no console
                print('Dados da viagem: $rideData');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Viagem criada com sucesso!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
                Navigator.pop(context);
              },
              height: 45,
            ),
          ),
        ),
      ],
    );
  }
  
  // Widget para exibir a lista de grupos quando expandida
  Widget _buildGroupList(ColorScheme colorScheme) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _mockGroups.map((group) => 
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedGroup = group;
                  _showGroupSelection = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      group,
                      style: TextStyle(
                        color: _selectedGroup == group 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _selectedGroup == group 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                      ),
                    ),
                    if (_selectedGroup == group)
                      Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ).toList(),
      ),
    );
  }
}