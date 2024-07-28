import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  _CalendarTabState createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final _storage = const FlutterSecureStorage();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _monthlyTransactions = [];
  bool _isLoading = true;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadMonthlyData(_selectedDate);
  }

  Future<void> _loadMonthlyData(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse(
            '${Config.apiUrl}/api/v1/users/monthly-transactions/${date.year}/${date.month}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _monthlyTransactions = List<Map<String, dynamic>>.from(data);
          _events = _groupTransactionsByDate(_monthlyTransactions);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load monthly data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    for (var transaction in transactions) {
      DateTime date = DateTime.parse(transaction['created_at']);
      DateTime dateOnly = DateTime(
          date.year, date.month, date.day); // Group by date without time
      if (grouped[dateOnly] == null) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add(transaction);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      children: [
        _buildCalendar(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildMonthlyTransactionsList()),
      ],
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _selectedDate,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDate, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          // Update the calendar format
        });
      },
      eventLoader: (day) {
        DateTime dateOnly = DateTime(day.year, day.month, day.day);
        return _events[dateOnly] ?? [];
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        markerDecoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return const SizedBox();
          final hasRewards = (events).any((event) => (event as Map)['type'] == 'reward');
          final hasExpenses = (events).any((event) => (event as Map)['type'] == 'expense');
          if (hasRewards && hasExpenses) {
            return Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              width: 16,
              height: 16,
              child: CustomPaint(
                painter: _HalfAndHalfCirclePainter(),
              ),
            );
          } else if (hasRewards) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              width: 16,
              height: 16,
            );
          } else if (hasExpenses) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              width: 16,
              height: 16,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }


  Widget _buildMonthlyTransactionsList() {
    final transactionsForSelectedDay = _events[DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day)] ??
        [];
    return ListView.builder(
      itemCount: transactionsForSelectedDay.length,
      itemBuilder: (context, index) {
        final transaction = transactionsForSelectedDay[index];
        final isReward = transaction['type'] == 'reward';
        return ListTile(
          leading: Icon(
            isReward ? Icons.add_circle : Icons.remove_circle,
            color: isReward ? Colors.green : Colors.red,
          ),
          title: Text(transaction['description']),
          subtitle: Text(DateFormat('MMM d, yyyy')
              .format(DateTime.parse(transaction['created_at']))),
          trailing: Text(
            '${isReward ? '+' : '-'}${transaction['points']} pts',
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

class _HalfAndHalfCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw the red upper half
    paint.color = Colors.red;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -3.14 / 2, // Starting from the top center
      3.14, // Sweep angle to cover the upper half
      true,
      paint,
    );

    // Draw the green lower half
    paint.color = Colors.green;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.14 / 2, // Starting from the bottom center
      3.14, // Sweep angle to cover the lower half
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
