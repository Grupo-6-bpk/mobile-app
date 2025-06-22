import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class InputFormatters {
  // Máscara para CPF: 000.000.000-00
  static final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Máscara para CEP: 00000-000
  static final cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Máscara para telefone: (00) 00000-0000
  static final phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Máscara alternativa para telefone fixo: (00) 0000-0000
  static final landlineFormatter = MaskTextInputFormatter(
    mask: '(##) ####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Função para determinar automaticamente o formato do telefone
  static MaskTextInputFormatter getPhoneFormatter(String text) {
    // Remove todos os caracteres não numéricos
    String numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Se tem 11 dígitos, usa formato celular, senão usa formato fixo
    if (numbers.length <= 10) {
      return landlineFormatter;
    } else {
      return phoneFormatter;
    }
  }
}
