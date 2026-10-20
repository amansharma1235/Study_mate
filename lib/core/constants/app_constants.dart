class AppConstants {
  /// Default Gemini API Key if configured via environment or hardcoded.
  /// You can pass this at build/run time:
  /// flutter run --dart-define=GEMINI_API_KEY=AIzaSy...
  /// Or paste your key directly in the AI Tutor screen settings.
  static const String defaultGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String geminiApiKeyStorageKey = 'user_gemini_api_key';
}
