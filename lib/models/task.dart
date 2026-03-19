class Task {
  int? id;
  String title;
  String description;
  DateTime dueDate;
  DateTime? reminderTime;
  String category;
  int priority; // 1: Low, 2: Medium, 3: High
  bool isCompleted;
  bool isRepeated;
  String repeatType; // daily, weekly, monthly
  List<String> subtasks;
  List<bool> subtaskStatus;
  int progress;
  String? imagePath;
  DateTime createdAt;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.reminderTime,
    required this.category,
    required this.priority,
    this.isCompleted = false,
    this.isRepeated = false,
    this.repeatType = 'none',
    List<String>? subtasks,
    List<bool>? subtaskStatus,
    this.progress = 0,
    this.imagePath,
    DateTime? createdAt,
  })  : subtasks = subtasks ?? [],
        subtaskStatus = subtaskStatus ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
      'isRepeated': isRepeated ? 1 : 0,
      'repeatType': repeatType,
      'subtasks': subtasks.join('||'),
      'subtaskStatus': subtaskStatus.map((e) => e ? '1' : '0').join(''),
      'progress': progress,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      reminderTime: map['reminderTime'] != null
          ? DateTime.parse(map['reminderTime'])
          : null,
      category: map['category'],
      priority: map['priority'],
      isCompleted: map['isCompleted'] == 1,
      isRepeated: map['isRepeated'] == 1,
      repeatType: map['repeatType'],
      subtasks: (map['subtasks'] as String).split('||'),
      subtaskStatus: (map['subtaskStatus'] as String)
          .split('')
          .map((e) => e == '1')
          .toList(),
      progress: map['progress'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    String? category,
    int? priority,
    bool? isCompleted,
    bool? isRepeated,
    String? repeatType,
    List<String>? subtasks,
    List<bool>? subtaskStatus,
    int? progress,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeated: isRepeated ?? this.isRepeated,
      repeatType: repeatType ?? this.repeatType,
      subtasks: subtasks ?? this.subtasks,
      subtaskStatus: subtaskStatus ?? this.subtaskStatus,
      progress: progress ?? this.progress,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}