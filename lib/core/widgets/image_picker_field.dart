import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/utils/image_utils.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/injection_container.dart';

enum _ImageSource { gallery, camera, remove }

/// A tappable image picker that uploads to Firebase Storage and returns the
/// download URL via [onUploaded].
///
/// - [storagePath] is a lazy callback called only at upload time, so the
///   path can include a fresh timestamp without changing on every rebuild.
/// - [isCircle] renders a circular frame (good for logos); otherwise a
///   rectangle with optional [aspectRatio] (default 1.0).
class ImagePickerField extends ConsumerStatefulWidget {
  const ImagePickerField({
    super.key,
    required this.storagePath,
    required this.onUploaded,
    this.imageUrl,
    this.label = 'Add Image',
    this.isCircle = false,
    this.aspectRatio = 1.0,
  });

  final String Function() storagePath;
  final void Function(String url) onUploaded;
  final String? imageUrl;
  final String label;
  final bool isCircle;
  final double aspectRatio;

  @override
  ConsumerState<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends ConsumerState<ImagePickerField> {
  bool _isUploading = false;

  Future<void> _showSourceSheet() async {
    final hasImage =
        widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    final source = await showModalBottomSheet<_ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.s8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, _ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, _ImageSource.camera),
            ),
            if (hasImage)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: Text(
                  'Remove Image',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(ctx, _ImageSource.remove),
              ),
            const SizedBox(height: AppSizes.s8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    if (source == _ImageSource.remove) {
      widget.onUploaded('');
      return;
    }

    await _pickAndUpload(source);
  }

  Future<void> _pickAndUpload(_ImageSource source) async {
    final File? file = source == _ImageSource.gallery
        ? await ImageUtils.pickFromGallery()
        : await ImageUtils.pickFromCamera();

    if (file == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final storageRef =
          ref.read(firebaseStorageProvider).ref(widget.storagePath());
      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await storageRef.getDownloadURL();
      if (mounted) widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _isUploading ? null : _showSourceSheet,
      child: widget.isCircle
          ? _buildCircle(hasImage)
          : _buildRectangle(hasImage),
    );
  }

  Widget _buildCircle(bool hasImage) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: AppColors.divider,
              width: 1.5,
            ),
          ),
          child: hasImage
              ? ClipOval(
                  child: CachedImage(
                    imageUrl: widget.imageUrl!,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.textHint,
                      size: AppSizes.iconL,
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      widget.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
        if (_isUploading)
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildRectangle(bool hasImage) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          hasImage
              ? CachedImage(
                  imageUrl: widget.imageUrl!,
                  fit: BoxFit.cover,
                  borderRadius: AppSizes.borderRadiusM,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSizes.borderRadiusM,
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.textHint,
                        size: AppSizes.iconL,
                      ),
                      const SizedBox(height: AppSizes.s8),
                      Text(
                        widget.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
          if (_isUploading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: AppSizes.borderRadiusM,
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
