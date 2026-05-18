import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final ValueChanged<File> onImagePicked;

  const ImagePickerWidget({
    super.key,
    this.imageFile,
    required this.onImagePicked,
  });

  Future<bool> _requestPermission(
    BuildContext context,
    ImageSource source,
  ) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    var status = await permission.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      _showPermissionDeniedDialog(context, source);
      return false;
    }

    return false;
  }

  void _showPermissionDeniedDialog(BuildContext context, ImageSource source) {
    final label = source == ImageSource.camera ? 'Kamera' : 'Galeri';
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Izin $label Diperlukan', style: AppTextStyles.heading2),
        content: Text(
          'Izin $label ditolak secara permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SourceSheet(),
    );
    if (source == null || !context.mounted) return;

    // Minta permission dulu
    final granted = await _requestPermission(context, source);
    if (!granted || !context.mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        onImagePicked(File(picked.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal membuka ${source == ImageSource.camera ? "kamera" : "galeri"}: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.black, width: 2.5),
          boxShadow: const [AppColors.neoShadow],
        ),
        child: imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(color: AppColors.black, width: 2),
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
                        size: 16,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.camera(PhosphorIconsStyle.bold),
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tambah Foto Buku',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ketuk untuk kamera atau galeri',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
      ),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2.5),
        boxShadow: const [AppColors.neoShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Pilih Sumber Foto', style: AppTextStyles.heading2),
          ),
          const Divider(height: 1, color: AppColors.black, thickness: 1),
          _SourceTile(
            icon: PhosphorIcons.camera(PhosphorIconsStyle.bold),
            label: 'Kamera',
            source: ImageSource.camera,
          ),
          const Divider(height: 1, color: AppColors.black, thickness: 0.5),
          _SourceTile(
            icon: PhosphorIcons.image(PhosphorIconsStyle.bold),
            label: 'Galeri',
            source: ImageSource.gallery,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final ImageSource source;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 22, color: AppColors.black),
            const SizedBox(width: 16),
            Text(label, style: AppTextStyles.bodyBold),
          ],
        ),
      ),
    );
  }
}
