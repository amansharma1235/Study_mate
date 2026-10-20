import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/core/errors/app_exception.dart';
import 'package:study_mate/data/models/note_model.dart';
import 'package:study_mate/data/remote/gemini_service.dart';

void main() {
  group('GeminiService Unit Tests', () {
    test('Throws ValidationException if API key is blank', () async {
      final service = GeminiService();
      expect(
        () => service.generateContent(
          prompt: 'Explain Newton third law',
          apiKey: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('GeminiResponse holds live indicator and text correctly', () {
      const resp = GeminiResponse(
        text: 'Newton third law states action equals reaction.',
        isLiveOnline: true,
        finishReason: 'STOP',
      );

      expect(resp.isLiveOnline, isTrue);
      expect(resp.text, contains('Newton third law'));
      expect(resp.finishReason, 'STOP');
    });

    test('generateFlashcardsFromNote generates cards with offline fallback', () async {
      final service = GeminiService();
      final cards = await service.generateFlashcardsFromNote(
        title: 'Operating Systems Virtual Memory',
        content: '• Paging: Divides memory into fixed-size frames.\n• TLB: Translation Lookaside Buffer caches page entries.\n• Thrashing: Occurs when excessive paging leads to constant disk I/O.',
        apiKey: '', // Empty key triggers resilient offline extractor
      );

      expect(cards, isNotEmpty);
      expect(cards.length, greaterThanOrEqualTo(2));
      expect(cards.any((c) => c['question']!.contains('Paging') || c['question']!.contains('Operating Systems')), isTrue);
    });
  });

  group('Note Metrics & Integrity Unit Tests', () {
    test('Calculates word count and reading time correctly', () {
      const content =
          'Distributed consensus ensures all nodes agree on a single data value in distributed systems.';
      final words = content.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
      expect(words, 14);

      final readingMinutes = (words / 200).ceil();
      expect(readingMinutes, 1);
    });

    test('NoteModel retains pinned and category state across copyWith', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'n-1',
        userId: 'u-1',
        title: 'Cache Locality',
        content: 'Spatial and temporal locality',
        category: 'Computer Science',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      );

      final pinned = note.copyWith(isPinned: true);
      expect(pinned.isPinned, isTrue);
      expect(pinned.title, note.title);

      final recategorized = pinned.copyWith(category: 'Revision');
      expect(recategorized.category, 'Revision');
      expect(recategorized.isPinned, isTrue);
    });
  });
}
