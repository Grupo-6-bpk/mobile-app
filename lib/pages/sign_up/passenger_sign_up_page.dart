import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_button.dart';
import 'package:mobile_app/components/custom_file_picker.dart';
import 'package:mobile_app/components/custom_textfield.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/user_service.dart';

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
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

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
  final FocusNode _streetFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _zipCodeFocusNode = FocusNode();

  void _nextStep() async {
    if (_currentStep == 0) {
      if (!_passwordsMatch()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("As senhas não coincidem")),
        );
      } else if (!_validateFirstStep()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos")),
        );
      } else {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      await _createPassenger();
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

  bool _validateFirstStep() {
    return _nameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _cpfController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _streetController.text.isNotEmpty &&
        _numberController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _zipCodeController.text.isNotEmpty &&
        _passwordsMatch();
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

  Future<void> _createPassenger() async {
    User passenger = User(
      name: _nameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      cpf: _cpfController.text,
      phone: _phoneController.text,
      street: _streetController.text,
      cnh: "",
      cnhBackUrl: null,
      cnhFrontUrl: null,
      rgFrontUrl: _frontDocumentUrl.value,
      rgBackUrl: _backDocumentUrl.value,
      bpkLinkUrl: _linkComprovationUrl.value,
      number: int.parse(_numberController.text),
      city: _cityController.text,
      zipcode: _zipCodeController.text,
      createdAt: DateTime.now(),
      isDriver: false,
      isPassenger: true,
      verified: false,
    );

    bool success = await UserService.registerUser(passenger);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passageiro realizado com sucesso!")),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao realizar cadastro")),
      );
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
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_streetFocusNode);
                                  },
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextfield(
                                        controller: _streetController,
                                        label: "Rua",
                                        obscureText: false,
                                        focusNode: _streetFocusNode,
                                        onSubmitted: (value) {
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(_numberFocusNode);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomTextfield(
                                        controller: _numberController,
                                        label: "Número",
                                        obscureText: false,
                                        focusNode: _numberFocusNode,
                                        onSubmitted: (value) {
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(_cityFocusNode);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextfield(
                                        controller: _cityController,
                                        label: "Cidade",
                                        obscureText: false,
                                        focusNode: _cityFocusNode,
                                        onSubmitted: (value) {
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(_zipCodeFocusNode);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomTextfield(
                                        controller: _zipCodeController,
                                        label: "CEP",
                                        obscureText: false,
                                        focusNode: _zipCodeFocusNode,
                                        onSubmitted: (value) {
                                          FocusScope.of(context).unfocus();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
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
