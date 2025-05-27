import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_file_picker.dart';
import 'package:mobile_app/components/custom_textfield.dart';

class PassengerSignUpPage extends StatefulWidget {
  const PassengerSignUpPage({super.key});

  @override
  State<PassengerSignUpPage> createState() => _PassengerSignUpPageState();
}

class _PassengerSignUpPageState extends State<PassengerSignUpPage> {
  int _currentStep = 0;
  bool isFirstStepValid = false;
  bool isSecondStepValid = false;
  final double horizontalPadding = 10.0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final ValueNotifier<FilePickerResult?> _frontDocument =
      ValueNotifier<FilePickerResult?>(null);
  final ValueNotifier<String?> _frontDocumentUrl = ValueNotifier<String?>(null);

  final ValueNotifier<FilePickerResult?> _backDocument =
      ValueNotifier<FilePickerResult?>(null);
  final ValueNotifier<String?> _backDocumentUrl = ValueNotifier<String?>(null);

  final ValueNotifier<FilePickerResult?> _linkComprovation =
      ValueNotifier<FilePickerResult?>(null);
  final ValueNotifier<String?> _linkComprovationUrl = ValueNotifier<String?>(
    null,
  );

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _cpfFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_passwordsMatch()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("As senhas não coincidem")),
        );
      } else if (_nameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _cpfController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos")),
        );
      } else {
        setState(() => _currentStep++);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _passwordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  StepState getStepState(int step) {
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
                      title: Text(
                        "Dados",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "Cadastro passageiro",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
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
                                    controller: _nameController,
                                    label: "Nome",
                                    obscureText: false,
                                    focusNode: _nameFocusNode,
                                    onSubmitted: (value) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_lastNameFocusNode);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomTextfield(
                                    controller: _lastNameController,
                                    label: "Sobrenome",
                                    obscureText: false,
                                    focusNode: _lastNameFocusNode,
                                    onSubmitted: (value) {
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
                                  label: "Email",
                                  obscureText: false,
                                  focusNode: _emailFocusNode,
                                  onSubmitted: (value) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_phoneFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _phoneController,
                                  label: "Telefone",
                                  obscureText: false,
                                  focusNode: _phoneFocusNode,
                                  onSubmitted: (value) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_cpfFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _cpfController,
                                  label: "CPF",
                                  obscureText: false,
                                  focusNode: _cpfFocusNode,
                                  onSubmitted: (value) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_passwordFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _passwordController,
                                  label: "Senha",
                                  obscureText: true,
                                  focusNode: _passwordFocusNode,
                                  onSubmitted: (value) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_confirmPasswordFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                CustomTextfield(
                                  controller: _confirmPasswordController,
                                  label: "Confirmar senha",
                                  obscureText: true,
                                  focusNode: _confirmPasswordFocusNode,
                                  onSubmitted: (value) {
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                      isActive: _currentStep == 0,
                      state: getStepState(0),
                    ),
                    Step(
                      title: Text(
                        "Upload documentos",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "Envio de documentos",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Frente RG",
                              fileNotifier: _frontDocument,
                              fileUrl: _frontDocumentUrl,
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Verso RG",
                              fileNotifier: _backDocument,
                              fileUrl: _backDocumentUrl,
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: CustomFilePicker(
                              label: "Comprovante vínculo Biopark",
                              fileNotifier: _linkComprovation,
                              fileUrl: _linkComprovationUrl,
                            ),
                          ),
                        ],
                      ),
                      isActive: _currentStep == 1,
                      state: getStepState(1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
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
                      variant: ButtonVariant.primary,
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
