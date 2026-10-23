import 'dart:collection';
import 'package:flutter/foundation.dart';

class TrackedError {
  final DateTime timestamp;
  final String message;
  final String? stackTrace;
  final String? context;
  final bool isFatal;

  TrackedError({
    DateTime? timestamp,
    required this.message,
    this.stackTrace,
    this.context,
    this.isFatal = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'context': context,
      'isFatal': isFatal,
      'stackTrace': stackTrace,
    };
  }
}

/// Centralized Error Tracking Service for StudyMate.
/// Captures unhandled Flutter framework errors, async exceptions, and provides diagnostic reports.
class ErrorTrackingService {
  ErrorTrackingService._();
  static final ErrorTrackingService instance = ErrorTrackingService._();

  static const int _maxErrorsToRetain = 50;
  final ListQueue<TrackedError> _errorQueue = ListQueue<TrackedError>();

  List<TrackedError> get recentErrors => _errorQueue.toList().reversed.toList();
  int get errorCount => _errorQueue.length;

  /// Initializes global error hooks.
  void init() {
    // 1. Flutter framework layout/rendering errors
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details);
      if (originalOnError != null) {
        originalOnError(details);
      }
    };

    // 2. Unhandled asynchronous / platform dispatcher errors
    final originalPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(
        error,
        stack,
        context: 'PlatformDispatcher.onError',
        isFatal: true,
      );
      if (originalPlatformOnError != null) {
        return originalPlatformOnError(error, stack);
      }
      return true; // Mark as handled gracefully
    };
  }

  /// Records a caught or framework-level error.
  void recordError(
    Object error,
    StackTrace? stack, {
    String? context,
    bool isFatal = false,
  }) {
    final entry = TrackedError(
      message: error.toString(),
      stackTrace: stack?.toString(),
      context: context,
      isFatal: isFatal,
    );

    if (_errorQueue.length >= _maxErrorsToRetain) {
      _errorQueue.removeFirst();
    }
    _errorQueue.addLast(entry);

    debugPrint('[ErrorTracking] ⚠️ Recorded error: ${entry.message} (Context: $context)');
  }

  /// Specialized recorder for Flutter framework details.
  void recordFlutterError(FlutterErrorDetails details) {
    recordError(
      details.exception,
      details.stack,
      context: details.context?.toString() ?? 'Flutter Framework',
      isFatal: false,
    );
  }

  /// Clears in-memory error logs.
  void clear() {
    _errorQueue.clear();
  }

  /// Formats all captured logs into a clean, shareable diagnostic text.
  String generateDiagnosticReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== StudyMate Diagnostics & Error Report ===');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Platform: ${defaultTargetPlatform.name}');
    buffer.writeln('Total Captured Issues: ${_errorQueue.length}');
    buffer.writeln('============================================\n');

    if (_errorQueue.isEmpty) {
      buffer.writeln('✅ System Healthy: No unhandled errors or exceptions captured.');
    } else {
      for (int i = 0; i < recentErrors.length; i++) {
        final err = recentErrors[i];
        buffer.writeln('[#${i + 1}] ${err.timestamp.toIso8601String()}');
        buffer.writeln('Context: ${err.context ?? "General"} | Fatal: ${err.isFatal}');
        buffer.writeln('Message: ${err.message}');
        if (err.stackTrace != null && err.stackTrace!.isNotEmpty) {
          final lines = err.stackTrace!.split('\n').take(6).join('\n');
          buffer.writeln('Stack: $lines');
        }
        buffer.writeln('--------------------------------------------');
      }
    }

    return buffer.toString();
  }
}
