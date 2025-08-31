import 'package:flutter/material.dart';
import 'package:anchor/theme.dart';
import 'package:anchor/services/task_service.dart';
import 'package:anchor/screens/dashboard_screen.dart';
import 'package:anchor/screens/all_tasks_screen.dart';
import 'package:anchor/screens/calendar_screen.dart';
import 'package:anchor/screens/add_task_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sample data
  await TaskService.instance.initializeSampleData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();
  final GlobalKey<AllTasksScreenState> _allTasksKey =
      GlobalKey<AllTasksScreenState>();
  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey),
      AllTasksScreen(key: _allTasksKey),
      CalendarScreen(key: _calendarKey),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _addNewTask() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );

    if (result == true) {
      // Refresh all screens
      _dashboardKey.currentState?.refresh();
      _allTasksKey.currentState?.refresh();
      _calendarKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'All Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
