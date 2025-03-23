import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CustomFilePicker extends StatefulWidget {
  final String label;
  const CustomFilePicker({super.key, required this.label});

  @override
  State<CustomFilePicker> createState() => _CustomFilePickerState();
}

class _CustomFilePickerState extends State<CustomFilePicker> {
  String? _fileName;
  FilePickerResult? _file;

  Future<void> _pickFile() async {
    try {
      _file = await FilePicker.platform.pickFiles();

      if (_file != null) {
        setState(() {
          _fileName = _file?.files.single.name;
        });
      } else {
        setState(() {
          _fileName = null;
        });
      }
    } catch (e) {
      setState(() {
        _fileName = "Erro ao selecionar arquivo";
      });
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
