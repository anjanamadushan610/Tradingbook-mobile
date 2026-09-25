import 'package:equatable/equatable.dart';

import 'json_utils.dart';

class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.postId,
    required this.moderatorId,
    required this.action,
    this.reason,
    required this.stage,
    required this.previousStatus,
    required this.newStatus,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String moderatorId;

  /// approved | rejected
  final String action;
  final String? reason;

  /// single | platform | group
  final String stage;
  final String previousStatus;
  final String newStatus;
  final DateTime createdAt;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: readString(json['id']),
        postId: readString(json['postId']),
        moderatorId: readString(json['moderatorId']),
        action: readString(json['action']),
        reason: readNullableString(json['reason']),
        stage: readString(json['stage']),
        previousStatus: readString(json['previousStatus']),
        newStatus: readString(json['newStatus']),
        createdAt: readTime(json['createdAt']),
      );

  @override
  List<Object?> get props => [id];
}

class BulkActionResult {
  const BulkActionResult({
    required this.total,
    required this.succeeded,
    required this.failed,
  });

  final int total;
  final int succeeded;
  final int failed;

  factory BulkActionResult.fromJson(Map<String, dynamic> json) =>
      BulkActionResult(
        total: readInt(json['total']),
        succeeded: readInt(json['succeeded']),
        failed: readInt(json['failed']),
      );
}

/// Why a user is reporting something — sent as `reason`.
enum ReportReason {
  spam('spam', 'Spam or misleading'),
  scam('scam', 'Scam or fraud'),
  harassment('harassment', 'Harassment or hate'),
  financialAdvice('financial_misconduct', 'Pump-and-dump / market manipulation'),
  inappropriate('inappropriate', 'Nudity or inappropriate content'),
  violence('violence', 'Violence or threats'),
  impersonation('impersonation', 'Impersonation'),
  other('other', 'Something else');

  const ReportReason(this.wire, this.label);
  final String wire;
  final String label;
}

enum ReportTarget { post, comment, user, group, page }

class ContentReport extends Equatable {
  const ContentReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reporterId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String reporterId;
  final String reason;
  final String? details;

  /// open | resolved | dismissed
  final String status;
  final DateTime createdAt;

  factory ContentReport.fromJson(Map<String, dynamic> json) => ContentReport(
        id: readString(json['id']),
        targetType: readString(json['targetType']),
        targetId: readString(json['targetId']),
        reporterId: readString(json['reporterId']),
        reason: readString(json['reason']),
        details: readNullableString(json['details']),
        status: readString(json['status'], 'open'),
        createdAt: readTime(json['createdAt']),
      );

  @override
  List<Object?> get props => [id, status];
}
