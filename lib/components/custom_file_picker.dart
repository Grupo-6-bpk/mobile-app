import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomFilePicker extends StatefulWidget {
  final String label;
  final ValueNotifier<String?> fileUrl;
  final ValueNotifier<FilePickerResult?> fileNotifier;

  const CustomFilePicker({
    super.key,
    required this.label,
    required this.fileUrl,
    required this.fileNotifier,
  });

  @override
  State<CustomFilePicker> createState() => _CustomFilePickerState();
}

class _CustomFilePickerState extends State<CustomFilePicker> {
  String? _fileName;
  String? _filePath;
  static final String cloudinaryCloudName =
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String cloudinaryUploadPreset =
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
        });
        final cloudinary = CloudinaryPublic(
          cloudinaryCloudName,
          cloudinaryUploadPreset,
          cache: false,
        );

        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _filePath!,
            resourceType: CloudinaryResourceType.Auto,
          ),
        );

        debugPrint('File uploaded: ${response.secureUrl}');

        widget.fileUrl.value = response.secureUrl;
        widget.fileNotifier.value = result;
      } else {
        setState(() {
          _fileName = null;
        });
        widget.fileNotifier.value = null;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
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
