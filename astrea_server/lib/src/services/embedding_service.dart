import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:serverpod/serverpod.dart';

/// Service for generating text embeddings using Google Gemini.
/// Used for semantic search in RAG (Retrieval-Augmented Generation).
class EmbeddingService {
  static const String _model = 'text-embedding-004';
  static const int dimensions = 768; // Gemini text-embedding-004 output size

  static EmbeddingService? _instance;
  late final GenerativeModel _generativeModel;

  EmbeddingService._(String apiKey) {
    _generativeModel = GenerativeModel(
      model: _model,
      apiKey: apiKey,
    );
  }

  /// Lazy singleton that reads API key from Serverpod passwords config or env var.
  static Future<EmbeddingService?> getInstance(Session session) async {
    if (_instance == null) {
      // Try passwords.yaml first, then environment variable
      final apiKey =
          session.passwords['geminiApiKey'] ??
          Platform.environment['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        session.log(
          'Gemini API key not configured - embeddings disabled',
          level: LogLevel.warning,
        );
        return null;
      }
      _instance = EmbeddingService._(apiKey);
    }
    return _instance;
  }

  /// Generate embedding vector for text.
  /// Returns null if generation fails.
  Future<List<double>?> generateEmbedding(String text) async {
    try {
      final content = Content.text(text);
      final result = await _generativeModel.embedContent(content);
      return result.embedding.values;
    } catch (e) {
      // Log error but don't throw - embeddings are optional enhancement
      return null;
    }
  }

  /// Generate embedding for a reminder (title + description).
  Future<List<double>?> generateReminderEmbedding({
    required String title,
    String? description,
  }) async {
    final text = description != null ? '$title $description' : title;
    return generateEmbedding(text);
  }
}
