import '../config/app_config.dart';

enum ImageVariant { thumbnail, feed, full }

/// Builds displayable URLs from the raw object keys posts carry.
///
/// Uploaded images are stored at `images/{owner}/{media}/original`; the
/// processing queue writes `thumbnail.webp` / `feed.webp` / `full.webp` beside
/// it within seconds (backend: media/queue-consumer.ts). Variants are ~10x
/// smaller than the original, so we ask for one and let the image widget fall
/// back to [original] in the brief window before processing finishes.
class MediaUrls {
  MediaUrls._();

  static String original(String ref) {
    if (ref.startsWith('http')) return ref;
    return '${AppConfig.mediaBaseUrl}/$ref';
  }

  static String image(String ref, [ImageVariant variant = ImageVariant.feed]) {
    if (ref.startsWith('http')) return ref;
    if (!ref.endsWith('/original')) return original(ref);
    final base = ref.substring(0, ref.length - '/original'.length);
    return '${AppConfig.mediaBaseUrl}/$base/${variant.name}.webp';
  }
}
