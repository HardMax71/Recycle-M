import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'custom_bottom_nav_bar.dart';

class UserOptionsScreen extends StatefulWidget {
  const UserOptionsScreen({super.key});

  @override
  _UserOptionsScreenState createState() => _UserOptionsScreenState();
}

class _UserOptionsScreenState extends State<UserOptionsScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, bool> _options = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserOptions();
  }

  Future<void> _loadUserOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/users/options'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body));
        setState(() {
          _options = data
              .map<String, bool>((key, value) => MapEntry(key, value as bool));
        });
      } else {
        throw Exception('Failed to load user options');
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

  Future<void> _saveUserOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.put(
        Uri.parse('${Config.apiUrl}/api/v1/users/options'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(_options),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Return to Profile screen
      } else {
        throw Exception('Failed to save user options');
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

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/feed');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/market');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          child: const Text('Back', style: TextStyle(color: Colors.green)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('User Options',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.2,
            )),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    String key = _options.keys.elementAt(index);
                    return ListTile(
                      title: Text(key.replaceAll('_', ' ').capitalizeFirst()),
                      trailing: Switch(
                        value: _options[key]!,
                        onChanged: (bool value) {
                          setState(() {
                            _options[key] = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveUserOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Options'),
            ),
          ),
          const CustomBottomNavBar(currentIndex: 4),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (this == null) {
      return '';
    }
    if (isNotEmpty) {
      return '${this[0].toUpperCase()}${substring(1)}';
    }
    return this;
  }
}
