import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neo_button.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../controllers/book_controller.dart';
import '../widgets/image_picker_widget.dart';
import 'location_picker_screen.dart'; // LocationResult & LocationPickerScreen ada di sini

class DonateBookScreen extends ConsumerStatefulWidget {
  const DonateBookScreen({super.key});

  @override
  ConsumerState<DonateBookScreen> createState() => _DonateBookScreenState();
}

class _DonateBookScreenState extends ConsumerState<DonateBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  File? _imageFile;
  String _category = 'Fiksi';
  String _condition = 'good';
  double? _lat;
  double? _lng;
  String? _address;
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    // Pakai Navigator.push langsung karena ini full-screen tanpa bottom nav
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _address = result.address;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_imageFile == null) {
      setState(() => _errorMessage = 'Foto buku wajib ditambahkan.');
      return;
    }
    if (_lat == null || _address == null) {
      setState(() => _errorMessage = 'Lokasi buku wajib dipilih.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    await ref.read(bookControllerProvider.notifier).donateBook(
          title: _titleCtrl.text,
          author: _authorCtrl.text,
          category: _category,
          condition: _condition,
          description: _descCtrl.text,
          imageFile: _imageFile!,
          latitude: _lat!,
          longitude: _lng!,
          address: _address!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(bookControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(bookControllerProvider, (_, state) {
      if (state.hasError) {
        setState(() => _errorMessage = state.error.toString());
      } else if (!state.isLoading && !state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buku berhasil didonasikan!')),
        );
        context.go('/');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.heart(PhosphorIconsStyle.bold),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text('Donasikan Buku', style: AppTextStyles.heading1),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.black, thickness: 2.5),

          // ── Form ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.danger, width: 2),
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.warningCircle(),
                              size: 16,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Foto
                    Text('Foto Buku *', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    ImagePickerWidget(
                      imageFile: _imageFile,
                      onImagePicked: (f) => setState(() => _imageFile = f),
                    ),
                    const SizedBox(height: 20),

                    NeoTextField(
                      label: 'Judul Buku *',
                      controller: _titleCtrl,
                      hint: 'Misal: Laskar Pelangi',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Judul tidak boleh kosong.'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    NeoTextField(
                      label: 'Pengarang *',
                      controller: _authorCtrl,
                      hint: 'Misal: Andrea Hirata',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pengarang tidak boleh kosong.'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Kategori
                    Text('Kategori *', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.black, width: 2.5),
                        ),
                        boxShadow: [AppColors.neoShadow],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          style: AppTextStyles.body,
                          items: AppConstants.bookCategories
                              .where((c) => c != 'Semua')
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _category = v ?? _category),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kondisi
                    Text('Kondisi Buku *', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Row(
                      children: AppConstants.conditionLabels.entries.map((e) {
                        final selected = _condition == e.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _condition = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.white,
                                border: Border.all(
                                  color: AppColors.black,
                                  width: selected ? 2.5 : 1.5,
                                ),
                                boxShadow: selected
                                    ? const [AppColors.neoShadowSmall]
                                    : null,
                              ),
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    NeoTextField(
                      label: 'Deskripsi',
                      controller: _descCtrl,
                      hint: 'Kondisi detail, edisi, catatan, dll.',
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 20),

                    // Lokasi picker
                    Text('Lokasi Buku *', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(
                            color: _address == null
                                ? AppColors.black
                                : AppColors.success,
                            width: 2.5,
                          ),
                          boxShadow: const [AppColors.neoShadow],
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(
                              _address != null
                                  ? PhosphorIcons.mapPin(
                                      PhosphorIconsStyle.fill)
                                  : PhosphorIcons.mapPin(),
                              size: 20,
                              color: _address != null
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _address ?? 'Ketuk untuk pilih lokasi di peta',
                                style: AppTextStyles.body.copyWith(
                                  color: _address != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PhosphorIcon(
                              PhosphorIcons.arrowRight(),
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    NeoButton(
                      label: 'Donasikan Sekarang',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
