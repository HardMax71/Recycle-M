import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'package:intl/intl.dart';

class ProductScreen extends StatefulWidget {
  final int productId;

  const ProductScreen({super.key, required this.productId});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic> _productData = {};
  bool _isLoading = true;
  String _errorMessage = '';
  int _userBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadProductData();
    _loadUserBalance();
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/products/${widget.productId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _productData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load product data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading product data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserBalance() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/users/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userBalance = data['balance'] ?? 0;
        });
      } else {
        throw Exception('Failed to load user balance');
      }
    } catch (e) {
      print('Error loading user balance: $e');
    }
  }

  Future<void> _buyProduct() async {
    final int productPrice = (_productData['price'] ?? 0).round();
    final int projectedBalance = _userBalance - productPrice;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Purchase',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Current Balance:', '$_userBalance pts'),
                const SizedBox(height: 8),
                _buildInfoRow('Product Price:', '$productPrice pts'),
                const SizedBox(height: 8),
                _buildInfoRow('Projected Balance:', '$projectedBalance pts',
                    isHighlighted: true,
                    color: projectedBalance >= 0 ? Colors.green : Colors.red),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: projectedBalance >= 0 ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: projectedBalance >= 0
                    ? () => _confirmPurchase(productPrice)
                    : null,
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPurchase(int productPrice) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/api/v1/expenses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'description': 'Purchase: ${_productData['name']}',
          'points': productPrice,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Purchase successful. Please wait till our manager contacts you.')),
        );
        Navigator.of(context).pop(); // Close the dialog
        _loadUserBalance(); // Reload user balance
      } else {
        throw Exception('Failed to complete purchase, response code != 201');
      }
    } catch (e) {
      print('Error completing purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete purchase')),
      );
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Product Details',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 24,
              height: 1.2,
            )),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _buildProductDetails(),
    );
  }

  Widget _buildProductDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProductImage(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _productData['name'] ?? 'Unknown Product',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${NumberFormat('#,##0').format(_productData['price'] ?? 0)} pts',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _productData['description'] ??
                            'No description available',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _buyProduct,
                  child: const Text('Buy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: _productData['image_url'] != null &&
              _productData['image_url'].isNotEmpty
          ? Image.network(
              _productData['image_url'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackProductIcon();
              },
            )
          : _buildFallbackProductIcon(),
    );
  }

  Widget _buildFallbackProductIcon() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.shopping_bag,
        size: 100,
        color: Colors.grey[400],
      ),
    );
  }
}
