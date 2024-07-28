import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import '../styles.dart';
import 'custom_bottom_nav_bar.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _storage = const FlutterSecureStorage();
  final Map<String, List<dynamic>> _productsByType = {};
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<String> _productTypes = {};
  final Set<String> _selectedFilters = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData({String searchQuery = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse(
            '${Config.apiUrl}/api/v1/products?skip=0&limit=100&search=$searchQuery'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final products = json.decode(response.body);
        _productsByType.clear();
        _productTypes.clear();
        for (var product in products) {
          final type = product['product_type']['name'];
          _productTypes.add(type);
          if (!_productsByType.containsKey(type)) {
            _productsByType[type] = [];
          }
          _productsByType[type]!.add(product);
        }
        setState(() {});
      } else {
        throw Exception('Failed to load market data');
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

  String capitalizeWords(String input) {
    return input
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter by Product Type'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _productTypes.map((type) {
                    return CheckboxListTile(
                      title: Text(capitalizeWords(type.replaceAll('_', ' '))),
                      value: _selectedFilters.contains(type),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value!) {
                            _selectedFilters.add(type);
                          } else {
                            _selectedFilters.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    this.setState(() {});
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductList(String title, List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            capitalizeWords(title.replaceAll('_', ' ')),
            style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.black,
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w500),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/product',
                  arguments: {'productId': product['id']},
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: product['image_url'] != null
                          ? Image.network(
                              product['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image,
                                      size: 30, color: Colors.grey),
                            )
                          : const Icon(Icons.image, size: 30, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product['name'] ?? 'No name',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${product['price'].round()} pts',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _errorMessage = '';
      _searchQuery = query;
      _loadMarketData(searchQuery: _searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Market',
            style: AppStyles.titleStyle),
        actions: [
          TextButton(
            onPressed: _showFilterDialog,
            child: const Text('Filter', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : RefreshIndicator(
                  onRefresh: () => _loadMarketData(searchQuery: _searchQuery),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onSubmitted: _onSearchSubmitted,
                          ),
                        ),
                        ..._productsByType.entries
                            .where((entry) =>
                                _selectedFilters.isEmpty ||
                                _selectedFilters.contains(entry.key))
                            .map((entry) =>
                                _buildProductList(entry.key, entry.value))
                            .toList(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }
}
