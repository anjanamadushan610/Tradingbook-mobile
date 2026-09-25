import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';
import '../models/moderation.dart';
import '../models/post.dart';

/// Platform moderation (moderator/admin only) and user reports (anyone).
class ModerationRepository {
  ModerationRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Post>> queue({String status = 'all', String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/moderation/queue',
      query: {'status': status, 'cursor': cursor, 'limit': 20},
    );
    return Paginated.fromJson(json, Post.fromJson);
  }

  Future<void> approve(String postId) =>
      _api.post<Json>('/api/moderation/approve', body: {'postId': postId});

  Future<void> reject(String postId, String reason) => _api.post<Json>(
        '/api/moderation/reject',
        body: {'postId': postId, 'reason': reason},
      );

  Future<BulkActionResult> bulkApprove(List<String> postIds) async =>
      BulkActionResult.fromJson(await _api.post<Json>(
        '/api/moderation/bulk-approve',
        body: {'postIds': postIds},
      ));

  Future<BulkActionResult> bulkReject(List<String> postIds, String reason) async =>
      BulkActionResult.fromJson(await _api.post<Json>(
        '/api/moderation/bulk-reject',
        body: {'postIds': postIds, 'reason': reason},
      ));

  Future<Paginated<AuditEntry>> audit({String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/moderation/audit',
      query: {'cursor': cursor, 'limit': 30},
    );
    // The audit route answers { entries, nextCursor } rather than { items }.
    return Paginated(
      items: (json['entries'] as List? ?? json['items'] as List? ?? const [])
          .cast<Json>()
          .map(AuditEntry.fromJson)
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  // --- user reports (Play UGC policy: every user can flag content) ---

  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) =>
      _api.post<Json>('/api/reports', body: {
        'targetType': target.name,
        'targetId': targetId,
        'reason': reason.wire,
        if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      });

  Future<Paginated<ContentReport>> reports({String status = 'open', String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/moderation/reports',
      query: {'status': status, 'cursor': cursor, 'limit': 30},
    );
    return Paginated.fromJson(json, ContentReport.fromJson);
  }

  Future<void> resolveReport(String reportId, {required String status}) => _api.post<Json>(
        '/api/moderation/reports/$reportId/resolve',
        body: {'status': status},
      );
}
