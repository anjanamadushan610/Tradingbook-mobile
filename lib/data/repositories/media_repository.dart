import 'dart:io';

import '../../core/network/api_client.dart';

/// Post media goes straight to storage: the API hands out presigned targets
/// and the bytes never pass through the Worker.
class MediaRepository {
  MediaRepository(this._api);

  final ApiClient _api;

  /// Uploads [files] (all JPEG — the picker re-encodes) for draft [postId].
  /// The upload-url call also writes the real object keys onto the post.
  Future<void> uploadPostImages({
    required String postId,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    if (files.isEmpty) return;
    final sizes = await Future.wait(files.map((f) => f.length()));
    final largest = sizes.reduce((a, b) => a > b ? a : b);
    final json = await _api.post<Json>(
      '/api/media/image/upload-url',
      body: {
        'postId': postId,
        'contentType': 'image/jpeg',
        'fileSizeBytes': largest,
        'count': files.length,
      },
    );
    final targets = (json['items'] as List).cast<Json>();
    final progress = List<double>.filled(files.length, 0);
    await Future.wait([
      for (var i = 0; i < files.length; i++)
        _api.putBytesToUrl(
          targets[i]['uploadUrl'] as String,
          file: files[i],
          headers: {
            'Content-Type': 'image/jpeg',
            ...?(targets[i]['headers'] as Map?)?.cast<String, String>(),
          },
          onProgress: (p) {
            progress[i] = p;
            onProgress?.call(progress.reduce((a, b) => a + b) / files.length);
          },
        ),
    ]);
  }

  /// Video goes to Cloudflare Stream via a direct-creator-upload URL
  /// (multipart POST). Only reachable when AppConfig.videoUploadsEnabled.
  Future<void> uploadPostVideo({
    required String postId,
    required File file,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    final json = await _api.post<Json>(
      '/api/media/video/upload-url',
      body: {
        'postId': postId,
        'contentType': contentType,
        'fileSizeBytes': await file.length(),
      },
    );
    await _api.postMultipartToUrl(
      json['uploadUrl'] as String,
      file: file,
      onProgress: onProgress,
    );
  }
}
