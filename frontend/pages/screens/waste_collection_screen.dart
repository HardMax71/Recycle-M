import 'dart:convert';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import 'custom_bottom_nav_bar.dart';

class WasteCollectionScreen extends StatefulWidget {
  const WasteCollectionScreen({super.key});

  @override
  _WasteCollectionScreenState createState() => _WasteCollectionScreenState();
}

class _WasteCollectionScreenState extends State<WasteCollectionScreen> {
  final _storage = const FlutterSecureStorage();
  int _currentStep = 0;
  String _wasteType = '';
  List<String> _wasteTypes = [];
  List<Map<String, dynamic>> _recyclingCenters = [];
  Map<String, dynamic>? _selectedCenter;
  int _reward = 0;

  @override
  void initState() {
    super.initState();
    _loadWasteTypes();
  }

  Future<void> _loadWasteTypes() async {
    final token = await _storage.read(key: 'access_token');
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/api/v1/waste-collection/waste-types'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _wasteTypes = List<String>.from(json.decode(response.body));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load waste types')),
      );
    }
  }

  Future<void> _detectWasteType() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final token = await _storage.read(key: 'access_token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiUrl}/api/v1/waste-collection/detect-waste'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'waste_image.jpg'));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          _wasteType = json.decode(responseBody);
          _currentStep = 2; // Move to Location step
        });
        await _getNearbyRecyclingCenters();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to detect waste type')),
        );
      }
    }
  }

  Future<void> _getNearbyRecyclingCenters() async {
    final position = await Geolocator.getCurrentPosition();
    final token = await _storage.read(key: 'access_token');

    final response = await http.get(
      Uri.parse(
          '${Config.apiUrl}/api/v1/waste-collection/recycling-centers?latitude=${position.latitude}&longitude=${position.longitude}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> centersData = json.decode(response.body);
      setState(() {
        _recyclingCenters =
            centersData.map((center) => center as Map<String, dynamic>)
                .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get nearby recycling centers')),
      );
    }
  }

  Future<void> _confirmCollection() async {
    final token = await _storage.read(key: 'access_token');
    final position = await Geolocator.getCurrentPosition();

    final response = await http.post(
      Uri.parse('${Config.apiUrl}/api/v1/waste-collection'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'waste_type': _wasteType,
        'quantity': 1,
        'collection_date': DateTime.now().toIso8601String(),
        'location_latitude': position.latitude,
        'location_longitude': position.longitude,
      }),
    );

    if (response.statusCode == 201) {
      final rewardResponse = await http.get(
        Uri.parse(
            '${Config.apiUrl}/api/v1/waste-collection/reward?waste_type=$_wasteType'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (rewardResponse.statusCode == 200) {
        setState(() {
          _reward = json.decode(rewardResponse.body)['reward'];
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Waste collection confirmed! You earned $_reward points.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm waste collection')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Find Nearest Place'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _buildStepContent(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStepIndicator() {
    return EasyStepper(
      activeStep: _currentStep,
      lineStyle: LineStyle(
        defaultLineColor: Colors.grey,
        lineType: LineType.normal,
        lineSpace: 0,
        finishedLineColor: Colors.green,
        lineLength: 50,
      ),
      activeStepTextColor: Colors.green,
      finishedStepTextColor: Colors.green,
      internalPadding: 0,
      showLoadingAnimation: false,
      stepRadius: 15,
      showStepBorder: false,
      steps: [
        EasyStep(
          customStep: _buildStep(0, '1'),
          title: 'Type of\nWaste',
        ),
        EasyStep(
          customStep: _buildStep(1, '2'),
          title: 'Detect\nWaste',
        ),
        EasyStep(
          customStep: _buildStep(2, '3'),
          title: 'Location',
        ),
        EasyStep(
          customStep: _buildStep(3, '4'),
          title: 'Delivery',
        ),
        EasyStep(
          customStep: _buildStep(4, '5'),
          title: 'Reward',
        ),
      ],
      onStepReached: (index) => setState(() => _currentStep = index),
    );
  }

  Widget _buildStep(int step, String label) {
    bool isActive = _currentStep == step;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.green : Colors.grey,
      ),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWasteTypeStep();
      case 1:
        return _buildDetectWasteStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildDeliveryStep();
      case 4:
        return _buildRewardStep();
      default:
        return Container();
    }
  }

  Widget _buildWasteTypeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            _detectWasteType();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('Detect Waste'),
        ),
        const SizedBox(height: 20),
        const Text('Or select waste type:'),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _wasteTypes.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _wasteType = _wasteTypes[index];
                    _currentStep = 2;
                  });
                  _getNearbyRecyclingCenters();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getIconForWasteType(_wasteTypes[index]),
                          size: 40, color: Colors.green),
                      const SizedBox(height: 8),
                      Text(
                        _wasteTypes[index],
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForWasteType(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'plastic':
        return Icons.local_drink;
      case 'paper':
        return Icons.description;
      case 'glass':
        return Icons.wine_bar;
      case 'metal':
        return Icons.build;
      case 'electronic':
        return Icons.computer;
      default:
        return Icons.delete;
    }
  }

  Widget _buildDetectWasteStep() {
    return Center(
      child: Text('Waste Type: $_wasteType'),
    );
  }

  Widget _buildLocationStep() {
    if (_recyclingCenters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recycling centers found nearby.',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getNearbyRecyclingCenters,
              child: Text('Refresh'),
              style: ElevatedButton.styleFrom(primary: Colors.green),
            ),
          ],
        ),
      );
    }
    return _buildRecyclingCentersList();
  }

  Widget _buildDeliveryStep() {
    if (_selectedCenter == null) {
      return Center(child: Text('No center selected. Please go back and select a center.'));
    }
    return Column(
      children: [
        Expanded(
          child: _buildMap(),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected Center:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_selectedCenter!['name']),
              Text(_selectedCenter!['address']),
              Text('Distance: ${_selectedCenter!['distance'].toStringAsFixed(2)} km'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep++;
                  });
                },
                child: Text('Proceed to Reward'),
                style: ElevatedButton.styleFrom(primary: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return _selectedCenter != null
        ? GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_selectedCenter!['latitude'], _selectedCenter!['longitude']),
        zoom: 14,
      ),
      markers: {
        Marker(
          markerId: MarkerId('selected_center'),
          position: LatLng(_selectedCenter!['latitude'], _selectedCenter!['longitude']),
          infoWindow: InfoWindow(title: _selectedCenter!['name']),
        ),
      },
    )
        : Center(child: Text('Loading map...'));
  }

  Widget _buildRewardStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Reward: $_reward points'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _confirmCollection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildRecyclingCentersList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Select place to go:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recyclingCenters.length,
            itemBuilder: (context, index) {
              final center = _recyclingCenters[index];
              final distance = center['distance'];
              final distanceText = distance < 1
                  ? '${(distance * 1000).toInt()} meters'
                  : '${distance.toStringAsFixed(1)} km';
              final distanceUnit = distance < 1 ? 'meters' : 'km';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(center['name']),
                  subtitle: Text(center['address']),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          distance < 1 ? '${(distance * 1000).toInt()}' : '${distance.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          distanceUnit,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCenter = center;
                      _currentStep++;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

