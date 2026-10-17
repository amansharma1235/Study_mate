import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note_model.dart';
import '../models/task_model.dart';
import '../models/timetable_model.dart';
import '../models/pomodoro_session_model.dart';
import '../models/exam_model.dart';
import '../models/quiz_model.dart';
import '../models/study_tip_model.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  // For testing
  AppDatabase.withDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('studymate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Notes Table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        isPinned INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Tasks Table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        priority TEXT NOT NULL,
        subject TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        reminderEnabled INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Timetable Table
    await db.execute('''
      CREATE TABLE timetable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subject TEXT NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        room TEXT NOT NULL,
        instructor TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Pomodoro Sessions Table
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subject TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        mode TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Exams Table
    await db.execute('''
      CREATE TABLE exams (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        examDate TEXT NOT NULL,
        description TEXT NOT NULL,
        reminderEnabled INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Quiz Attempts Table
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        category TEXT NOT NULL,
        totalQuestions INTEGER NOT NULL,
        correctAnswers INTEGER NOT NULL,
        scorePercentage REAL NOT NULL,
        completedAt TEXT NOT NULL
      )
    ''');

    // Saved Tips Table
    await db.execute('''
      CREATE TABLE saved_tips (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        summary TEXT NOT NULL,
        content TEXT NOT NULL,
        isFavorite INTEGER NOT NULL
      )
    ''');
  }

  // --- Notes Operations ---
  Future<int> insertNote(NoteModel note) async {
    final db = await database;
    return await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NoteModel>> getNotes(String userId) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Tasks Operations ---
  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TaskModel>> getTasks(String userId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'dueDate ASC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Timetable Operations ---
  Future<int> insertTimetable(TimetableModel entry) async {
    final db = await database;
    return await db.insert(
      'timetable',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TimetableModel>> getTimetable(String userId) async {
    final db = await database;
    final maps = await db.query(
      'timetable',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'dayOfWeek ASC, startTime ASC',
    );
    return maps.map((m) => TimetableModel.fromMap(m)).toList();
  }

  Future<int> updateTimetable(TimetableModel entry) async {
    final db = await database;
    return await db.update(
      'timetable',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteTimetable(String id) async {
    final db = await database;
    return await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  // --- Pomodoro Sessions Operations ---
  Future<int> insertSession(PomodoroSessionModel session) async {
    final db = await database;
    return await db.insert(
      'pomodoro_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PomodoroSessionModel>> getSessions(String userId) async {
    final db = await database;
    final maps = await db.query(
      'pomodoro_sessions',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'completedAt DESC',
    );
    return maps.map((m) => PomodoroSessionModel.fromMap(m)).toList();
  }

  // --- Exams Operations ---
  Future<int> insertExam(ExamModel exam) async {
    final db = await database;
    return await db.insert(
      'exams',
      exam.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExamModel>> getExams(String userId) async {
    final db = await database;
    final maps = await db.query(
      'exams',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'examDate ASC',
    );
    return maps.map((m) => ExamModel.fromMap(m)).toList();
  }

  Future<int> updateExam(ExamModel exam) async {
    final db = await database;
    return await db.update(
      'exams',
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<int> deleteExam(String id) async {
    final db = await database;
    return await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  // --- Quiz Attempt Operations ---
  Future<int> insertQuizAttempt(QuizAttempt attempt) async {
    final db = await database;
    return await db.insert(
      'quiz_attempts',
      attempt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<QuizAttempt>> getQuizAttempts(String userId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_attempts',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'completedAt DESC',
    );
    return maps.map((m) => QuizAttempt.fromMap(m)).toList();
  }

  // --- Saved Tips Operations ---
  Future<int> insertSavedTip(StudyTipModel tip) async {
    final db = await database;
    return await db.insert(
      'saved_tips',
      tip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudyTipModel>> getSavedTips() async {
    final db = await database;
    final maps = await db.query('saved_tips', orderBy: 'title ASC');
    return maps.map((m) => StudyTipModel.fromMap(m)).toList();
  }

  Future<int> deleteSavedTip(String id) async {
    final db = await database;
    return await db.delete('saved_tips', where: 'id = ?', whereArgs: [id]);
  }

  // --- Clear all User Data on Account Deletion ---
  Future<void> clearAllUserData(String userId) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
    );
    await db.delete(
      'tasks',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
    );
    await db.delete(
      'timetable',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
    );
    await db.delete(
      'pomodoro_sessions',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
    );
    await db.delete(
      'exams',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
    );
    await db.delete(
      'quiz_attempts',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
    );
  }
}
