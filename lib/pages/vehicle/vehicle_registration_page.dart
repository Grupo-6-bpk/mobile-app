import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_textfield.dart';
import 'package:mobile_app/components/custom_file_picker.dart';
import 'package:mobile_app/models/vehicle.dart';
import 'package:mobile_app/services/vehicle_service.dart';

class VehicleRegistrationPage extends StatefulWidget {
  final Vehicle? vehicleToEdit;

  const VehicleRegistrationPage({
    super.key,
    this.vehicleToEdit,
  });

  @override
  State<VehicleRegistrationPage> createState() =>
      _VehicleRegistrationPageState();
}

class _VehicleRegistrationPageState extends State<VehicleRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // Controllers
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _renavamController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();  final TextEditingController _fuelConsumptionController =
      TextEditingController();

  // File pickers for car image
  final ValueNotifier<FilePickerResult?> _carImageNotifier =
      ValueNotifier<FilePickerResult?>(null);
  final ValueNotifier<String?> _carImageUrlNotifier = ValueNotifier<String?>(null);

  // Focus Nodes
  final FocusNode _modelFocusNode = FocusNode();
  final FocusNode _brandFocusNode = FocusNode();
  final FocusNode _yearFocusNode = FocusNode();
  final FocusNode _colorFocusNode = FocusNode();
  final FocusNode _renavamFocusNode = FocusNode();
  final FocusNode _plateFocusNode = FocusNode();
  final FocusNode _fuelConsumptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.vehicleToEdit != null) {
      _populateFieldsForEdit();
    }
  }  void _populateFieldsForEdit() {
    final vehicle = widget.vehicleToEdit!;
    _modelController.text = vehicle.model;
    _brandController.text = vehicle.brand;
    _yearController.text = vehicle.year.toString();
    _colorController.text = vehicle.color;
    _renavamController.text = vehicle.renavam;
    _plateController.text = vehicle.plate;
    _fuelConsumptionController.text = vehicle.fuelConsumption.toString();
    
    // Set the car image URL if available
    if (vehicle.carImageUrl != null) {
      _carImageUrlNotifier.value = vehicle.carImageUrl;
    }
  }
  @override
  void dispose() {
    // Dispose controllers
    _modelController.dispose();
    _brandController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _renavamController.dispose();
    _plateController.dispose();
    _fuelConsumptionController.dispose();

    // Dispose focus nodes
    _modelFocusNode.dispose();
    _brandFocusNode.dispose();
    _yearFocusNode.dispose();
    _colorFocusNode.dispose();
    _renavamFocusNode.dispose();
    _plateFocusNode.dispose();
    _fuelConsumptionFocusNode.dispose();

    super.dispose();
  }
  bool _validateForm() {
    return _modelController.text.isNotEmpty &&
        _brandController.text.isNotEmpty &&
        _yearController.text.isNotEmpty &&
        _colorController.text.isNotEmpty &&
        _renavamController.text.isNotEmpty &&
        _plateController.text.isNotEmpty &&
        _fuelConsumptionController.text.isNotEmpty;
  }
  Future<void> _registerVehicle() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {      final vehicle = Vehicle(
        id: widget.vehicleToEdit?.id,
        model: _modelController.text.trim(),
        brand: _brandController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        color: _colorController.text.trim(),
        renavam: _renavamController.text.trim(),
        plate: _plateController.text.trim().toUpperCase(),
        fuelConsumption: double.parse(_fuelConsumptionController.text.trim()),
        carImageUrl: _carImageUrlNotifier.value,
        driverId: 0, // This will be set by the service using the current user
      );

      bool success;
      String successMessage;
      
      if (widget.vehicleToEdit != null) {
        success = await VehicleService.updateVehicle(vehicle);
        successMessage = 'Veículo atualizado com sucesso!';
      } else {
        success = await VehicleService.registerVehicle(vehicle);
        successMessage = 'Veículo cadastrado com sucesso!';
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ${widget.vehicleToEdit != null ? 'atualizar' : 'cadastrar'} veículo')),
        );
      }    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Remove "Exception: " prefix if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        // Handle authentication errors specifically
        if (errorMessage.contains('Usuário não autenticado') || 
            errorMessage.contains('Sessão expirada')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
          // Optionally navigate to login screen
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $errorMessage')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,      appBar: AppBar(
        title: Text(widget.vehicleToEdit != null ? 'Editar Veículo' : 'Cadastrar Veículo'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações do Veículo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Marca e Modelo
                Row(
                  children: [
                    Expanded(
                      child: CustomTextfield(
                        controller: _brandController,
                        focusNode: _brandFocusNode,
                        label: 'Marca',
                        obscureText: false,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_modelFocusNode),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextfield(
                        controller: _modelController,
                        focusNode: _modelFocusNode,
                        label: 'Modelo',
                        obscureText: false,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_yearFocusNode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),                // Ano e Cor
                Row(
                  children: [
                    Expanded(
                      child: CustomTextfield(
                        controller: _yearController,
                        focusNode: _yearFocusNode,
                        label: 'Ano',
                        obscureText: false,
                        isNumeric: true,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_colorFocusNode),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomTextfield(
                        controller: _colorController,
                        focusNode: _colorFocusNode,
                        label: 'Cor',
                        obscureText: false,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_plateFocusNode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Placa
                CustomTextfield(
                  controller: _plateController,
                  focusNode: _plateFocusNode,
                  label: 'Placa (ex: ABC1234)',
                  obscureText: false,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_renavamFocusNode),
                ),
                const SizedBox(height: 20),

                // Renavam
                CustomTextfield(
                  controller: _renavamController,
                  focusNode: _renavamFocusNode,
                  label: 'Renavam',
                  obscureText: false,
                  isNumeric: true,
                  onSubmitted: (_) => FocusScope.of(context)
                      .requestFocus(_fuelConsumptionFocusNode),
                ),
                const SizedBox(height: 20),                // Consumo de combustível
                CustomTextfield(
                  controller: _fuelConsumptionController,
                  focusNode: _fuelConsumptionFocusNode,
                  label: 'Consumo (km/l)',
                  obscureText: false,
                  isNumeric: true,
                ),
                const SizedBox(height: 20),

                // Imagem do veículo
                SizedBox(
                  width: double.infinity,
                  child: CustomFilePicker(
                    label: "Foto do Veículo",
                    fileNotifier: _carImageNotifier,
                    fileUrl: _carImageUrlNotifier,
                  ),
                ),
                const SizedBox(height: 40),

                // Botão de cadastrar/editar
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: _isLoading ? null : _registerVehicle,
                    variant: ButtonVariant.primary,
                    text: _isLoading 
                        ? (widget.vehicleToEdit != null ? 'Atualizando...' : 'Cadastrando...') 
                        : (widget.vehicleToEdit != null ? 'Atualizar Veículo' : 'Cadastrar Veículo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
