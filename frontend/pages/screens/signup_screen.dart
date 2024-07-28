import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:recycle_m_mobile/styles.dart';
import '../config.dart';
import 'error_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _newsletterSubscription = false;
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/api/v1/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'full_name': _nameController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Signup successful, now login
        await _login();
      } else {
        final errorData = json.decode(response.body);
        _showErrorScreen(errorData, StackTrace.current);
      }
    } catch (e, stackTrace) {
      _showErrorScreen({'detail': e.toString()}, stackTrace);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorScreen(dynamic errorData, [StackTrace? stackTrace]) {
    if (stackTrace != null && errorData is Map<String, dynamic>) {
      errorData['stack_trace'] = stackTrace.toString();
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ErrorScreen(
        title: 'Error',
        errorData: errorData,
      ),
    ));
  }


  Future<void> _login() async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/api/v1/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': _emailController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final accessToken = responseData['access_token'];
        await _storage.write(key: 'access_token', value: accessToken);

        // Fetch user information
        await _fetchUserInfo(accessToken);

        Navigator.pushReplacementNamed(context, '/feed');
      } else {
        final errorData = json.decode(response.body);
        _showErrorScreen(errorData, StackTrace.current);
      }
    } catch (e, stackTrace) {
      _showErrorScreen({'detail': e.toString()}, stackTrace);
    }
  }

  Future<void> _fetchUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/users/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        await _storage.write(key: 'user_data', value: json.encode(userData));
      } else {
        throw Exception('Failed to fetch user data');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // We'll continue even if this fails, as the signup was successful
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Sign Up', style: AppStyles.titleStyle),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            child: const Text('Login', style: TextStyle(color: Colors.green)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Name',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _newsletterSubscription,
                    onChanged: (value) {
                      setState(() {
                        _newsletterSubscription = value ?? false;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I would like to receive your newsletter and other promotional information.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign Up'),
            ),
            const SizedBox(height: 16),
            TextButton(
              child: const Text('Forgot your password?', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.pushNamed(context, '/forgot_password');
              },
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
