import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_file_picker.dart';
import 'package:mobile_app/components/custom_textfield.dart';

class DriverSignUpPage extends StatefulWidget {
  const DriverSignUpPage({super.key});

  @override
  State<DriverSignUpPage> createState() => _DriverSignUpPageState();
}

class _DriverSignUpPageState extends State<DriverSignUpPage> {
  int _currentStep = 0;
  bool isFirstStepValid = false;
  bool isSecondStepValid = false;
  bool isThirdStepValid = false;
  final double horizontalPadding = 10.0;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _driverLicenseController =
      TextEditingController();

  final TextEditingController _renavamController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carPlateController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _driverLicenseFocusNode = FocusNode();
  final FocusNode _renavamFocusNode = FocusNode();
  final FocusNode _carModelFocusNode = FocusNode();
  final FocusNode _carPlateFocusNode = FocusNode();

  final ValueNotifier<FilePickerResult?> _frontCNHNotifier =
      ValueNotifier<FilePickerResult?>(null);
  final ValueNotifier<FilePickerResult?> _backCNHNotifier =
      ValueNotifier<FilePickerResult?>(null);
  final ValueNotifier<FilePickerResult?> _proofOfLinkNotifier =
      ValueNotifier<FilePickerResult?>(null);
  final ValueNotifier<FilePickerResult?> _carPhotoNotifier =
      ValueNotifier<FilePickerResult?>(null);

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_passwordsMatch()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Senhas não conferem")));
      } else if (_validateFirstStep()) {
        setState(() {
          isFirstStepValid = true;
          _currentStep++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos")),
        );
      }
    } else if (_currentStep == 1) {
      if (_validateSecondStep()) {
        setState(() {
          isSecondStepValid = true;
          _currentStep++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos")),
        );
      }
    } else if (_currentStep == 2) {}
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _passwordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  bool _validateFirstStep() {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  bool _validateSecondStep() {
    return _driverLicenseController.text.isNotEmpty &&
        _frontCNHNotifier.value != null &&
        _backCNHNotifier.value != null &&
        _proofOfLinkNotifier.value != null;
  }

  StepState _getStepState(int step) {
    if (_currentStep > step) {
      return StepState.complete;
    } else if (_currentStep == step) {
      return StepState.editing;
    } else {
      return StepState.indexed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Expanded(
                child: Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepContinue: _nextStep,
                  onStepCancel: _previousStep,
                  controlsBuilder: (context, details) {
                    return Container();
                  },
                  steps: [
                    Step(
                      title: Text("Dados"),
                      content: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "Cadastro de Motorista",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomTextfield(
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocusNode,
                                    label: "Primeiro Nome",
                                    obscureText: false,
                                    onSubmitted: (_) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_lastNameFocusNode);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: CustomTextfield(
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocusNode,
                                    label: "Último Nome",
                                    obscureText: false,
                                    onSubmitted: (_) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_emailFocusNode);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Column(
                              children: [
                                CustomTextfield(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: "Email",
                                  obscureText: false,
                                  onSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_passwordFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  label: "Senha",
                                  obscureText: true,
                                  onSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_confirmPasswordFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _confirmPasswordController,
                                  label: "Confirmar Senha",
                                  obscureText: true,
                                  focusNode: _confirmPasswordFocusNode,
                                  onSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_phoneFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _phoneController,
                                  focusNode: _phoneFocusNode,
                                  label: "Telefone",
                                  obscureText: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      isActive: _currentStep >= 0,
                      state: _getStepState(0),
                    ),
                    Step(
                      title: Text("Documentos"),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            "Documentos Pessoais",
                            textWidthBasis: TextWidthBasis.longestLine,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextfield(
                            controller: _driverLicenseController,
                            focusNode: _driverLicenseFocusNode,
                            label: "Número da CNH",
                            obscureText: false,
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Frente CNH",
                              fileNotifier: _frontCNHNotifier,
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Verso CNH",
                              fileNotifier: _backCNHNotifier,
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Comprovante de Vínculo com BPK",
                              fileNotifier: _proofOfLinkNotifier,
                            ),
                          ),
                        ],
                      ),
                      isActive: _currentStep == 1,
                      state: _getStepState(1),
                    ),
                    Step(
                      title: Text("Carro"),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            "Documentos do Carro",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Imagem do carro",
                              fileNotifier: _carPhotoNotifier,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextfield(
                            controller: _renavamController,
                            focusNode: _renavamFocusNode,
                            onSubmitted:
                                (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_carModelFocusNode),
                            label: "Renavam",
                            obscureText: false,
                          ),
                          const SizedBox(height: 20),
                          CustomTextfield(
                            controller: _carModelController,
                            focusNode: _carModelFocusNode,
                            onSubmitted:
                                (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_carPlateFocusNode),
                            label: "Modelo do Carro",
                            obscureText: false,
                          ),
                          const SizedBox(height: 20),
                          CustomTextfield(
                            controller: _carPlateController,
                            focusNode: _carPlateFocusNode,
                            label: "Placa do Carro",
                            obscureText: false,
                          ),
                        ],
                      ),
                      isActive: _currentStep == 2,
                      state: _getStepState(2),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep == 0)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Voltar"),
                      ),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _previousStep,
                        child: const Text("Voltar"),
                      ),
                    CustomButton(
                      onPressed: _nextStep,
                      bgColor: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      text: _currentStep == 2 ? "Finalizar" : "Próximo",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
