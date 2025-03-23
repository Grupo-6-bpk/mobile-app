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

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _driverLicenseFocusNode = FocusNode();

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
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
                      title: Text("Dados Pessoais"),
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
                                  onSubmitted: (_) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_driverLicenseFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _driverLicenseController,
                                  focusNode: _driverLicenseFocusNode,
                                  label: "Número da CNH",
                                  obscureText: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      isActive: _currentStep >= 0,
                    ),
                    Step(
                      title: Text("Documentos"),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            "Upload Documentos",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(label: "Frente CNH"),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(label: "Verso CNH"),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Comprovante de Vínculo com BPK",
                            ),
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 1,
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
                      text: _currentStep == 1 ? "Finalizar" : "Próximo",
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
