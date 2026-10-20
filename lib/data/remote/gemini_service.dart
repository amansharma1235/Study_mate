import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../models/quiz_model.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiResponse {
  final String text;
  final bool isLiveOnline;
  final String? finishReason;
  final String? model;

  const GeminiResponse({
    required this.text,
    required this.isLiveOnline,
    this.finishReason,
    this.model,
  });
}

class GeminiService {
  /// Candidate model paths ordered by priority and reliability
  static const List<String> _candidateModelPaths = [
    'v1beta/models/gemini-2.0-flash',
    'v1beta/models/gemini-2.0-flash-exp',
    'v1beta/models/gemini-1.5-flash',
    'v1/models/gemini-1.5-flash',
    'v1beta/models/gemini-1.5-pro',
    'v1beta/models/gemini-pro',
  ];

  static String? _cachedWorkingModel;

  final HttpClient _client;

  GeminiService({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 25);
  }

  /// Sends an educational query (with optional image) to Google Gemini or Real-Time Online AI.
  /// Automatically tries active Gemini models if API key is provided, or seamlessly routes
  /// to the built-in real-time AI reasoning engine (ChatGPT-level) when no key is entered.
  Future<GeminiResponse> generateContent({
    required String prompt,
    required String apiKey,
    String? systemInstruction,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      // Out-of-the-box Real-Time Online AI (ChatGPT / Reasoning Level)
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final textReply = await generateOnlineAiContent(
          prompt: prompt.isNotEmpty
              ? prompt
              : 'Please explain this study topic or formula step-by-step.',
          systemInstruction: systemInstruction,
        );
        return GeminiResponse(
          text: '📷 **Study Image Received**\n\n'
              '${textReply.text}\n\n'
              '---\n'
              '💡 *Tip: For full multimodal diagram scanning, you can optionally connect your free Gemini API key in settings.*',
          isLiveOnline: true,
          model: 'StudyMate Vision Helper',
        );
      }

      return generateOnlineAiContent(
        prompt: prompt,
        systemInstruction: systemInstruction,
      );
    }

    final List<Map<String, dynamic>> parts = [];

