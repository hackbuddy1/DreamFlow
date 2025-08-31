# Task Manager - Architecture Documentation

## Application Overview
Task Manager is a comprehensive daily task management application with clean, intuitive UI and powerful task tracking capabilities. The app focuses on helping users organize, track, and complete their daily tasks efficiently.

## Technical Architecture

### Core Components
1. **Task Model** - Data structure with all required fields
2. **Task Service** - Local storage management using SharedPreferences
3. **Main Navigation** - Tab-based navigation with 4 screens
4. **Task Widgets** - Reusable UI components

### Screen Structure
1. **Dashboard (Home)** - Today's tasks and overdue tasks sections
2. **All Tasks** - Complete task list with filtering and search
3. **Calendar View** - Monthly calendar with task visualization
4. **Add Task** - Form interface for creating/editing tasks

### Data Model
```dart
class Task {
  String id;
  String name; // max 100 chars
  String description; // max 500 chars, optional
  DateTime dueDate;
  TaskPriority priority; // High, Medium, Low
  TaskStatus status; // To Do, In Progress, Done
  String category; // Work, Personal, Shopping, Health + custom
  DateTime createdAt;
}
```

### Priority System
- High Priority: Red color coding
- Medium Priority: Orange color coding  
- Low Priority: Green color coding

### Key Features Implementation
- Local storage with SharedPreferences for offline functionality
- Swipe gestures for task management
- One-tap status updates with visual feedback
- Hide/show completed tasks toggle
- Search and filter functionality
- Custom category management
- Calendar integration with task density indicators

### File Structure
- `lib/models/task.dart` - Task data model and enums
- `lib/services/task_service.dart` - Data persistence layer
- `lib/screens/dashboard_screen.dart` - Home screen with today's & overdue tasks
- `lib/screens/all_tasks_screen.dart` - Complete task list with filters
- `lib/screens/calendar_screen.dart` - Monthly calendar view
- `lib/screens/add_task_screen.dart` - Task creation/editing form
- `lib/widgets/task_card.dart` - Individual task display component
- `lib/widgets/task_filter_bar.dart` - Filter and search controls
- `lib/main.dart` - App entry point with tab navigation

## Implementation Priority
1. Create Task model and service layer
2. Implement main navigation structure
3. Build Dashboard screen with sample data
4. Create Add Task screen and form
5. Implement All Tasks screen with filters
6. Build Calendar view integration
7. Add task management gestures and interactions
8. Final testing and debugging