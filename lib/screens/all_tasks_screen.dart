import 'package:flutter/material.dart';
import 'package:anchor/models/task.dart';
import 'package:anchor/services/task_service.dart';
import 'package:anchor/widgets/task_card.dart';
import 'package:anchor/screens/add_task_screen.dart';

enum SortOption { dueDateAsc, dueDateDesc, nameAsc, nameDesc, priorityHigh }

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => AllTasksScreenState();
}

class AllTasksScreenState extends State<AllTasksScreen> {


  final TaskService _taskService = TaskService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  List<String> _categories = [];
  bool _isLoading = true;
  bool _hideCompleted = false;

  // Filter options
  String? _selectedCategory;
  TaskPriority? _selectedPriority;
  TaskStatus? _selectedStatus;
  SortOption _sortOption = SortOption.dueDateAsc;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final tasks = await _taskService.getAllTasks();
    final categories = await _taskService.getCategories();
    
    setState(() {
      _allTasks = tasks;
      _categories = categories;
      _isLoading = false;
    });
    
    _applyFilters();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    List<Task> filtered = List.from(_allTasks);
    
    // Apply search filter
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((task) =>
        task.name.toLowerCase().contains(searchTerm) ||
        task.description.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((task) => task.category == _selectedCategory).toList();
    }
    
    // Apply priority filter
    if (_selectedPriority != null) {
      filtered = filtered.where((task) => task.priority == _selectedPriority).toList();
    }
    
    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((task) => task.status == _selectedStatus).toList();
    }
    
    // Hide completed tasks if enabled
    if (_hideCompleted) {
      filtered = filtered.where((task) => task.status != TaskStatus.done).toList();
    }
    
    // Apply sorting
    switch (_sortOption) {
      case SortOption.dueDateAsc:
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case SortOption.dueDateDesc:
        filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.priorityHigh:
        filtered.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
    }
    
    setState(() => _filteredTasks = filtered);
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final updatedTask = task.copyWith(status: newStatus);
    await _taskService.updateTask(updatedTask);
    _loadData();
  }

  Future<void> _deleteTask(Task task) async {
    await _taskService.deleteTask(task.id);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.name}" deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _taskService.addTask(task);
              _loadData();
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
      _loadData();
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
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(
            child: _filteredTasks.isEmpty
              ? _buildEmptyState()
              : _buildTasksList(),
          ),
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
                'All Tasks',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_filteredTasks.length} of ${_allTasks.length} tasks',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'hide_completed',
                child: Row(
                  children: [
                    Icon(_hideCompleted ? Icons.visibility_off : Icons.visibility),
                    const SizedBox(width: 8),
                    Text(_hideCompleted ? 'Show Completed' : 'Hide Completed'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_completed',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Delete All Completed (${_allTasks.where((task) => task.status == TaskStatus.done).length})'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'hide_completed':
                  setState(() => _hideCompleted = !_hideCompleted);
                  _applyFilters();
                  break;
                case 'delete_completed':
                  _showDeleteCompletedDialog();
                  break;
                case 'clear_filters':
                  _clearFilters();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            'Category',
            _selectedCategory ?? 'All',
            () => _showCategoryFilter(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Priority',
            _selectedPriority != null 
              ? _getPriorityLabel(_selectedPriority!)
              : 'All',
            () => _showPriorityFilter(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Status',
            _selectedStatus != null 
              ? _getStatusLabel(_selectedStatus!)
              : 'All',
            () => _showStatusFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    final isActive = value != 'All';
    
    return ActionChip(
      label: Text('$label: $value'),
      onPressed: onTap,
      backgroundColor: isActive 
        ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
        : null,
      side: BorderSide(
        color: isActive 
          ? Theme.of(context).primaryColor
          : Colors.grey,
      ),
    );
  }

  Widget _buildTasksList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          return TaskCard(
            task: task,
            onTap: () => _editTask(task),
            onEdit: () => _editTask(task),
            onStatusChanged: (status) => _updateTaskStatus(task, status),
            onDelete: () => _deleteTask(task),
          );
        },
      ),
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
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
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

  void _showSortOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Sort by',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...SortOption.values.map(
          (option) => RadioListTile<SortOption>(
            title: Text(_getSortOptionLabel(option)),
            value: option,
            groupValue: _sortOption,
            onChanged: (value) {
              setState(() {
                _sortOption = value!;
              });
              _applyFilters();
              Navigator.pop(context);
            },
          ),
        ),
      ],
    ),
  );
}


  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Categories'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            ),
            ..._categories.map((category) => ListTile(
              title: Text(category),
              leading: Radio<String?>(
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showPriorityFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Priorities'),
              leading: Radio<TaskPriority?>(
                value: null,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() => _selectedPriority = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            ),
            ...TaskPriority.values.map((priority) => ListTile(
              title: Text(_getPriorityLabel(priority)),
              leading: Radio<TaskPriority?>(
                value: priority,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() => _selectedPriority = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Statuses'),
              leading: Radio<TaskStatus?>(
                value: null,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            ),
            ...TaskStatus.values.map((status) => ListTile(
              title: Text(_getStatusLabel(status)),
              leading: Radio<TaskStatus?>(
                value: status,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedPriority = null;
      _selectedStatus = null;
      _hideCompleted = false;
      _searchController.clear();
      _sortOption = SortOption.dueDateAsc;
    });
    _applyFilters();
  }

  void _showDeleteCompletedDialog() {
    final completedTasks = _allTasks.where((task) => task.status == TaskStatus.done).toList();
    
    if (completedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No completed tasks to delete'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Completed Tasks'),
        content: Text('Are you sure you want to delete all ${completedTasks.length} completed tasks? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete all completed tasks
              for (final task in completedTasks) {
                await _taskService.deleteTask(task.id);
              }
              
              // Refresh the data
              _loadData();
              
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${completedTasks.length} completed tasks'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.dueDateAsc:
        return 'Due Date (Earliest First)';
      case SortOption.dueDateDesc:
        return 'Due Date (Latest First)';
      case SortOption.nameAsc:
        return 'Name (A to Z)';
      case SortOption.nameDesc:
        return 'Name (Z to A)';
      case SortOption.priorityHigh:
        return 'Priority (High to Low)';
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void refresh() {
    _loadData();
  }
}