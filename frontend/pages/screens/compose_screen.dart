import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class ComposeScreen extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final int? postId; // If null, creating a new post
  final String postType;

  const ComposeScreen({super.key, 
    this.initialTitle = '',
    this.initialContent = '',
    this.postId,
    this.postType = 'article',
  });

  @override
  _ComposeScreenState createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _storage = const FlutterSecureStorage();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late String _postType;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _contentController.text = widget.initialContent;
    _postType = widget.postType;
  }

  Future<void> _sendPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final url = Uri.parse('${Config.apiUrl}/api/v1/feed${widget.postId != null ? '/${widget.postId}' : ''}');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final body = json.encode({
        'title': _titleController.text,
        'content': _contentController.text,
        'type': _postType,
      });

      final response = widget.postId != null
          ? await http.put(url, headers: headers, body: body)
          : await http.post(url, headers: headers, body: body);

      if (response.statusCode == (widget.postId != null ? 200 : 201)) {
        // Post created/updated successfully
        Navigator.pop(context); // Return to previous screen
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = 'Error: ${responseData['detail'] ?? 'Failed to create/update post'}';
        });
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.postId != null ? 'Edit Post' : 'Compose', style: const TextStyle(color: Colors.black)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Compose your message here...',
                border: OutlineInputBorder(),
              ),
            ),
            DropdownButton<String>(
              value: _postType,
              onChanged: (String? newValue) {
                setState(() {
                  _postType = newValue!;
                });
              },
              items: <String>['article', 'blog_post']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.postId != null ? 'Update' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
