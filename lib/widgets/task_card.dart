import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:anchor/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final Function(TaskStatus)? onStatusChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeBackground(context, DismissDirection.startToEnd),
      secondaryBackground: _buildSwipeBackground(context, DismissDirection.endToStart),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _toggleStatus();
          return false; // Don't actually dismiss, just update status
        } else {
          onDelete?.call();
          return false; // Don't actually dismiss, let the parent handle it
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPriorityIndicator(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: task.status == TaskStatus.done 
                            ? TextDecoration.lineThrough 
                            : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(context),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _getDueDateColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(task.dueDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getDueDateColor(context),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    Color color;
    switch (task.priority) {
      case TaskPriority.high:
        color = Colors.red;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        break;
      case TaskPriority.low:
        color = Colors.green;
        break;
    }

    return Container(
      width: 4,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (task.status) {
      case TaskStatus.todo:
        backgroundColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey[700]!;
        label = 'To Do';
        break;
      case TaskStatus.inProgress:
        backgroundColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue[700]!;
        label = 'In Progress';
        break;
      case TaskStatus.done:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green[700]!;
        label = 'Done';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, DismissDirection direction) {
    if (direction == DismissDirection.startToEnd) {
      return Container(
        color: task.status == TaskStatus.done ? Colors.orange : Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          task.status == TaskStatus.done ? Icons.undo : Icons.check,
          color: Colors.white,
          size: 28,
        ),
      );
    } else {
      return Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      );
    }
  }

  Color _getDueDateColor(BuildContext context) {
    if (task.isOverdue) {
      return Colors.red;
    } else if (task.isToday) {
      return Theme.of(context).primaryColor;
    } else {
      return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    }
  }

  void _toggleStatus() {
    switch (task.status) {
      case TaskStatus.todo:
        onStatusChanged?.call(TaskStatus.inProgress);
        break;
      case TaskStatus.inProgress:
        onStatusChanged?.call(TaskStatus.done);
        break;
      case TaskStatus.done:
        onStatusChanged?.call(TaskStatus.todo);
        break;
    }
  }
}