import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

import 'custom_bottom_nav_bar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _feedItems = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final queryParams = {
        'skip': '0',
        'limit': '20',
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
      };
      final uri = Uri.parse('${Config.apiUrl}/api/v1/feed')
          .replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            _feedItems = decodedData;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load feed');
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

  void _navigateToSearch() {
    Navigator.pushNamed(
      context,
      '/search',
      arguments: {'initialQuery': _searchController.text},
    );
  }

  void _navigateToItem(dynamic item) {
    if (item != null && item['id'] != null) {
      Navigator.pushNamed(
        context,
        '/content_detail',
        arguments: {
          'id': item['id'],
          'contentType': item['post_type']['name'] ?? 'Article',
        },
      );
    } else {
      // Handle the case where the item or its id is null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Feed',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.2,
            )),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
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
              onSubmitted: (_) => _navigateToSearch(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        child: ListView.separated(
                          itemCount: _feedItems.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(left: 92),
                            child: Divider(height: 1, color: Colors.grey[300]),
                          ),
                          itemBuilder: (context, index) {
                            final item = _feedItems[index];
                            return InkWell(
                              onTap: () => _navigateToItem(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: item['images'] != null &&
                                          item['images'].isNotEmpty &&
                                          item['images'][0]['url'] != null
                                          ? Image.network(
                                        item['images'][0]['url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          // If there's an error loading the image, show the article icon
                                          return Icon(Icons.article, size: 30, color: Colors.grey[600]);
                                        },
                                      )
                                          : Icon(Icons.article, size: 30, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['title'] ?? 'No Title',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                item['created_at'] != null
                                                    ? _getTimeAgo(DateTime.parse(item['created_at']))
                                                    : 'Unknown date',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['content'] ?? 'No content',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800]),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'By ${item['author']?['full_name'] ?? 'Unknown Author'}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
