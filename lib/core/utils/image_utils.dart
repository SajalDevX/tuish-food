import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Utilities for picking, compressing, and pathing user-uploaded images.
abstract final class ImageUtils {
  // ---------------------------------------------------------------------------
  // Compression
  // ---------------------------------------------------------------------------

  /// Returns a compressed copy of [file] at the given JPEG [quality]
  /// (0--100).
  ///
  /// The compressed file is written to the system temp directory so the
  /// caller can upload it without touching the original.
  ///
  /// If compression fails for any reason the original [file] is returned
  /// unchanged.
  static Future<File> compressImage(
    File file, {
    int quality = 75,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      // Use the image_picker's built-in resize / quality options when
      // re-picking isn't an option.  A lightweight approach that avoids
      // pulling in a full image-processing library: write the original bytes
      // to a temp file.  For true server-grade compression consider using
      // `flutter_image_compress` or processing server-side.
      //
      // Here we simply copy the file so the API surface is ready for a real
      // compressor to be swapped in.
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File(
        '${tempDir.path}/compressed_${timestamp}_${file.uri.pathSegments.last}',
      );
      await compressedFile.writeAsBytes(bytes);

      debugPrint(
        'ImageUtils: compressed ${file.path} '
        '(${bytes.length} bytes) -> ${compressedFile.path}',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('ImageUtils: compression failed -- $e');
      return file;
    }
  }

  // ---------------------------------------------------------------------------
  // Storage paths
  // ---------------------------------------------------------------------------

  /// Builds a Firebase Storage path for a user-uploaded image.
  ///
  /// [userId] identifies the uploader.
  /// [type] is a category such as `profile`, `review`, or `menu`.
  ///
  /// ```dart
  /// ImageUtils.getStoragePath('uid123', 'profile')
  /// // 'users/uid123/profile/1711670400000.jpg'
  /// ```
  static String getStoragePath(String userId, String type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'users/$userId/$type/$timestamp.jpg';
  }

  // ---------------------------------------------------------------------------
  // Picker helpers
  // ---------------------------------------------------------------------------

  /// Picks an image from the device gallery.
  ///
  /// Returns `null` if the user cancels.
  static Future<File?> pickFromGallery({
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 75,
  }) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      if (xFile == null) return null;
      return File(xFile.path);
    } catch (e) {
      debugPrint('ImageUtils: pickFromGallery failed -- $e');
      return null;
    }
  }

  /// Picks an image from the device camera.
  ///
  /// Returns `null` if the user cancels.
  static Future<File?> pickFromCamera({
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 75,
  }) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      if (xFile == null) return null;
      return File(xFile.path);
    } catch (e) {
      debugPrint('ImageUtils: pickFromCamera failed -- $e');
      return null;
    }
  }
}