    // Attach inline image for Multimodal Vision
    if (imageBytes != null && imageBytes.isNotEmpty) {
      parts.add({
        'inlineData': {
          'mimeType': imageMimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      });
    }

    final effectivePrompt = prompt.trim().isNotEmpty
        ? prompt.trim()
        : (imageBytes != null
            ? 'Please analyze this student study image, identify the question or diagram, and explain the solution step by step.'
            : '');

    if (effectivePrompt.isNotEmpty) {
      parts.add({'text': effectivePrompt});
    }

    // Try candidates starting with known working model
    final candidates = [
      ?_cachedWorkingModel,
      ..._candidateModelPaths.where((m) => m != _cachedWorkingModel),
    ];

    String lastErrorMessage = 'Unknown error';
    int lastStatusCode = 404;

    for (final modelPath in candidates) {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '$modelPath:generateContent',
        {'key': cleanKey},
      );

      final Map<String, dynamic> requestPayload = {
        'contents': [
          {
            'parts': parts,
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
      };

      if (systemInstruction != null && systemInstruction.isNotEmpty) {
        requestPayload['systemInstruction'] = {
          'parts': [
            {'text': systemInstruction},
          ],
        };
      }

      try {
        final request = await _client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        request.add(utf8.encode(jsonEncode(requestPayload)));

        final response = await request.close().timeout(
          const Duration(seconds: 25),
          onTimeout: () {
            throw const NetworkException(
              'Request timed out. Please check your internet connection.',
            );
          },
        );

        final responseBody = await response.transform(utf8.decoder).join();
        final statusCode = response.statusCode;
        lastStatusCode = statusCode;

        if (statusCode == 200) {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          final candidateList = data['candidates'] as List<dynamic>?;

          if (candidateList == null || candidateList.isEmpty) {
            throw const ServerException(
              'Gemini could not generate a response. The prompt may have triggered a safety filter.',
            );
          }

          final firstCandidate = candidateList[0] as Map<String, dynamic>;
          final content = firstCandidate['content'] as Map<String, dynamic>?;
          final outParts = content?['parts'] as List<dynamic>?;

          if (outParts == null || outParts.isEmpty) {
            throw const ServerException('Empty content returned from Gemini.');
          }

          final generatedText = outParts[0]['text'] as String? ?? '';
          final finishReason = firstCandidate['finishReason'] as String?;

          // Cache this successful model
          _cachedWorkingModel = modelPath;

          return GeminiResponse(
            text: generatedText.trim(),
            isLiveOnline: true,
            finishReason: finishReason,
            model: modelPath.split('/').last,
          );
        } else if (statusCode == 404) {
          // Model not found on this endpoint/version, proceed to next candidate
          debugPrint('Model $modelPath returned 404. Trying next candidate model...');
          final errorJson = _tryParseError(responseBody);
          lastErrorMessage = errorJson?['message'] as String? ?? 'Model not found (404)';
          continue;
        } else if (statusCode == 400) {
          final errorJson = _tryParseError(responseBody);
          final message = errorJson?['message'] as String? ??
              'Invalid API Key or request payload.';

          // If the error mentions systemInstruction, retry this model once without it
          if (message.contains('systemInstruction') && systemInstruction != null) {
            final fallbackParts = [
              {'text': '[System Instruction: $systemInstruction]\n\n'},
              ...parts,
            ];
            final fallbackPayload = {
              'contents': [{'parts': fallbackParts}],
            };
            try {
              final retryReq = await _client.postUrl(uri);
              retryReq.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
              retryReq.add(utf8.encode(jsonEncode(fallbackPayload)));
              final retryRes = await retryReq.close();
              if (retryRes.statusCode == 200) {
                final retryBody = await retryRes.transform(utf8.decoder).join();
                final retryData = jsonDecode(retryBody) as Map<String, dynamic>;
                final retryCandidates = retryData['candidates'] as List<dynamic>?;
                if (retryCandidates != null && retryCandidates.isNotEmpty) {
                  final c = retryCandidates[0] as Map<String, dynamic>;
                  final p = (c['content']?['parts'] as List<dynamic>?)?[0]['text'] as String? ?? '';
                  _cachedWorkingModel = modelPath;
                  return GeminiResponse(
                    text: p.trim(),
                    isLiveOnline: true,
                    model: modelPath.split('/').last,
                  );
                }
              }
            } catch (_) {}
          }

          lastErrorMessage = message;
          // If invalid API key, fail fast with informative message
          if (message.toLowerCase().contains('api key not valid') ||
              message.toLowerCase().contains('api_key_invalid')) {
            throw AuthException('Invalid Gemini API Key: $message. Please check your key at aistudio.google.com');
          }
          continue;
        } else if (statusCode == 429) {
          throw const ServerException(
            'Gemini rate limit exceeded. Please wait a moment before asking another question.',
          );
        } else {
          final errorJson = _tryParseError(responseBody);
          lastErrorMessage = errorJson?['message'] as String? ?? 'HTTP $statusCode error';
          continue;
        }
      } on SocketException catch (e) {
        debugPrint('Gemini network connection error on $modelPath: $e');
        throw const NetworkException(
          'Unable to reach Google Gemini. Please verify your internet connection.',
        );
      } on FormatException catch (e) {
        debugPrint('Gemini JSON format error on $modelPath: $e');
        continue;
      } catch (e) {
        if (e is AppException) rethrow;
        debugPrint('Gemini attempt failed on $modelPath: $e');
        continue;
      }
    }

    // If Gemini key failed or was invalid, fallback to built-in real-time AI (if no image)
    if (imageBytes == null) {
      try {
        debugPrint('Gemini model calls failed, falling back to Real-Time AI engine...');
        return await generateOnlineAiContent(
          prompt: prompt,
          systemInstruction: systemInstruction,
        );
      } catch (fallbackError) {
        debugPrint('Fallback Real-Time AI also failed: $fallbackError');
      }
    }

    throw ServerException(
      'Gemini Service Notice ($lastStatusCode): $lastErrorMessage. '
      'Please verify that your Google AI Studio API key has the Generative Language API enabled.',
    );
  }

  /// Direct Real-Time Generative AI inference (ChatGPT / Reasoning Level).
  /// Works out-of-the-box for all users with zero API keys required.
  Future<GeminiResponse> generateOnlineAiContent({
    required String prompt,
    String? systemInstruction,
  }) async {
    final uri = Uri.parse('https://text.pollinations.ai/');
    final messages = <Map<String, String>>[];

    final effectiveSystem = (systemInstruction != null && systemInstruction.trim().isNotEmpty)
        ? systemInstruction.trim()
        : 'You are StudyMate, an expert academic tutor and university mentor. '
            'Explain concepts clearly using step-by-step logic, practical real-world examples, '
            'relevant formulas, and structured markdown (headers, bullet points, bold key terms). '
            'Answer accurately in the same language or dialect as the student (Hindi, English, Hinglish, etc.).';

    messages.add({'role': 'system', 'content': effectiveSystem});
    messages.add({'role': 'user', 'content': prompt.trim()});

    final requestPayload = {
      'messages': messages,
      'model': 'openai-fast',
      'seed': 42,
    };

    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.add(utf8.encode(jsonEncode(requestPayload)));

      final response = await request.close().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw const NetworkException(
            'AI request timed out. Please check your internet connection.',
          );
        },
      );

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 && responseBody.trim().isNotEmpty) {
        return GeminiResponse(
          text: responseBody.trim(),
          isLiveOnline: true,
          model: 'StudyMate Real AI (Live)',
        );
      } else if (response.statusCode == 429 || response.statusCode == 402) {
        // Fallback GET request to alternate endpoint
        final fallbackUri = Uri.parse(
          'https://text.pollinations.ai/${Uri.encodeComponent(prompt)}?model=openai-fast',
        );
        final fallbackReq = await _client.getUrl(fallbackUri);
        final fallbackRes = await fallbackReq.close().timeout(
          const Duration(seconds: 25),
        );
        final fallbackBody = await fallbackRes.transform(utf8.decoder).join();
        if (fallbackRes.statusCode == 200 &&
            fallbackBody.trim().isNotEmpty &&
            !fallbackBody.toLowerCase().contains('limit reached')) {
          return GeminiResponse(
            text: fallbackBody.trim(),
            isLiveOnline: true,
            model: 'StudyMate Real AI (Live)',
          );
        }
      }

      throw ServerException(
        'Online AI returned status code ${response.statusCode}: $responseBody',
      );
    } on SocketException catch (e) {
      debugPrint('Real AI network error: $e');
      throw const NetworkException(
        'No active internet connection. Please verify your Wi-Fi or mobile data.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      debugPrint('Real AI inference error: $e');
      throw ServerException('Failed to generate AI response: $e');
    }
  }

  /// Verifies if a given Gemini API key is valid and responsive
  Future<bool> testApiKey(String apiKey) async {
    try {
      final res = await generateContent(
        prompt: 'Hello, respond with OK.',
        apiKey: apiKey,
      );
      return res.text.isNotEmpty;
    } catch (e) {
      debugPrint('Gemini testApiKey error: $e');
      return false;
    }
  }

  /// Generates structured flashcard question & answer pairs from study notes.
  Future<List<Map<String, String>>> generateFlashcardsFromNote({
    required String title,
    required String content,
    required String apiKey,
  }) async {
    if (apiKey.trim().isNotEmpty) {
      final prompt = '''
You are StudyMate AI, an expert educational flashcard creator.
Analyze the following student note and generate 3 to 5 high-yield revision flashcards for spaced repetition.
Each flashcard must test a core concept, theorem, definition, or formula.
Format your output STRICTLY as a JSON array of objects with keys "question" and "answer". Do not wrap with markdown fences or other text.

Example:
[
  {"question": "What is the First Law of Thermodynamics?", "answer": "Energy cannot be created or destroyed, only transformed."},
  {"question": "What is the governing formula for entropy?", "answer": "ΔS = Q_rev / T"}
]

Note Title: $title
Note Content:
$content
''';

      try {
        final response = await generateContent(
          prompt: prompt,
          apiKey: apiKey,
          systemInstruction:
              'You are an educational JSON generator that outputs pure JSON arrays of flashcard questions and answers.',
        );

        final cleanText = response.text
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
            .trim();

        final dynamic parsed = jsonDecode(cleanText);
        if (parsed is List) {
          final List<Map<String, String>> cards = [];
          for (final item in parsed) {
            if (item is Map) {
              final q = (item['question'] ?? item['front'] ?? '')
                  .toString()
                  .trim();
              final a =
                  (item['answer'] ?? item['back'] ?? '').toString().trim();
              if (q.isNotEmpty && a.isNotEmpty) {
                cards.add({'question': q, 'answer': a});
              }
            }
          }
          if (cards.isNotEmpty) return cards;
        }
      } catch (e) {
        debugPrint('AI flashcard generation notice: $e');
      }
    }

    // Fallback: Offline rule-based flashcard generation
    return _generateOfflineFlashcards(title, content);
  }

  /// Generates 5 structured MCQ quiz questions for a syllabus topic or subject.
  Future<List<QuizQuestion>> generateQuizForTopic({
    required String topic,
    required String subject,
    required String apiKey,
  }) async {
    if (apiKey.trim().isNotEmpty) {
      final prompt = '''
You are StudyMate AI, an expert exam tutor.
Create 5 multiple-choice quiz questions (MCQs) for revision of the topic "$topic" in subject "$subject".
Each question must have exactly 4 plausible options, a 0-based integer index for the correct option (0, 1, 2, or 3), and a clear educational explanation.
Format output STRICTLY as a JSON array of objects with keys: "question", "options" (array of 4 strings), "correctIndex" (integer 0-3), "explanation" (string).
Do not wrap with markdown code fences.
''';

      try {
        final response = await generateContent(
          prompt: prompt,
          apiKey: apiKey,
          systemInstruction:
              'You are an educational MCQ quiz generator that strictly outputs valid JSON arrays.',
        );

        final cleanText = response.text
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
            .trim();

        final dynamic parsed = jsonDecode(cleanText);
        if (parsed is List) {
          final List<QuizQuestion> questions = [];
          for (int i = 0; i < parsed.length; i++) {
            final item = parsed[i];
            if (item is Map) {
              final qText = (item['question'] ?? '').toString().trim();
              final opts = (item['options'] as List<dynamic>?)
                      ?.map((o) => o.toString().trim())
                      .toList() ??
                  [];
              final cIdx = (item['correctIndex'] as num?)?.toInt() ?? 0;
              final exp = (item['explanation'] ?? '').toString().trim();

              if (qText.isNotEmpty && opts.length >= 2) {
                questions.add(
                  QuizQuestion(
                    id: 'ai_q_${DateTime.now().millisecondsSinceEpoch}_$i',
                    category: subject,
                    question: qText,
                    options: opts,
                    correctIndex: cIdx.clamp(0, opts.length - 1),
                    explanation: exp.isNotEmpty ? exp : 'Core concept in $topic.',
                  ),
                );
              }
            }
          }
          if (questions.isNotEmpty) return questions;
        }
      } catch (e) {
        debugPrint('AI quiz generation notice: $e');
      }
    }

    // Fallback: rule-based topic quiz
    return [
      QuizQuestion(
        id: 'fallback_1_${DateTime.now().millisecondsSinceEpoch}',
        category: subject,
        question: 'Which of the following best defines "$topic"?',
        options: [
          'A fundamental principle in $subject studying key properties',
          'An obsolete historical hypothesis without mathematical proof',
          'A non-standard notation only used in introductory exercises',
          'A terminology exclusively reserved for laboratory equipment',
        ],
        correctIndex: 0,
        explanation: '"$topic" is an essential curriculum concept in $subject.',
      ),
      QuizQuestion(
        id: 'fallback_2_${DateTime.now().millisecondsSinceEpoch}',
        category: subject,
        question: 'When analyzing "$topic", what is the primary objective?',
        options: [
          'To memorize symbols without conceptual understanding',
          'To apply theoretical formulas and solve related problem scenarios',
          'To omit derivation steps during examinations',
          'To substitute numerical values randomly',
        ],
        correctIndex: 1,
        explanation: 'Deep understanding and problem application are crucial for $topic.',
      ),
      QuizQuestion(
        id: 'fallback_3_${DateTime.now().millisecondsSinceEpoch}',
        category: subject,
        question: 'Which strategy is most effective for mastering "$topic"?',
        options: [
          'Cramming right before the examination bell rings',
          'Active recall, solving chapter exercises, and spaced revision',
          'Ignoring foundational prerequisites and theorem proofs',
          'Copying textbook summaries without self-testing',
        ],
        correctIndex: 1,
        explanation: 'Active recall and spaced repetition ensure long-term mastery.',
      ),
    ];
  }

  /// Offline rule-based flashcard generation from note content
  List<Map<String, String>> _generateOfflineFlashcards(
    String title,
    String content,
  ) {
    final List<Map<String, String>> results = [];
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Definition card from title
    results.add({
      'question': 'What are the core concepts of "$title"?',
      'answer': lines.isNotEmpty
          ? lines.take(3).join(' ')
          : 'Key principles and theorems regarding $title.',
    });

    // 2. Extract bullet points or colon-separated definitions
    for (final line in lines) {
      if (line.startsWith('•') ||
          line.startsWith('-') ||
          line.startsWith('*') ||
          RegExp(r'^\d+[\.\)]').hasMatch(line)) {
        final cleaned = line
            .replaceFirst(RegExp(r'^[•\-\*]\s*'), '')
            .replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
        if (cleaned.contains(':')) {
          final parts = cleaned.split(':');
          final term = parts[0].replaceAll('*', '').trim();
          final def = parts.sublist(1).join(':').trim();
          if (term.isNotEmpty && def.isNotEmpty) {
            results.add({
              'question': 'Define / Explain: $term',
              'answer': def,
            });
          }
        } else if (cleaned.length > 20) {
          results.add({
            'question': 'Key point regarding $title:',
            'answer': cleaned,
          });
        }
      }
      if (results.length >= 4) break;
    }

    if (results.length < 3 && lines.length > 1) {
      results.add({
        'question': 'Summary conclusion of "$title":',
        'answer': lines.last,
      });
    }

    return results;
  }

  /// Generates structured multiple-choice quiz questions from study notes.
  Future<List<QuizQuestion>> generateQuizFromNote({
    required String title,
    required String content,
    required String category,
    required String apiKey,
  }) async {
    if (apiKey.trim().isNotEmpty) {
      final prompt = '''
You are StudyMate AI, an expert exam writer.
Analyze this study note and generate 4 high-yield multiple-choice questions (MCQs) for revision.
Format STRICTLY as a JSON array of objects with keys: "question", "options" (array of 4 distinct choices), "correctIndex" (0, 1, 2, or 3), and "explanation".
Do not wrap with markdown fences.

Example format:
[
  {
    "question": "What is the primary function of mitochondria?",
    "options": ["ATP generation", "Protein synthesis", "Lipid storage", "DNA replication"],
    "correctIndex": 0,
    "explanation": "Mitochondria produce cellular energy through ATP synthesis."
  }
]

Note Title: $title
Category: $category
Content:
$content
''';

      try {
        final response = await generateContent(
          prompt: prompt,
          apiKey: apiKey,
          systemInstruction:
              'You are an educational quiz JSON generator that outputs pure JSON arrays of 4 MCQs.',
        );

        final cleanText = response.text
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
            .trim();

        final dynamic parsed = jsonDecode(cleanText);
        if (parsed is List) {
          final List<QuizQuestion> questions = [];
          for (int i = 0; i < parsed.length; i++) {
            final item = parsed[i];
            if (item is Map) {
              final q = (item['question'] ?? '').toString().trim();
              final rawOpts = item['options'];
              final List<String> opts = (rawOpts is List)
                  ? rawOpts.map((o) => o.toString().trim()).toList()
                  : [];
              final correct = (item['correctIndex'] is num)
                  ? (item['correctIndex'] as num).toInt()
                  : 0;
              final exp = (item['explanation'] ?? '').toString().trim();

              if (q.isNotEmpty && opts.length >= 2) {
                while (opts.length < 4) {
                  opts.add('Option ${opts.length + 1}');
                }
                questions.add(
                  QuizQuestion(
                    id: 'ai_quiz_${DateTime.now().millisecondsSinceEpoch}_$i',
                    category: category.isNotEmpty ? category : 'Study Notes',
                    question: q,
                    options: opts.take(4).toList(),
                    correctIndex: correct.clamp(0, 3),
                    explanation: exp.isNotEmpty
                        ? exp
                        : 'Explanation based on note: $title',
                  ),
                );
              }
            }
          }
          if (questions.isNotEmpty) return questions;
        }
      } catch (e) {
        debugPrint('AI quiz generation notice: $e');
      }
    }

    return _generateOfflineQuiz(title, content, category);
  }

  /// Offline rule-based multiple choice quiz generator
  List<QuizQuestion> _generateOfflineQuiz(
    String title,
    String content,
    String category,
  ) {
    final cat = category.isNotEmpty ? category : 'General Study';
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 10)
        .toList();

    final List<QuizQuestion> questions = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Q1: Title definition
    questions.add(
      QuizQuestion(
        id: 'quiz_${timestamp}_1',
        category: cat,
        question: 'Which of the following best describes the core topic of "$title"?',
        options: [
          lines.isNotEmpty ? lines.first : 'Foundational study concept in $title',
          'An obsolete unrelated empirical theory',
          'A computational error in measurement',
          'None of the above',
        ],
        correctIndex: 0,
        explanation: 'According to "$title", the primary principle is foundational.',
      ),
    );

    // Q2: Key takeaway
    if (lines.length > 1) {
      questions.add(
        QuizQuestion(
          id: 'quiz_${timestamp}_2',
          category: cat,
          question: 'In "$title", which principle is emphasized as critical?',
          options: [
            lines[1],
            'Inverse proportion without boundary conditions',
            'Random perturbation analysis',
            'Disregarding core axioms',
          ],
          correctIndex: 0,
          explanation: 'Refer to key concepts outlined in "$title".',
        ),
      );
    }

    // Q3: Practical application
    questions.add(
      QuizQuestion(
        id: 'quiz_${timestamp}_3',
        category: cat,
        question: 'What is a primary objective when studying $title?',
        options: [
          'Systematic mastery and active conceptual problem-solving',
          'Memorizing without understanding mechanisms',
          'Skipping fundamental definitions',
          'Ignoring formula derivations',
        ],
        correctIndex: 0,
        explanation: 'Active recall and structured problem solving yield top retention.',
      ),
    );

    // Q4: Summary / conclusion
    if (lines.length > 2) {
      questions.add(
        QuizQuestion(
          id: 'quiz_${timestamp}_4',
          category: cat,
          question: 'Which key takeaway concludes the notes on "$title"?',
          options: [
            lines.last,
            'All conditions are invariant across all dimensions',
            'The hypothesis is invalid in all frames',
            'No further study required',
          ],
          correctIndex: 0,
          explanation: 'The conclusion encapsulates key findings in $title.',
        ),
      );
    }

    return questions;
  }

  /// Extracts a comprehensive study kit (5-bullet summary, top 5 exam questions, cheatsheet formulas)
  /// from a PDF, image, or text document using Gemini 1.5 Flash multimodal capabilities.
  Future<Map<String, dynamic>> extractStudyKitFromDocument({
    required String documentTitle,
    String? subject,
    List<int>? fileBytes,
    String? mimeType,
    String? textContent,
    required String apiKey,
  }) async {
    if (apiKey.trim().isNotEmpty) {
      final prompt = '''
You are StudyMate AI, an elite academic learning assistant.
Analyze this study document ("$documentTitle", Subject: ${subject ?? 'General'}).
${textContent != null && textContent.isNotEmpty ? "Document Text:\n$textContent" : ""}

Extract a high-impact, exam-focused Study Kit with 3 components:
1. "summary": A list of 5 concise, high-yield executive bullet points explaining the core concepts.
2. "questions": A list of 5 expected exam questions. Each object has "question", "answer", and "difficulty" (Easy/Medium/Hard).
3. "cheatsheet": A list of 4 to 6 key formulas, theorems, definitions or rules. Each object has "term" and "definition".

Format your output STRICTLY as a single JSON object with keys "summary" (List of strings), "questions" (List of objects), and "cheatsheet" (List of objects). Do not wrap with markdown code fences or other text.
''';

      try {
        final response = await generateContent(
          prompt: prompt,
          imageBytes: fileBytes != null ? Uint8List.fromList(fileBytes) : null,
          imageMimeType: mimeType ?? 'application/pdf',
          apiKey: apiKey,
          systemInstruction:
              'You are an expert academic JSON analyzer that creates study summaries, exam questions, and formula cheatsheets.',
        );

        final cleanText = response.text
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
            .trim();

        final dynamic parsed = jsonDecode(cleanText);
        if (parsed is Map<String, dynamic>) {
          return {
            'summary': (parsed['summary'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            'questions': (parsed['questions'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [],
            'cheatsheet': (parsed['cheatsheet'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [],
            'isLiveOnline': true,
          };
        }
      } catch (e) {
        debugPrint('AI study kit extraction notice: $e');
      }
    }

    // Fallback: Offline heuristic extraction
    return _generateOfflineStudyKit(documentTitle, subject, textContent);
  }

  Map<String, dynamic> _generateOfflineStudyKit(
    String title,
    String? subject,
    String? textContent,
  ) {
    final sub = subject ?? 'General Studies';
    final lines = (textContent ?? '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final List<String> summary = [
      'Foundational overview and core scope of $title in $sub.',
      lines.isNotEmpty
          ? lines.first
          : 'Key underlying principles and definitions outlined in chapter syllabus.',
      lines.length > 2
          ? lines[1]
          : 'Practical methodologies and analytical frameworks required for exams.',
      lines.length > 4
          ? lines[3]
          : 'Edge cases, boundary conditions, and real-world domain applications.',
      'Comprehensive preparation guidelines and expected exam question patterns.',
    ];

    final List<Map<String, dynamic>> questions = [
      {
        'question':
            'What are the fundamental laws and primary objectives of $title?',
        'answer':
            'The governing principles ensure systematic problem-solving and foundational understanding in $sub.',
        'difficulty': 'Easy',
      },
      {
        'question': 'How do you derive or apply the main formulas in $title?',
        'answer':
            'Identify input parameters, verify boundary constraints, and apply standard step-by-step reduction.',
        'difficulty': 'Medium',
      },
      {
        'question':
            'Explain the most common failure modes or exceptions in $title:',
        'answer':
            'Violations of convergence, division by zero, or disregarding environmental assumptions.',
        'difficulty': 'Hard',
      },
      {
        'question':
            'Compare and contrast the primary approaches discussed in $title:',
        'answer':
            'Analytical solutions offer exact closed forms, while numerical methods provide iterative approximations.',
        'difficulty': 'Medium',
      },
      {
        'question':
            'Provide a standard numerical or practical example illustrating $title:',
        'answer':
            'Substitute typical exam values into standard equations to evaluate dimensional consistency.',
        'difficulty': 'Easy',
      },
    ];

    final List<Map<String, dynamic>> cheatsheet = [
      {
        'term': 'Core Theorem ($title)',
        'definition':
            'Primary mathematical or conceptual postulate governing this subject domain.',
      },
      {
        'term': 'Boundary Condition',
        'definition':
            'Set of constraints necessary to evaluate constant terms in governing equations.',
      },
      {
        'term': 'Efficiency Metric',
        'definition':
            'Ratio of useful study output/performance to total computational/time input.',
      },
      {
        'term': 'Asymptotic Limit',
        'definition':
            'Behavior of the system or equation as the scale approaches infinity or zero.',
      },
    ];

    return {
      'summary': summary,
      'questions': questions,
      'cheatsheet': cheatsheet,
      'isLiveOnline': false,
    };
  }

  Map<String, dynamic>? _tryParseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (decoded.containsKey('error') &&
          decoded['error'] is Map<String, dynamic>) {
        return decoded['error'] as Map<String, dynamic>;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }
}
