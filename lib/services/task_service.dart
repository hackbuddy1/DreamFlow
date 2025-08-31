import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anchor/models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  static const String _categoriesKey = 'categories';
  
  static final List<String> _defaultCategories = [
    'Work',
    'Personal', 
    'Shopping',
    'Health'
  ];

  static TaskService? _instance;
  static TaskService get instance {
    _instance ??= TaskService._internal();
    return _instance!;
  }
  TaskService._internal();

  Future<List<Task>> getAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    return tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_tasksKey, tasksJson);
  }

  Future<void> addTask(Task task) async {
    final tasks = await getAllTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  Future<void> updateTask(Task updatedTask) async {
    final tasks = await getAllTasks();
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getAllTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await saveTasks(tasks);
  }

  Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categories = prefs.getStringList(_categoriesKey);
    if (categories == null) {
      await prefs.setStringList(_categoriesKey, _defaultCategories);
      return _defaultCategories;
    }
    return categories;
  }

  Future<void> addCategory(String category) async {
    final categories = await getCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_categoriesKey, categories);
    }
  }

  Future<void> deleteCategory(String category) async {
    if (_defaultCategories.contains(category)) return;
    final categories = await getCategories();
    categories.remove(category);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  List<Task> getTodaysTasks(List<Task> allTasks) {
    return allTasks.where((task) => task.isToday && task.status != TaskStatus.done).toList();
  }

  List<Task> getOverdueTasks(List<Task> allTasks) {
    return allTasks.where((task) => task.isOverdue).toList();
  }

  List<Task> getTasksForDate(List<Task> allTasks, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return allTasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  Future<void> initializeSampleData() async {
    final tasks = await getAllTasks();
    if (tasks.isEmpty) {
      final sampleTasks = _createSampleTasks();
      await saveTasks(sampleTasks);
    }
  }

  List<Task> _createSampleTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      Task(
        id: '1',
        name: 'Complete project proposal',
        description: 'Finish writing the Q1 project proposal for client meeting',
        dueDate: today.add(const Duration(hours: 14)),
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        category: 'Work',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: '2',
        name: 'Buy groceries',
        description: 'Milk, eggs, bread, vegetables for the week',
        dueDate: today.add(const Duration(hours: 18)),
        priority: TaskPriority.medium,
        status: TaskStatus.todo,
        category: 'Shopping',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Task(
        id: '3',
        name: 'Doctor appointment',
        description: 'Annual checkup at 3 PM',
        dueDate: today.subtract(const Duration(days: 1)),
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        category: 'Health',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Task(
        id: '4',
        name: 'Team standup meeting',
        description: 'Daily team sync at 10 AM',
        dueDate: today.add(const Duration(days: 1)),
        priority: TaskPriority.low,
        status: TaskStatus.todo,
        category: 'Work',
        createdAt: now,
      ),
      Task(
        id: '5',
        name: 'Read book chapter',
        description: 'Chapter 5 of "Atomic Habits"',
        dueDate: today,
        priority: TaskPriority.low,
        status: TaskStatus.done,
        category: 'Personal',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: '6',
        name: 'Gym workout',
        description: 'Chest and triceps day',
        dueDate: today.add(const Duration(days: 2)),
        priority: TaskPriority.medium,
        status: TaskStatus.todo,
        category: 'Health',
        createdAt: now,
      ),
    ];
  }
}