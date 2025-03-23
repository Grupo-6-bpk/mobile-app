import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CustomFilePicker extends StatefulWidget {
  final String label;
  final ValueNotifier<FilePickerResult?> fileNotifier;

  const CustomFilePicker({
    super.key,
    required this.label,
    required this.fileNotifier,
  });

  @override
  State<CustomFilePicker> createState() => _CustomFilePickerState();
}

class _CustomFilePickerState extends State<CustomFilePicker> {
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
        });
        widget.fileNotifier.value = result;
      } else {
        setState(() {
          _fileName = null;
        });
        widget.fileNotifier.value = null;
      }
    } catch (e) {
      setState(() {
        _fileName = "Erro ao selecionar arquivo";
      });
      widget.fileNotifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ElevatedButton(
        onPressed: () async {
          await _pickFile();
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40),
            Text(
              widget.label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_fileName != null) Text(_fileName!),
          ],
        ),
      ),
    );
  }
}
