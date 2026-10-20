import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../data/models/flashcard_model.dart';
import '../../data/remote/firebase_service.dart';
import '../auth/auth_controller.dart';

final flashcardDecksProvider =
    StateNotifierProvider<
      FlashcardDecksController,
      AsyncValue<List<FlashcardDeckModel>>
    >((ref) {
      final db = ref.watch(appDatabaseProvider);
      final user = ref.watch(currentProfileProvider);
      final firebaseService = ref.watch(firebaseServiceProvider);
      final userId = user?.uid ?? 'guest';
      return FlashcardDecksController(db, userId, firebaseService: firebaseService);
    });

class LeitnerDeckMastery {
  final int box1Learning; // intervalDays <= 1
  final int box2Review; // intervalDays 2-3
  final int box3Consolidating; // intervalDays 4-14
  final int box4Mastered; // intervalDays > 14
  final int totalCards;
  final int dueToday;
  final int retentionPercentage;

  const LeitnerDeckMastery({
    required this.box1Learning,
    required this.box2Review,
    required this.box3Consolidating,
    required this.box4Mastered,
    required this.totalCards,
    required this.dueToday,
    required this.retentionPercentage,
  });

  factory LeitnerDeckMastery.fromCards(List<FlashcardModel> cards) {
    if (cards.isEmpty) {
      return const LeitnerDeckMastery(
        box1Learning: 0,
        box2Review: 0,
        box3Consolidating: 0,
        box4Mastered: 0,
        totalCards: 0,
        dueToday: 0,
        retentionPercentage: 0,
      );
    }

    int b1 = 0;
    int b2 = 0;
    int b3 = 0;
    int b4 = 0;
    int due = 0;
    final now = DateTime.now();

    for (final c in cards) {
      if (c.nextReviewDate.isBefore(now) || c.repetitionNumber == 0) {
        due++;
      }
      if (c.intervalDays <= 1) {
        b1++;
      } else if (c.intervalDays <= 3) {
        b2++;
      } else if (c.intervalDays <= 14) {
        b3++;
      } else {
        b4++;
      }
    }

    final score = (b4 * 100 + b3 * 75 + b2 * 45 + b1 * 15) / (cards.length * 100);
    final retention = (score * 100).round().clamp(0, 100);

    return LeitnerDeckMastery(
      box1Learning: b1,
      box2Review: b2,
      box3Consolidating: b3,
      box4Mastered: b4,
      totalCards: cards.length,
      dueToday: due,
      retentionPercentage: retention,
    );
  }
}

final deckMasteryProvider =
    FutureProvider.family<LeitnerDeckMastery, String>((ref, deckId) async {
  final db = ref.watch(appDatabaseProvider);
  final cards = await db.getFlashcards(deckId);
  return LeitnerDeckMastery.fromCards(cards);
});

class FlashcardDecksController
    extends StateNotifier<AsyncValue<List<FlashcardDeckModel>>> {
  final AppDatabase _db;
  final String _userId;
  final FirebaseService? firebaseService;

  FlashcardDecksController(
    this._db,
    this._userId, {
    this.firebaseService,
  }) : super(const AsyncValue.loading()) {
    loadDecks();
  }

  Future<void> loadDecks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final local = await _db.getFlashcardDecks(_userId);
      final fb = firebaseService;
      if (fb != null &&
          fb.isConfigured &&
          _userId.isNotEmpty &&
          _userId != 'guest') {
        _syncRemoteDecks().catchError((e) {
          debugPrint('Flashcards remote sync notice: $e');
        });
      }
      return local;
    });
  }

  Future<void> _syncRemoteDecks() async {
    final col = firebaseService?.getUserCollection(_userId, 'flashcard_decks');
    if (col == null) return;
    final snap = await col.get();
    for (final doc in snap.docs) {
      final deck = FlashcardDeckModel.fromMap(doc.data());
      await _db.insertFlashcardDeck(deck);
    }
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

    final fb = firebaseService;
    if (fb != null &&
        fb.isConfigured &&
        _userId.isNotEmpty &&
        _userId != 'guest') {
      try {
        final col = fb.getUserCollection(
          _userId,
          'flashcard_decks',
        );
        await col?.doc(deck.id).set(deck.toMap());
      } catch (e) {
        debugPrint('Cloud deck upload notice: $e');
      }
    }

    await loadDecks();
  }

  Future<void> deleteDeck(String id) async {
    await _db.deleteFlashcardDeck(id);

    final fb = firebaseService;
    if (fb != null &&
        fb.isConfigured &&
        _userId.isNotEmpty &&
        _userId != 'guest') {
      try {
        final col = fb.getUserCollection(
          _userId,
          'flashcard_decks',
        );
        await col?.doc(id).delete();
      } catch (_) {}
    }

    await loadDecks();
  }

  Future<FlashcardDeckModel> getOrCreateDeckForSubject({
    required String subject,
    required String title,
  }) async {
    final decks = state.value ?? await _db.getFlashcardDecks(_userId);
    final existing = decks
        .where((d) => d.title.trim().toLowerCase() == title.trim().toLowerCase())
        .firstOrNull;
    if (existing != null) return existing;

    final newDeck = FlashcardDeckModel(
      id: const Uuid().v4(),
      userId: _userId,
      title: title.trim(),
      subject: subject.trim(),
      description: 'Auto-generated flashcards from study notes',
      colorHex: '#6258E8',
      cardCount: 0,
    );

    await _db.insertFlashcardDeck(newDeck);
    await loadDecks();
    return newDeck;
  }

  Future<int> addMultipleCardsToDeck({
    required String deckId,
    required List<Map<String, String>> cards,
  }) async {
    int count = 0;
    for (final c in cards) {
      final front = c['question'] ?? c['front'] ?? '';
      final back = c['answer'] ?? c['back'] ?? '';
      if (front.trim().isNotEmpty && back.trim().isNotEmpty) {
        await addCardToDeck(
          deckId: deckId,
          front: front.trim(),
          back: back.trim(),
        );
        count++;
      }
    }
    return count;
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

    final fb = firebaseService;
    if (fb != null &&
        fb.isConfigured &&
        _userId.isNotEmpty &&
        _userId != 'guest') {
      try {
        final col = fb.getUserCollection(_userId, 'flashcards');
        await col?.doc(card.id).set(card.toMap());
      } catch (_) {}
    }

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
            'front':
                'What is the time complexity of searching in a Balanced Binary Search Tree (AVL/Red-Black)?',
            'back': 'O(log n) in both average and worst cases.',
            'hint': 'Logarithmic based on tree height.',
          },
          {
            'front': 'What is the difference between BFS and DFS?',
            'back':
                'BFS explores level-by-level using a Queue (FIFO).\nDFS explores as deep as possible using a Stack (LIFO) or recursion.',
            'hint': 'Queue vs Stack',
          },
          {
            'front': 'What are the 4 fundamental pillars of OOP?',
            'back':
                '1. Encapsulation\n2. Abstraction\n3. Inheritance\n4. Polymorphism',
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
            'back':
                'Force equals the rate of change of momentum: F = ma (when mass is constant).',
            'hint': 'F = ?',
          },
          {
            'front': 'What is the Work-Energy Theorem?',
            'back':
                'Net work done on an object equals the change in its kinetic energy: W_net = ΔKE.',
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
