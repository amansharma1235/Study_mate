import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../auth/auth_controller.dart';

final notesSearchQueryProvider = StateProvider<String>((ref) => '');
final notesCategoryFilterProvider = StateProvider<String>((ref) => 'All');

final notesControllerProvider =
    StateNotifierProvider<NotesController, AsyncValue<List<NoteModel>>>((ref) {
      final repo = ref.watch(notesRepositoryProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return NotesController(repo, userId);
    });

final filteredNotesProvider = Provider<List<NoteModel>>((ref) {
  final notesState = ref.watch(notesControllerProvider);
  final query = ref.watch(notesSearchQueryProvider).toLowerCase();
  final category = ref.watch(notesCategoryFilterProvider);

  return notesState.maybeWhen(
    data: (notes) {
      return notes.where((n) {
        final matchesQuery =
            query.isEmpty ||
            n.title.toLowerCase().contains(query) ||
            n.content.toLowerCase().contains(query);
        final matchesCategory = category == 'All' || n.category == category;
        return matchesQuery && matchesCategory;
      }).toList();
    },
    orElse: () => [],
  );
});

class NotesController extends StateNotifier<AsyncValue<List<NoteModel>>> {
  final NotesRepository _repo;
  final String _userId;

  NotesController(this._repo, this._userId)
    : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _repo.getNotes(_userId));
  }

  Future<void> addNote({
    required String title,
    required String content,
    String category = 'General',
  }) async {
    final newNote = NoteModel(
      id: const Uuid().v4(),
      userId: _userId,
      title: title.trim(),
      content: content.trim(),
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.saveNote(newNote);
    await loadNotes();
  }

  Future<void> updateNote(NoteModel note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _repo.saveNote(updated);
    await loadNotes();
  }

  Future<void> togglePin(NoteModel note) async {
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await _repo.saveNote(updated);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repo.deleteNote(id, _userId);
    await loadNotes();
  }
}
