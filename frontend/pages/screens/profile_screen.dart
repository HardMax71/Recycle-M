import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import 'custom_bottom_nav_bar.dart';
import 'expenses_calendar_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic> _userData = {};
  List<dynamic> _userPosts = [];
  List<dynamic> _userPhotos = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _balance = 0;
  List<Map<String, dynamic>> _rewards = [];
  List<Map<String, dynamic>> _expenses = [];
  bool _isBalanceLoading = true;

  final TextEditingController _bioController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadBalanceAndRewards();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');

      final userResponse = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (userResponse.statusCode == 200) {
        _userData = json.decode(userResponse.body);

        final postsResponse = await http.get(
          Uri.parse(
              '${Config.apiUrl}/api/v1/feed/user/${_userData['id']}?skip=0&limit=10'),
          headers: {'Authorization': 'Bearer $token'},
        );

        final photosResponse = await http.get(
          Uri.parse('${Config.apiUrl}/api/v1/users/me/photos?skip=0&limit=9'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (postsResponse.statusCode == 200 &&
            photosResponse.statusCode == 200) {
          setState(() {
            _userPosts = json.decode(postsResponse.body);
            _userPhotos = json.decode(photosResponse.body);
          });
        } else {
          throw Exception('Failed to load user posts or photos');
        }
      } else {
        throw Exception('Failed to load user data');
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

  Future<void> _loadBalanceAndRewards() async {
    setState(() {
      _isBalanceLoading = true;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/users/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _balance = data['balance'] ?? 0;
          _rewards = List<Map<String, dynamic>>.from(data['rewards'] ?? []);
          _expenses = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
          _isBalanceLoading = false;
        });
      } else {
        throw Exception('Failed to load balance and transactions');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isBalanceLoading = false;
        _rewards = [];
        _expenses = [];
      });
    }
  }

  Future<void> _updateBio() async {
    setState(() => _isUpdating = true);

    try {
      final token = await _storage.read(key: 'access_token');
      final new_bio = _bioController.text;
      final response = await http.patch(
        Uri.parse('${Config.apiUrl}/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'bio': new_bio}),
      );

      if (response.statusCode == 200) {
        final updatedUser = json.decode(response.body);
        setState(() {
          _userData = updatedUser;
        });
      } else {
        throw Exception('Failed to update bio');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bio: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUpdating = true);

      try {
        final token = await _storage.read(key: 'access_token');
        var request = http.MultipartRequest(
          'PATCH',
          Uri.parse('${Config.apiUrl}/api/v1/users/me/profile-photo'),
        );

        request.headers['Authorization'] = 'Bearer $token';

        if (kIsWeb) {
          List<int> imageBytes = await image.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'profile_photo',
            imageBytes,
            filename: image.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('profile_photo', image.path));
        }

        var response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final updatedUser = json.decode(responseData);
          setState(() {
            _userData = updatedUser;
          });
        } else {
          throw Exception('Failed to update profile photo');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile photo: $e')),
        );
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }


  void _showEditProfileDialog() {
    _bioController.text = _userData['bio'] ?? 'No bio :(';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _updateProfilePhoto();
                  },
                  child: const Text('Change Profile Photo',
                      style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child:
                          const Text('Cancel', style: TextStyle(fontSize: 18)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _updateBio();
                      },
                      child:
                          const Text('Apply', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    _buildProfileHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostsList(),
                          _buildPhotosList(),
                          _buildBalanceOverview(),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF4CAF50),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text('Settings',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/user_options'),
                    ),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        await _storage.delete(key: 'access_token');
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 40,
              color: Colors.white,
            ),
            Positioned(
              top: -100,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[300],
                          child: _userData['profile_image'] != null
                              ? ClipOval(
                                  child: Image.network(
                                    _userData['profile_image'],
                                    fit: BoxFit.cover,
                                    width: 150,
                                    height: 150,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.grey[600],
                                  size: 75,
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showEditProfileDialog,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32), // Darker green
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                _userData['full_name'] ?? 'Victoria Robertson',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _userData['bio'] ?? 'A mantra goes here',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200], // Light grey background
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4CAF50),
        // Green color for selected tab text
        unselectedLabelColor: Colors.grey[600],
        // Darker grey for unselected tab text
        indicator: BoxDecoration(
          color: Colors.white, // White background for the selected tab
          borderRadius:
              BorderRadius.circular(30.0), // Rounded corners for the indicator
        ),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Photos'),
          Tab(text: 'Balance'),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return ListView.builder(
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            '/content_detail',
            arguments: {
              'id': post['id'],
              'contentType': post['post_type']['name'] ?? 'Article',
            },
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post['title'] ?? 'No Title',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeAgo(post['created_at']),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['content'] ?? 'No content',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(String dateString) {
    final now = DateTime.now();
    final date = DateTime.parse(dateString);
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildPhotosList() {
    if (_userPhotos.isEmpty) {
      return const Center(child: Text('No photos uploaded yet'));
    }

    return Container(
      color: const Color(0xFF47A34B),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemHeight = width * 0.3;
          return ListView.builder(
            itemCount: (_userPhotos.length / 3).ceil(),
            itemBuilder: (context, groupIndex) {
              final startIndex = groupIndex * 3;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _ImageTile(width * 0.3 - 5, itemHeight, startIndex),
                        const SizedBox(width: 10),
                        if (startIndex + 1 < _userPhotos.length)
                          _ImageTile(
                              width * 0.7 - 5, itemHeight, startIndex + 1)
                        else
                          _ImageTile(
                              width * 0.7 - 5, itemHeight, startIndex + 1,
                              isPlaceholder: true),
                      ],
                    ),
                    if (startIndex + 2 < _userPhotos.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child:
                            _ImageTile(width - 10, itemHeight, startIndex + 2),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _ImageTile(double width, double height, int index,
      {bool isPlaceholder = false}) {
    if (index >= _userPhotos.length && !isPlaceholder) {
      return SizedBox(width: width, height: height);
    }
    return GestureDetector(
      onTap: isPlaceholder
          ? null
          : () => _showFullSizeImage(_userPhotos[index]['url']),
      child: Hero(
        tag: 'photo_$index',
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isPlaceholder
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    _userPhotos[index]['url'],
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
    );
  }

  void _showFullSizeImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: Hero(
                tag: imageUrl,
                child: Image.network(imageUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '${NumberFormat("#,##0").format(_balance)} pts',
            style: const TextStyle(fontSize: 36, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExpensesCalendarScreen()),
              );
            },
            child: const Text('View Expenses and Calendar',
                style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
