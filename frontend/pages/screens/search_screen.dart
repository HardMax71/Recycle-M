import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'custom_bottom_nav_bar.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse(
            '${Config.apiUrl}/api/v1/search?query=$query&skip=0&limit=20'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to perform search');
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

  // In SearchScreen
  Widget _buildSearchResultItem(dynamic result) {
    // List of icons to choose from
    final List<IconData> iconOptions = [
      Icons.article,
      Icons.post_add,
      Icons.book,
      Icons.video_library,
      Icons.photo,
      Icons.music_note,
      Icons.event,
      Icons.description,
    ];

    final List<Color> appColors = [
      Color(0xFF4CAF50), // Green (Primary)
      Color(0xFFF44336), // Red (Complementary to Green)
      Color(0xFF2196F3), // Blue
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF795548), // Brown
      Color(0xFF607D8B), // Blue Grey
    ];

    Color getColorForType(String type) {
      int hash = type.toLowerCase().codeUnits.reduce((a, b) => a + b);
      return appColors[hash % appColors.length];
    }

    // Function to get an icon based on the content type
    IconData getIconForType(String type) {
      if (type.toLowerCase() == 'product') {
        return Icons.shopping_bag;
      } else {
        int hash = type.toLowerCase().codeUnits.reduce((a, b) => a + b);
        return iconOptions[hash % iconOptions.length];
      }
    }

    final String contentType = (result['type'] as String?) ?? 'Article';
    final Color backgroundColor = getColorForType(contentType);
    final IconData iconData = getIconForType(contentType);

    return Card(
      color: backgroundColor,
      child: ListTile(
        leading: Icon(iconData),
        title: Text(result['title'] ?? 'No title'),
        subtitle: Text(
          result['description'] ?? 'No description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          // result is SearchResult / dict with 4 keys: id, type, title, description
          if (result != null && result['id'] != null) {
            if (result['type'] == 'product') {
              Navigator.pushNamed(
                context,
                '/product',
                arguments: {'productId': result['id']},
              );
            } else {
              Navigator.pushNamed(
                context,
                '/content_detail',
                arguments: {
                  'id': result['id'],
                  'contentType': contentType,
                },
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open this item')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Search',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.2,
            )),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onSubmitted: (value) => _performSearch(value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return _buildSearchResultItem(_searchResults[index]);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
