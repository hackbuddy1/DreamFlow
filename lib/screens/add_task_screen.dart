import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:anchor/models/task.dart';
import 'package:anchor/services/task_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newCategoryController = TextEditingController();

  final TaskService _taskService = TaskService.instance;
  DateTime _dueDate = DateTime.now();
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  String _selectedCategory = 'Work';
  List<String> _categories = [];
  bool _showNewCategoryField = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeFields();
  }

  Future<void> _loadCategories() async {
    final categories = await _taskService.getCategories();
    if (!mounted) return; // ✅ mounted check
    setState(() {
      _categories = categories;
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.first;
      }
    });
  }

  void _initializeFields() {
    if (widget.task != null) {
      final task = widget.task!;
      _nameController.text = task.name;
      _descriptionController.text = task.description;
      _dueDate = task.dueDate;
      _priority = task.priority;
      _status = task.status;
      _selectedCategory = task.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: Text(
              isEditing ? 'Update' : 'Save',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildDueDateField(),
              const SizedBox(height: 16),
              _buildPriorityField(),
              if (isEditing) ...[
                const SizedBox(height: 16),
                _buildStatusField(),
              ],
              const SizedBox(height: 16),
              _buildCategoryField(),
              if (_showNewCategoryField) ...[
                const SizedBox(height: 12),
                _buildNewCategoryField(),
              ],
              const SizedBox(height: 32),
              _buildActionButtons(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Task Name *',
        hintText: 'Enter task name',
        border: OutlineInputBorder(),
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a task name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Add task description',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      maxLength: 500,
    );
  }

  Widget _buildDueDateField() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date *',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_dueDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(_dueDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: TaskPriority.values.map((priority) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PriorityChip(
                  priority: priority,
                  isSelected: _priority == priority,
                  onTap: () => setState(() => _priority = priority),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TaskStatus>(
          initialValue: _status, // ✅ updated from initialValue to value
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: TaskStatus.values.map((status) {
            String label;
            switch (status) {
              case TaskStatus.todo:
                label = 'To Do';
                break;
              case TaskStatus.inProgress:
                label = 'In Progress';
                break;
              case TaskStatus.done:
                label = 'Done';
                break;
            }
            return DropdownMenuItem(
              value: status,
              child: Text(label),
            );
          }).toList(),
          onChanged: (status) => setState(() => _status = status!),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory, // ✅ updated
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            ..._categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )),
            const DropdownMenuItem(
              value: 'add_new',
              child: Text(
                '+ Add New Category',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == 'add_new') {
              setState(() => _showNewCategoryField = true);
            } else {
              setState(() {
                _selectedCategory = value!;
                _showNewCategoryField = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildNewCategoryField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _newCategoryController,
            decoration: const InputDecoration(
              labelText: 'New Category Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addNewCategory,
          child: const Text('Add'),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => setState(() => _showNewCategoryField = false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _saveTask,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Text(isEditing ? 'Update Task' : 'Create Task'),
        ),
        if (isEditing) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showDeleteDialog,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Task'),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _dueDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _addNewCategory() async {
    final categoryName = _newCategoryController.text.trim();
    if (categoryName.isNotEmpty) {
      await _taskService.addCategory(categoryName);
      await _loadCategories();
      if (!mounted) return;
      setState(() {
        _selectedCategory = categoryName;
        _showNewCategoryField = false;
        _newCategoryController.clear();
      });
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      category: _selectedCategory,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
    );

    if (widget.task != null) {
      await _taskService.updateTask(task);
    } else {
      await _taskService.addTask(task);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _taskService.deleteTask(widget.task!.id);
              if (mounted) {
                if (mounted){
                Navigator.of(context).pop(true);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }
}

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (priority) {
      case TaskPriority.high:
        color = Colors.red;
        label = 'High';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case TaskPriority.low:
        color = Colors.green;
        label = 'Low';
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha((0.2*255).round()), // ✅ updated
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
