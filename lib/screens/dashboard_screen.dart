import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:anchor/models/task.dart';
import 'package:anchor/services/task_service.dart';
import 'package:anchor/widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {


  final TaskService _taskService = TaskService.instance;
  
  List<Task> _todaysTasks = [];
  List<Task> _overdueTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    
    final allTasks = await _taskService.getAllTasks();
    final todaysTasks = _taskService.getTodaysTasks(allTasks);
    final overdueTasks = _taskService.getOverdueTasks(allTasks);

    setState(() {
      
      _todaysTasks = todaysTasks;
      _overdueTasks = overdueTasks;
      _isLoading = false;
    });
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

  void refresh() {
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).appBarTheme.foregroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM dd').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),
            if (_overdueTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  'Overdue Tasks',
                  _overdueTasks.length,
                  Colors.red,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => TaskCard(
                    task: _overdueTasks[index],
                    onStatusChanged: (status) => _updateTaskStatus(_overdueTasks[index], status),
                    onDelete: () => _deleteTask(_overdueTasks[index]),
                  ),
                  childCount: _overdueTasks.length,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                "Today's Tasks",
                _todaysTasks.length,
                Theme.of(context).primaryColor,
              ),
            ),
            if (_todaysTasks.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(
                  context,
                  'No tasks for today',
                  'You\'re all caught up! Add a new task or relax.',
                  Icons.check_circle_outline,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => TaskCard(
                    task: _todaysTasks[index],
                    onStatusChanged: (status) => _updateTaskStatus(_todaysTasks[index], status),
                    onDelete: () => _deleteTask(_todaysTasks[index]),
                  ),
                  childCount: _todaysTasks.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Space for FAB
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}