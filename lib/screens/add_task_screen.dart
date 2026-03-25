import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../utils/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;

  const AddTaskScreen({Key? key, this.task}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(Duration(hours: 1));
  DateTime? _reminderTime;
  String _category = 'work';
  int _priority = 2;
  bool _isRepeated = false;
  String _repeatType = 'daily';
  List<String> _subtasks = [];
  List<bool> _subtaskStatus = [];
  final List<String> _categories = ['Work', 'Personal', 'Shopping', 'Health', 'Education'];
  final List<String> _repeatTypes = ['daily', 'weekly', 'monthly'];
  String? _imagePath;

  final List<Color> _priorityColors = [
    Colors.green,
    Colors.orange,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _reminderTime = widget.task!.reminderTime;
      _category = widget.task!.category;
      _priority = widget.task!.priority;
      _isRepeated = widget.task!.isRepeated;
      _repeatType = widget.task!.repeatType;
      _subtasks = List.from(widget.task!.subtasks);
      _subtaskStatus = List.from(widget.task!.subtaskStatus);
      _imagePath = widget.task!.imagePath;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (timePicked != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _selectReminder() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? _dueDate,
      firstDate: DateTime.now(),
      lastDate: _dueDate,
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderTime ?? _dueDate),
      );
      if (timePicked != null) {
        setState(() {
          _reminderTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _addSubtask() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Add Subtask'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter subtask',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _subtasks.add(controller.text);
                    _subtaskStatus.add(false);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add New Task' : 'Edit Task'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color(0xFF1A1A1A), Color(0xFF2C2C2C)]
                : [Color(0xFFF5F7FF), Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              // Title Field
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // Description Field
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Due Date
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Color(0xFF6C63FF)),
                  title: Text('Due Date & Time'),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy • hh:mm a').format(_dueDate),
                  ),
                  trailing: Icon(Icons.edit),
                  onTap: _selectDate,
                ),
              ),
              SizedBox(height: 16),

              // Reminder
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(Icons.notifications, color: Color(0xFF6C63FF)),
                  title: Text('Set Reminder'),
                  subtitle: Text(
                    _reminderTime == null
                        ? 'No reminder'
                        : DateFormat('MMM d, yyyy • hh:mm a').format(_reminderTime!),
                  ),
                  trailing: _reminderTime == null
                      ? TextButton(
                    onPressed: _selectReminder,
                    child: Text('Add'),
                  )
                      : IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _reminderTime = null;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Category Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),

              // Priority Slider
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Low'),
                        Expanded(
                          child: Slider(
                            value: _priority.toDouble(),
                            min: 1,
                            max: 3,
                            divisions: 2,
                            activeColor: _priorityColors[_priority - 1],
                            onChanged: (value) {
                              setState(() {
                                _priority = value.round();
                              });
                            },
                          ),
                        ),
                        Text('High'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _priorityColors[_priority - 1].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _priority == 1
                                ? 'Low Priority'
                                : _priority == 2
                                ? 'Medium Priority'
                                : 'High Priority',
                            style: TextStyle(
                              color: _priorityColors[_priority - 1],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Repeat Switch
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Repeat Task'),
                      subtitle: Text('Task will repeat automatically'),
                      value: _isRepeated,
                      activeColor: Color(0xFF6C63FF),
                      onChanged: (value) {
                        setState(() {
                          _isRepeated = value;
                        });
                      },
                    ),
                    if (_isRepeated)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: DropdownButtonFormField<String>(
                          value: _repeatType,
                          decoration: InputDecoration(
                            labelText: 'Repeat Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _repeatTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _repeatType = value!;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Subtasks Section
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.checklist, color: Color(0xFF6C63FF)),
                      title: Text('Subtasks'),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _addSubtask,
                      ),
                    ),
                    if (_subtasks.isNotEmpty)
                      ..._subtasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final subtask = entry.value;
                        return ListTile(
                          leading: Checkbox(
                            value: _subtaskStatus[index],
                            onChanged: (value) {
                              setState(() {
                                _subtaskStatus[index] = value!;
                              });
                            },
                          ),
                          title: Text(
                            subtask,
                            style: TextStyle(
                              decoration: _subtaskStatus[index]
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _subtasks.removeAt(index);
                                _subtaskStatus.removeAt(index);
                              });
                            },
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Image Attachment
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(Icons.image, color: Color(0xFF6C63FF)),
                  title: Text('Attach Image'),
                  subtitle: Text(_imagePath ?? 'No image selected'),
                  trailing: IconButton(
                    icon: Icon(Icons.add_photo_alternate),
                    onPressed: _pickImage,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitTask,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.task == null ? 'Create Task' : 'Update Task',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate()) {
      // Calculate progress based on subtasks
      int progress = 0;
      if (_subtasks.isNotEmpty) {
        progress = (_subtaskStatus.where((s) => s).length / _subtasks.length * 100).round();
      }

      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate,
        reminderTime: _reminderTime,
        category: _category,
        priority: _priority,
        isCompleted: widget.task?.isCompleted ?? false,
        isRepeated: _isRepeated,
        repeatType: _repeatType,
        subtasks: _subtasks,
        subtaskStatus: _subtaskStatus,
        progress: progress,
        imagePath: _imagePath,
      );

      final dbHelper = DatabaseHelper();

      if (widget.task == null) {
        await dbHelper.insertTask(task);
      } else {
        await dbHelper.updateTask(task);
      }

      // Schedule notification if reminder is set
      if (_reminderTime != null) {
        await NotificationService.scheduleNotification(
          task.id!,
          task.title,
          task.description,
          _reminderTime!,
        );
      }

      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}