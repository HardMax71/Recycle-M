import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart'; // Import this

class UploadPhotoScreen extends StatefulWidget {
  const UploadPhotoScreen({super.key});

  @override
  _UploadPhotoScreenState createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String _errorMessage = '';
  File? _image;
  String? _webImage;

  Future<void> _uploadPhoto() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiUrl}/api/v1/users/me/photos'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      if (kIsWeb) {
        final bytes = base64.decode(_webImage!.split(',').last);
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'upload.png',
          contentType: MediaType('image', 'png'),
        ));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('file', _image!.path));
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        Navigator.pop(context); // Return to previous screen
      } else {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final imageUrl = 'data:image/png;base64,${base64Encode(bytes)}';
        setState(() {
          _webImage = imageUrl;
        });
      } else {
        print('No image selected.');
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upload Photo', style: TextStyle(color: Colors.black)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null && !kIsWeb)
              Image.file(
                _image!,
                height: 200,
              ),
            if (_webImage != null && kIsWeb)
              Image.network(
                _webImage!,
                height: 200,
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: (_isLoading || (_image == null && _webImage == null))
                  ? null
                  : _uploadPhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
