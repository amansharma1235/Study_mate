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
import '../models/planner_model.dart';
import '../models/flashcard_model.dart';
import '../models/syllabus_model.dart';
import '../models/habit_model.dart';
import '../models/document_model.dart';
import '../models/voice_note_model.dart';
import '../models/career_model.dart';
import '../models/study_group_model.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

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

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createV1Tables(db);
        await _createV2Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
        }
      },
    );
  }

  Future<void> _createV1Tables(Database db) async {
    // Notes Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
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
      CREATE TABLE IF NOT EXISTS tasks (
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
      CREATE TABLE IF NOT EXISTS timetable (
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
      CREATE TABLE IF NOT EXISTS pomodoro_sessions (
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
      CREATE TABLE IF NOT EXISTS exams (
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
      CREATE TABLE IF NOT EXISTS quiz_attempts (
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
      CREATE TABLE IF NOT EXISTS saved_tips (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        summary TEXT NOT NULL,
        content TEXT NOT NULL,
        isFavorite INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createV2Tables(Database db) async {
    // Study Sessions / Smart Planner
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_sessions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        sessionDate TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        priority TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        isBreak INTEGER NOT NULL,
        notes TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Flashcard Decks
    await db.execute('''
      CREATE TABLE IF NOT EXISTS flashcard_decks (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        description TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        cardCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Flashcards
    await db.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        deckId TEXT NOT NULL,
        userId TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        hint TEXT NOT NULL,
        intervalDays INTEGER NOT NULL,
        easeFactor REAL NOT NULL,
        repetitionNumber INTEGER NOT NULL,
        nextReviewDate TEXT NOT NULL,
        lastReviewedAt TEXT,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Syllabus Topics
    await db.execute('''
      CREATE TABLE IF NOT EXISTS syllabus_topics (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subject TEXT NOT NULL,
        chapter TEXT NOT NULL,
        title TEXT NOT NULL,
        status TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        priority TEXT NOT NULL,
        revisionCount INTEGER NOT NULL,
        lastRevisionDate TEXT,
        nextRevisionDate TEXT,
        notes TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Habits
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        iconName TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        targetDaysPerWeek INTEGER NOT NULL,
        currentStreak INTEGER NOT NULL,
        bestStreak INTEGER NOT NULL,
        completedDates TEXT NOT NULL,
        reminderTime TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Documents
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        fileType TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileSizeBytes INTEGER NOT NULL,
        pageCount INTEGER NOT NULL,
        lastOpenedPage INTEGER NOT NULL,
        isBookmarked INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Voice Notes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS voice_notes (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        audioPath TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        transcription TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Career / Job Applications
    await db.execute('''
      CREATE TABLE IF NOT EXISTS job_applications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        company TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        appliedDate TEXT NOT NULL,
        deadline TEXT,
        location TEXT NOT NULL,
        stipendOrSalary TEXT NOT NULL,
        notes TEXT NOT NULL,
        link TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // Study Groups
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        subject TEXT NOT NULL,
        adminUserId TEXT NOT NULL,
        joinCode TEXT NOT NULL,
        memberCount INTEGER NOT NULL,
        sharedNotesCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
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
      orderBy: 'isCompleted ASC, dueDate ASC',
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
  Future<int> insertTimetable(TimetableModel item) async {
    final db = await database;
    return await db.insert(
      'timetable',
      item.toMap(),
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

  Future<int> updateTimetable(TimetableModel item) async {
    final db = await database;
    return await db.update(
      'timetable',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteTimetable(String id) async {
    final db = await database;
    return await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  // --- Pomodoro Sessions Operations ---
  Future<int> insertPomodoroSession(PomodoroSessionModel session) async {
    final db = await database;
    return await db.insert(
      'pomodoro_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PomodoroSessionModel>> getPomodoroSessions(String userId) async {
    final db = await database;
    final maps = await db.query(
      'pomodoro_sessions',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'completedAt DESC',
    );
    return maps.map((m) => PomodoroSessionModel.fromMap(m)).toList();
  }

  // Backward compatibility alias for timer repository and data export
  Future<int> insertSession(PomodoroSessionModel session) =>
      insertPomodoroSession(session);
  Future<List<PomodoroSessionModel>> getSessions(String userId) =>
      getPomodoroSessions(userId);

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
      orderBy: 'isCompleted ASC, examDate ASC',
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

  // --- Quiz Attempts Operations ---
  Future<int> insertQuizAttempt(QuizAttemptModel attempt) async {
    final db = await database;
    return await db.insert(
      'quiz_attempts',
      attempt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<QuizAttemptModel>> getQuizAttempts(String userId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_attempts',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'completedAt DESC',
    );
    return maps.map((m) => QuizAttemptModel.fromMap(m)).toList();
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
    final maps = await db.query('saved_tips', orderBy: 'id ASC');
    return maps.map((m) => StudyTipModel.fromMap(m)).toList();
  }

  Future<int> deleteSavedTip(String id) async {
    final db = await database;
    return await db.delete('saved_tips', where: 'id = ?', whereArgs: [id]);
  }

  // --- Study Sessions (Planner) Operations ---
  Future<int> insertStudySession(StudySessionModel session) async {
    final db = await database;
    return await db.insert(
      'study_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudySessionModel>> getStudySessions(String userId) async {
    final db = await database;
    final maps = await db.query(
      'study_sessions',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'sessionDate ASC, startTime ASC',
    );
    return maps.map((m) => StudySessionModel.fromMap(m)).toList();
  }

  Future<int> updateStudySession(StudySessionModel session) async {
    final db = await database;
    return await db.update(
      'study_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteStudySession(String id) async {
    final db = await database;
    return await db.delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Flashcard Operations ---
  Future<int> insertFlashcardDeck(FlashcardDeckModel deck) async {
    final db = await database;
    return await db.insert(
      'flashcard_decks',
      deck.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FlashcardDeckModel>> getFlashcardDecks(String userId) async {
    final db = await database;
    final maps = await db.query(
      'flashcard_decks',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => FlashcardDeckModel.fromMap(m)).toList();
  }

  Future<int> deleteFlashcardDeck(String deckId) async {
    final db = await database;
    await db.delete('flashcards', where: 'deckId = ?', whereArgs: [deckId]);
    return await db.delete(
      'flashcard_decks',
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }

  Future<int> insertFlashcard(FlashcardModel card) async {
    final db = await database;
    return await db.insert(
      'flashcards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FlashcardModel>> getFlashcards(String deckId) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'deckId = ?',
      whereArgs: [deckId],
      orderBy: 'nextReviewDate ASC',
    );
    return maps.map((m) => FlashcardModel.fromMap(m)).toList();
  }

  Future<int> updateFlashcard(FlashcardModel card) async {
    final db = await database;
    return await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteFlashcard(String id) async {
    final db = await database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  // --- Syllabus Topics Operations ---
  Future<int> insertSyllabusTopic(SyllabusTopicModel topic) async {
    final db = await database;
    return await db.insert(
      'syllabus_topics',
      topic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyllabusTopicModel>> getSyllabusTopics(String userId) async {
    final db = await database;
    final maps = await db.query(
      'syllabus_topics',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'subject ASC, chapter ASC',
    );
    return maps.map((m) => SyllabusTopicModel.fromMap(m)).toList();
  }

  Future<int> updateSyllabusTopic(SyllabusTopicModel topic) async {
    final db = await database;
    return await db.update(
      'syllabus_topics',
      topic.toMap(),
      where: 'id = ?',
      whereArgs: [topic.id],
    );
  }

  Future<int> deleteSyllabusTopic(String id) async {
    final db = await database;
    return await db.delete('syllabus_topics', where: 'id = ?', whereArgs: [id]);
  }

  // --- Habits Operations ---
  Future<int> insertHabit(HabitModel habit) async {
    final db = await database;
    return await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HabitModel>> getHabits(String userId) async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => HabitModel.fromMap(m)).toList();
  }

  Future<int> updateHabit(HabitModel habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(String id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // --- Documents Operations ---
  Future<int> insertDocument(DocumentModel doc) async {
    final db = await database;
    return await db.insert(
      'documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DocumentModel>> getDocuments(String userId) async {
    final db = await database;
    final maps = await db.query(
      'documents',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => DocumentModel.fromMap(m)).toList();
  }

  Future<int> deleteDocument(String id) async {
    final db = await database;
    return await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // --- Voice Notes Operations ---
  Future<int> insertVoiceNote(VoiceNoteModel vn) async {
    final db = await database;
    return await db.insert(
      'voice_notes',
      vn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VoiceNoteModel>> getVoiceNotes(String userId) async {
    final db = await database;
    final maps = await db.query(
      'voice_notes',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => VoiceNoteModel.fromMap(m)).toList();
  }

  Future<int> deleteVoiceNote(String id) async {
    final db = await database;
    return await db.delete('voice_notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Job Applications Operations ---
  Future<int> insertJobApplication(JobApplicationModel job) async {
    final db = await database;
    return await db.insert(
      'job_applications',
      job.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<JobApplicationModel>> getJobApplications(String userId) async {
    final db = await database;
    final maps = await db.query(
      'job_applications',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, ''],
      orderBy: 'appliedDate DESC',
    );
    return maps.map((m) => JobApplicationModel.fromMap(m)).toList();
  }

  Future<int> updateJobApplication(JobApplicationModel job) async {
    final db = await database;
    return await db.update(
      'job_applications',
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  Future<int> deleteJobApplication(String id) async {
    final db = await database;
    return await db.delete(
      'job_applications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Study Groups Operations ---
  Future<int> insertStudyGroup(StudyGroupModel group) async {
    final db = await database;
    return await db.insert(
      'study_groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudyGroupModel>> getStudyGroups() async {
    final db = await database;
    final maps = await db.query('study_groups', orderBy: 'createdAt DESC');
    return maps.map((m) => StudyGroupModel.fromMap(m)).toList();
  }

  Future<int> deleteStudyGroup(String id) async {
    final db = await database;
    return await db.delete('study_groups', where: 'id = ?', whereArgs: [id]);
  }

  // --- Clear all User Data on Account Deletion ---
  Future<void> clearAllUserData(String userId) async {
    final db = await database;
    final userWhere = 'userId = ? OR userId = ?';
    final userArgs = [userId, ''];

    await db.delete('notes', where: userWhere, whereArgs: userArgs);
    await db.delete('tasks', where: userWhere, whereArgs: userArgs);
    await db.delete('timetable', where: userWhere, whereArgs: userArgs);
    await db.delete('pomodoro_sessions', where: userWhere, whereArgs: userArgs);
    await db.delete('exams', where: userWhere, whereArgs: userArgs);
    await db.delete('quiz_attempts', where: userWhere, whereArgs: userArgs);
    await db.delete('study_sessions', where: userWhere, whereArgs: userArgs);
    await db.delete('flashcard_decks', where: userWhere, whereArgs: userArgs);
    await db.delete('flashcards', where: userWhere, whereArgs: userArgs);
    await db.delete('syllabus_topics', where: userWhere, whereArgs: userArgs);
    await db.delete('habits', where: userWhere, whereArgs: userArgs);
    await db.delete('documents', where: userWhere, whereArgs: userArgs);
    await db.delete('voice_notes', where: userWhere, whereArgs: userArgs);
    await db.delete('job_applications', where: userWhere, whereArgs: userArgs);
  }
}
