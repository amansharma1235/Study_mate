import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../data/models/flashcard_model.dart';
import '../auth/auth_controller.dart';

final flashcardDecksProvider =
    StateNotifierProvider<
      FlashcardDecksController,
      AsyncValue<List<FlashcardDeckModel>>
    >((ref) {
      final db = ref.watch(appDatabaseProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return FlashcardDecksController(db, userId);
    });

class FlashcardDecksController
    extends StateNotifier<AsyncValue<List<FlashcardDeckModel>>> {
  final AppDatabase _db;
  final String _userId;

  FlashcardDecksController(this._db, this._userId)
    : super(const AsyncValue.loading()) {
    loadDecks();
  }

  Future<void> loadDecks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => await _db.getFlashcardDecks(_userId),
    );
  }

  Future<void> createDeck({
    required String title,
    required String subject,
    String description = '',
    String colorHex = '#6258E8',
  }) async {
    final deck = FlashcardDeckModel(
      id: const Uuid().v4(),
      userId: _userId,
      title: title,
      subject: subject,
      description: description,
      colorHex: colorHex,
      cardCount: 0,
    );

    await _db.insertFlashcardDeck(deck);
    await loadDecks();
  }

  Future<void> deleteDeck(String id) async {
    await _db.deleteFlashcardDeck(id);
    await loadDecks();
  }

  Future<void> addCardToDeck({
    required String deckId,
    required String front,
    required String back,
    String hint = '',
  }) async {
    final card = FlashcardModel(
      id: const Uuid().v4(),
      deckId: deckId,
      userId: _userId,
      front: front,
      back: back,
      hint: hint,
      intervalDays: 0,
      repetitionNumber: 0,
      nextReviewDate: DateTime.now(),
    );

    await _db.insertFlashcard(card);
    await loadDecks();
  }

  // Seed sample starter decks for testing
  Future<void> seedStarterDecks() async {
    final sampleDecks = [
      {
        'title': 'Core CS & Data Structures',
        'subject': 'Computer Science',
        'desc': 'Essential algorithms, big-O, and binary trees',
        'color': '#6258E8',
        'cards': [
          {
            'front': 'What is the time complexity of searching in a Balanced Binary Search Tree (AVL/Red-Black)?',
            'back': 'O(log n) in both average and worst cases.',
            'hint': 'Logarithmic based on tree height.',
          },
          {
            'front': 'What is the difference between BFS and DFS?',
            'back': 'BFS explores level-by-level using a Queue (FIFO).\nDFS explores as deep as possible using a Stack (LIFO) or recursion.',
            'hint': 'Queue vs Stack',
          },
          {
            'front': 'What are the 4 fundamental pillars of OOP?',
            'back': '1. Encapsulation\n2. Abstraction\n3. Inheritance\n4. Polymorphism',
            'hint': 'E.A.I.P',
          },
        ],
      },
      {
        'title': 'Physics & Mechanics Formulas',
        'subject': 'Physics',
        'desc': 'Kinematics, work energy, and momentum laws',
        'color': '#10B981',
        'cards': [
          {
            'front': 'State Newton\'s Second Law of Motion.',
            'back': 'Force equals the rate of change of momentum: F = ma (when mass is constant).',
            'hint': 'F = ?',
          },
          {
            'front': 'What is the Work-Energy Theorem?',
            'back': 'Net work done on an object equals the change in its kinetic energy: W_net = ΔKE.',
            'hint': 'Work = change in energy',
          },
        ],
      },
    ];

    for (final d in sampleDecks) {
      final deckId = const Uuid().v4();
      final deck = FlashcardDeckModel(
        id: deckId,
        userId: _userId,
        title: d['title'] as String,
        subject: d['subject'] as String,
        description: d['desc'] as String,
        colorHex: d['color'] as String,
        cardCount: (d['cards'] as List).length,
      );
      await _db.insertFlashcardDeck(deck);

      for (final c in d['cards'] as List<Map<String, String>>) {
        final card = FlashcardModel(
          id: const Uuid().v4(),
          deckId: deckId,
          userId: _userId,
          front: c['front']!,
          back: c['back']!,
          hint: c['hint']!,
        );
        await _db.insertFlashcard(card);
      }
    }
    await loadDecks();
  }
}
