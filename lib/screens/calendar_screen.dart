import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:anchor/models/task.dart';
import 'package:anchor/services/task_service.dart';
import 'package:anchor/widgets/task_card.dart';
import 'package:anchor/screens/add_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {


  final TaskService _taskService = TaskService.instance;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _allTasks = [];
  List<Task> _selectedDayTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    
    final tasks = await _taskService.getAllTasks();
    
    setState(() {
      _allTasks = tasks;
      _isLoading = false;
    });
    
    _updateSelectedDayTasks();
  }

  void _updateSelectedDayTasks() {
    if (_selectedDay != null) {
      _selectedDayTasks = _taskService.getTasksForDate(_allTasks, _selectedDay!);
    } else {
      _selectedDayTasks = [];
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _taskService.getTasksForDate(_allTasks, day);
  }

  

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final updatedTask = task.copyWith(status: newStatus);
    await _taskService.updateTask(updatedTask);
    _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    await _taskService.deleteTask(task.id);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.name}" deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _taskService.addTask(task);
              _loadTasks();
            },
          ),
        ),
      );
    }
  }

  void _editTask(Task task) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(task: task),
      ),
    );
    
    if (result == true) {
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          _buildCalendar(),
          _buildSelectedDayTasks(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_module),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('Month View'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2 Weeks View'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('Week View'),
              ),
            ],
            onSelected: (format) {
              setState(() => _calendarFormat = format);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<Task>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getTasksForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red[400]),
          holidayTextStyle: TextStyle(color: Colors.red[400]),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markersMaxCount: 3,
          canMarkersOverflow: false,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(Icons.chevron_left),
          rightChevronIcon: Icon(Icons.chevron_right),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _updateSelectedDayTasks();
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox();
            
            final taskCount = events.length;
            final hasOverdue = events.any((task) => task.isOverdue);
            final hasCompleted = events.any((task) => task.status == TaskStatus.done);
            
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasOverdue)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasCompleted)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (taskCount > (hasOverdue ? 1 : 0) + (hasCompleted ? 1 : 0))
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayTasks() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text(
                  _selectedDay != null
                    ? DateFormat('EEEE, MMMM dd').format(_selectedDay!)
                    : 'Select a date',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedDayTasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedDayTasks.length} tasks',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDayTasks.isEmpty
              ? _buildEmptyState()
              : _buildTasksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      itemCount: _selectedDayTasks.length,
      itemBuilder: (context, index) {
        final task = _selectedDayTasks[index];
        return TaskCard(
          task: task,
          onTap: () => _editTask(task),
          onEdit: () => _editTask(task),
          onStatusChanged: (status) => _updateTaskStatus(task, status),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDay != null && isSameDay(_selectedDay!, DateTime.now())
                ? 'No tasks for today'
                : 'No tasks for this date',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new task',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void refresh() {
    _loadTasks();
  }
}