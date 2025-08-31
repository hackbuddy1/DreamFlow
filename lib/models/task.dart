enum TaskPriority { high, medium, low }

enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  final String name;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String category;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.name,
    this.description = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    required this.category,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? category,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.index,
      'status': status.index,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      priority: TaskPriority.values[json['priority']],
      status: TaskStatus.values[json['status']],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return taskDate.isBefore(today) && status != TaskStatus.done;
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return taskDate.isAtSameMomentAs(today);
  }
}