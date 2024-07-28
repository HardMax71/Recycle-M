import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  _ExpensesTabState createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpensesData();
  }

  Future<void> _loadExpensesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final weeklyResponse = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/users/weekly-data'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final transactionsResponse = await http.get(
        Uri.parse('${Config.apiUrl}/api/v1/users/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (weeklyResponse.statusCode == 200 &&
          transactionsResponse.statusCode == 200) {
        final weeklyData = json.decode(weeklyResponse.body);
        final transactionsData = json.decode(transactionsResponse.body);

        setState(() {
          _weeklyData = List<Map<String, dynamic>>.from(weeklyData);
          _recentTransactions = [
            ...List<Map<String, dynamic>>.from(transactionsData['rewards']),
            ...List<Map<String, dynamic>>.from(transactionsData['expenses']),
          ];
          _recentTransactions.sort((a, b) => DateTime.parse(b['created_at'])
              .compareTo(DateTime.parse(a['created_at'])));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load expenses data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
      children: [
        const SizedBox(height: 20),
        _buildWeeklyChart(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recent Transactions',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 10),
        _buildRecentTransactionsList(),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1), // Lightened the grey boundary
        borderRadius: BorderRadius.circular(10),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _weeklyData
              .map((d) => d['rewards'] + d['expenses'])
              .reduce((a, b) => a > b ? a : b)
              .toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: SideTitles(
              showTitles: true,
              getTextStyles: (context, value) => const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400, // Made the titles less bold
                  fontSize: 14),
              margin: 16,
              rotateAngle: -45,
              getTitles: (double value) {
                switch (value.toInt()) {
                  case 0:
                    return 'Mon';
                  case 1:
                    return 'Tue';
                  case 2:
                    return 'Wed';
                  case 3:
                    return 'Thu';
                  case 4:
                    return 'Fri';
                  case 5:
                    return 'Sat';
                  case 6:
                    return 'Sun';
                  default:
                    return '';
                }
              },
            ),
            leftTitles: SideTitles(showTitles: false),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _weeklyData.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  y: data['rewards'].toDouble(),
                  colors: [Colors.green],
                  width: 16,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    y: _weeklyData
                        .map((d) => d['rewards'] + d['expenses'])
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble(),
                    colors: [Colors.grey.shade200],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        final isReward = transaction.containsKey('waste_type');
        final description =
        isReward ? transaction['waste_type'] : transaction['description'];
        final createdAt = DateFormat('MMM d, yyyy')
            .format(DateTime.parse(transaction['created_at']));
        final points = transaction['points'];

        return ListTile(
          leading: Icon(
            isReward ? Icons.add_circle : Icons.remove_circle,
            color: isReward ? Colors.green : Colors.red,
          ),
          title: Text(description),
          subtitle: Text(createdAt),
          trailing: Text(
            '${isReward ? '+' : '-'}$points pts',
            style: TextStyle(
              color: isReward ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
