import 'package:flutter/material.dart';
import 'expenses_tab.dart';
import 'calendar_tab.dart';

class ExpensesCalendarScreen extends StatefulWidget {
  const ExpensesCalendarScreen({super.key});

  @override
  _ExpensesCalendarScreenState createState() => _ExpensesCalendarScreenState();
}

class _ExpensesCalendarScreenState extends State<ExpensesCalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Expenses & Calendar'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ExpensesTab(),
          CalendarTab(),
        ],
      ),
    );
  }
}
