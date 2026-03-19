import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import '../utils/notification_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  Map<String, dynamic> _statistics = {};
  int _selectedIndex = 0;
  bool _isLoading = true;

  final List<String> _categories = [
    'All Tasks',
    'Today',
    'Important',
    'Completed',
    'Repeated',
  ];

  final List<IconData> _categoryIcons = [
    Icons.list_alt,
    Icons.today,
    Icons.priority_high,
    Icons.check_circle,
    Icons.repeat,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final tasks = await _dbHelper.getTasks();
      final todayTasks = await _dbHelper.getTodayTasks();
      final statistics = await _dbHelper.getStatistics();

      // Schedule notifications for tasks with reminders
      for (var task in tasks) {
        if (task.reminderTime != null && !task.isCompleted) {
          await NotificationService.scheduleNotification(
            task.id!,
            task.title,
            task.description,
            task.reminderTime!,
          );
        }
      }

      setState(() {
        _tasks = tasks;
        _todayTasks = todayTasks;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Task> _getFilteredTasks() {
    switch (_selectedIndex) {
      case 0: // All Tasks
        return _tasks.where((task) => !task.isCompleted).toList();
      case 1: // Today
        return _todayTasks.where((task) => !task.isCompleted).toList();
      case 2: // Important (Priority 3)
        return _tasks
            .where((task) => task.priority == 3 && !task.isCompleted)
            .toList();
      case 3: // Completed
        return _tasks.where((task) => task.isCompleted).toList();
      case 4: // Repeated
        return _tasks.where((task) => task.isRepeated).toList();
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatistics(),
              _buildCategoryTabs(),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 500 + (index * 100)),
                      child: TaskCard(
                        task: task,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(task: task),
                            ),
                          );
                          if (result == true) _loadData();
                        },
                        onStatusChange: () async {
                          final updatedTask = task.copyWith(
                            isCompleted: !task.isCompleted,
                          );
                          await _dbHelper.updateTask(updatedTask);
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
          if (result == true) _loadData();
        },
        icon: Icon(Icons.add),
        label: Text('Add Task'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, User!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/images/profile.jpg'),
                  onBackgroundImageError: (_, __) {},
                  child: Icon(Icons.person),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            'Total Tasks',
            '${_statistics['total'] ?? 0}',
            Icons.assignment,
            Colors.blue,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            'Completed',
            '${_statistics['completed'] ?? 0}',
            Icons.check_circle,
            Colors.green,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            'Pending',
            '${_statistics['pending'] ?? 0}',
            Icons.pending,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedIndex == index
                    ? Color(0xFF6C63FF)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcons[index],
                    color: _selectedIndex == index ? Colors.white : Colors.grey,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    _categories[index],
                    style: TextStyle(
                      color: _selectedIndex == index ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add a new task',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}