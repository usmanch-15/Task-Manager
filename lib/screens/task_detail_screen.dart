import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Color _getPriorityColor() {
    switch (_task.priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteTask(_task.id!);
      Navigator.pop(context, true);
    }
  }

  Future<void> _shareTask() async {
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');
    final message = '''
Task: ${_task.title}
Description: ${_task.description}
Due: ${dateFormat.format(_task.dueDate)}
Priority: ${_task.priority == 1 ? 'Low' : _task.priority == 2 ? 'Medium' : 'High'}
Status: ${_task.isCompleted ? 'Completed' : 'Pending'}
    '''.trim();

    await Share.share(message);
  }

  Future<void> _toggleSubtask(int index) async {
    setState(() {
      _task.subtaskStatus[index] = !_task.subtaskStatus[index];
      // Update progress
      final completed = _task.subtaskStatus.where((s) => s).length;
      _task.progress = (completed / _task.subtasks.length * 100).round();
    });
    await _dbHelper.updateTask(_task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF1A1A1A), Color(0xFF2C2C2C)]
                : [Color(0xFFF5F7FF), Colors.white],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: _task.imagePath != null
                    ? Image.file(
                  File(_task.imagePath!),
                  fit: BoxFit.cover,
                )
                    : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF9F7AEA),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.task_alt,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: _shareTask,
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTaskScreen(task: _task),
                      ),
                    );
                    if (result == true) {
                      final tasks = await _dbHelper.getTasks();
                      final updatedTask = tasks.firstWhere((t) => t.id == _task.id);
                      setState(() {
                        _task = updatedTask;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _deleteTask,
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Status Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _task.isCompleted
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _task.isCompleted ? 'Completed' : 'Pending',
                                style: TextStyle(
                                  color: _task.isCompleted ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!_task.isCompleted) ...[
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                _task.isCompleted = true;
                                await _dbHelper.updateTask(_task);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Mark as Complete'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Description
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _task.description.isEmpty
                              ? 'No description added'
                              : _task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Details Grid
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Due Date',
                          dateFormat.format(_task.dueDate),
                        ),
                        Divider(),
                        _buildDetailRow(
                          Icons.category,
                          'Category',
                          _task.category,
                        ),
                        Divider(),
                        _buildDetailRow(
                          Icons.priority_high,
                          'Priority',
                          _task.priority == 1
                              ? 'Low'
                              : _task.priority == 2
                              ? 'Medium'
                              : 'High',
                          color: _getPriorityColor(),
                        ),
                        if (_task.reminderTime != null) ...[
                          Divider(),
                          _buildDetailRow(
                            Icons.notifications,
                            'Reminder',
                            dateFormat.format(_task.reminderTime!),
                          ),
                        ],
                        if (_task.isRepeated) ...[
                          Divider(),
                          _buildDetailRow(
                            Icons.repeat,
                            'Repeat',
                            _task.repeatType.toUpperCase(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Subtasks
                  if (_task.subtasks.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtasks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6C63FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_task.progress}%',
                                  style: TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _task.progress / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6C63FF),
                            ),
                          ),
                          SizedBox(height: 16),
                          ..._task.subtasks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final subtask = entry.value;
                            return CheckboxListTile(
                              value: _task.subtaskStatus[index],
                              onChanged: _task.isCompleted
                                  ? null
                                  : (value) => _toggleSubtask(index),
                              title: Text(
                                subtask,
                                style: TextStyle(
                                  decoration: _task.subtaskStatus[index]
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              activeColor: Color(0xFF6C63FF),
                              checkColor: Colors.white,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Color(0xFF6C63FF)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}