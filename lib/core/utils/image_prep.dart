import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picking and preparing images for upload.
///
/// Every image leaves the device as a JPEG, downscaled and with EXIF removed:
///  * post uploads are presigned for ONE content type per batch, so a mixed
///    PNG/HEIC/JPEG selection must be normalised anyway;
///  * phone photos carry GPS coordinates in EXIF — a trader posting a chart
///    screenshot shouldn't also publish where they live;
///  * a 12 MB camera original has no business going over a mobile link.
class ImagePrep {
  ImagePrep._();

  static final _picker = ImagePicker();

  static Future<List<File>> pickMany({int limit = 10}) async {
    final picked = await _picker.pickMultiImage(limit: limit);
    return _prepareAll(picked.take(limit).toList());
  }

  static Future<File?> pickOne({ImageSource source = ImageSource.gallery, int maxSide = 2048}) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;
    return prepare(picked, maxSide: maxSide);
  }

  static Future<List<File>> _prepareAll(List<XFile> files) async {
    final out = <File>[];
    for (final f in files) {
      out.add(await prepare(f));
    }
    return out;
  }

  static Future<File> prepare(XFile file, {int maxSide = 2048}) async {
    final dir = await getTemporaryDirectory();
    final target = '${dir.path}/tb_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      target,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    return File(result?.path ?? file.path);
  }
}
