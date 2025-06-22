import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';

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

  // Máscara para placa de veículo: AAA-0000 (formato antigo) ou AAA0A00 (formato Mercosul)
  static final plateFormatter = MaskTextInputFormatter(
    mask: 'AAA-####',
    filter: {
      "A": RegExp(r'[A-Za-z]'),
      "#": RegExp(r'[0-9]')
    },
    type: MaskAutoCompletionType.lazy,
  );

  // Máscara para placa Mercosul: AAA0A00
  static final plateFormatterMercosul = MaskTextInputFormatter(
    mask: 'AAA#A##',
    filter: {
      "A": RegExp(r'[A-Za-z]'),
      "#": RegExp(r'[0-9]')
    },
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
  // Função para determinar automaticamente o formato da placa
  static MaskTextInputFormatter getPlateFormatter(String text) {
    // Remove espaços e caracteres especiais
    String cleanText = text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    
    // Se tem mais de 4 caracteres, verifica se o 5º caractere é número (formato antigo) ou letra (Mercosul)
    if (cleanText.length >= 5) {
      String fifthChar = cleanText[4];
      if (RegExp(r'[0-9]').hasMatch(fifthChar)) {
        // Formato antigo: AAA-0000
        return plateFormatter;
      } else {
        // Formato Mercosul: AAA0A00
        return plateFormatterMercosul;
      }
    }
    
    // Por padrão, usa formato antigo
    return plateFormatter;
  }
}

// Classe personalizada para formatação automática de placa
class PlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Determina o formatador baseado no texto atual
    final formatter = InputFormatters.getPlateFormatter(newValue.text);
    
    // Aplica a formatação
    return formatter.formatEditUpdate(oldValue, newValue);
  }
}
