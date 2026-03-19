import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'task_manager.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        reminderTime TEXT,
        category TEXT NOT NULL,
        priority INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isRepeated INTEGER NOT NULL DEFAULT 0,
        repeatType TEXT NOT NULL DEFAULT 'none',
        subtasks TEXT,
        subtaskStatus TEXT,
        progress INTEGER DEFAULT 0,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN imagePath TEXT');
    }
  }

  // Insert Task
  Future<int> insertTask(Task task) async {
    Database db = await database;
    return await db.insert('tasks', task.toMap());
  }

  // Get All Tasks
  Future<List<Task>> getTasks() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Get Tasks by Category
  Future<List<Task>> getTasksByCategory(String category) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Get Today's Tasks
  Future<List<Task>> getTodayTasks() async {
    Database db = await database;
    DateTime today = DateTime.now();
    String todayStr = DateTime(today.year, today.month, today.day).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'dueDate LIKE ?',
      whereArgs: ['$todayStr%'],
      orderBy: 'priority DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Update Task
  Future<int> updateTask(Task task) async {
    Database db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete Task
  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔥 FIXED: Get Statistics (Error resolved)
  Future<Map<String, dynamic>> getStatistics() async {
    Database db = await database;

    // Fix: Use proper sqflite methods to get count
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
    final totalTasks = totalResult.first['count'] as int;

    final completedResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE isCompleted = 1');
    final completedTasks = completedResult.first['count'] as int;

    final pendingResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE isCompleted = 0');
    final pendingTasks = pendingResult.first['count'] as int;

    final highPriorityResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE priority = 3 AND isCompleted = 0');
    final highPriorityTasks = highPriorityResult.first['count'] as int;

    return {
      'total': totalTasks,
      'completed': completedTasks,
      'pending': pendingTasks,
      'highPriority': highPriorityTasks,
    };
  }

  // Alternative simpler method (if you prefer)
  Future<Map<String, dynamic>> getStatisticsSimple() async {
    Database db = await database;

    // Get all tasks
    final allTasks = await getTasks();

    int total = allTasks.length;
    int completed = allTasks.where((task) => task.isCompleted).length;
    int pending = total - completed;
    int highPriority = allTasks.where((task) => task.priority == 3 && !task.isCompleted).length;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'highPriority': highPriority,
    };
  }

  // Get Overdue Tasks
  Future<List<Task>> getOverdueTasks() async {
    Database db = await database;
    String now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'dueDate < ? AND isCompleted = 0',
      whereArgs: [now],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Get Tasks by Priority
  Future<List<Task>> getTasksByPriority(int priority) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'priority = ? AND isCompleted = 0',
      whereArgs: [priority],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Search Tasks
  Future<List<Task>> searchTasks(String query) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Delete All Completed Tasks
  Future<int> deleteCompletedTasks() async {
    Database db = await database;
    return await db.delete(
      'tasks',
      where: 'isCompleted = 1',
    );
  }
}