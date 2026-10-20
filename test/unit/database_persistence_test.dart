import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/local/app_database.dart';
import 'package:study_mate/data/models/note_model.dart';
import 'package:study_mate/data/models/task_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppDatabase initializes, saves notes and tasks successfully', () async {
    final db = AppDatabase.instance;

    // Test saving note
    final note = NoteModel(
      id: const Uuid().v4(),
      userId: 'test_user',
      title: 'Physics Mechanics Note',
      content: 'Newton third law states action equals reaction.',
      category: 'Science',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final insertedNoteRow = await db.insertNote(note);
    expect(insertedNoteRow, greaterThan(0));

    final notes = await db.getNotes('test_user');
    expect(notes.any((n) => n.id == note.id), isTrue);

    // Test saving task
    final task = TaskModel(
      id: const Uuid().v4(),
      userId: 'test_user',
      title: 'Complete Math Homework',
      description: 'Solve exercises 1 to 10',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      priority: TaskPriority.high,
      subject: 'Math',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final insertedTaskRow = await db.insertTask(task);
    expect(insertedTaskRow, greaterThan(0));

    final tasks = await db.getTasks('test_user');
    expect(tasks.any((t) => t.id == task.id), isTrue);

    // Cleanup
    await db.deleteNote(note.id);
    await db.deleteTask(task.id);
  });
}
