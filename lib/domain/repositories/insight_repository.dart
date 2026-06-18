import '../models/insight.dart';

/// Stores the most recently generated insights locally so the UI can render
/// them without re-running the engine on every frame.
abstract interface class InsightRepository {
  Stream<List<Insight>> watchInsights(String userId);

  Future<List<Insight>> getInsights(String userId);

  /// Replaces the stored insight set for a user (the engine returns the top N).
  Future<void> replaceInsights(String userId, List<Insight> insights);

  Future<void> deleteInsight(String id);

  Future<void> clear(String userId);
}
