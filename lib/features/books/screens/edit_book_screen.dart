import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neo_button.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../controllers/book_controller.dart';
import '../models/book_model.dart';
import '../widgets/image_picker_widget.dart';
import 'location_picker_screen.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final _bookForEditProvider =
    FutureProvider.family<BookModel?, String>((ref, id) async {
  final doc =
      await FirebaseFirestore.instance.collection('books').doc(id).get();
  return doc.exists ? BookModel.fromFirestore(doc) : null;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class EditBookScreen extends ConsumerStatefulWidget {
  final String bookId;

  const EditBookScreen({super.key, required this.bookId});

  @override
  ConsumerState<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends ConsumerState<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String _category = 'Fiksi';
  String _condition = 'good';
  File? _newImage; // null = tidak ganti foto
  String _currentImageUrl = '';
  String _cloudinaryPublicId = '';
  double? _lat;
  double? _lng;
  String? _address;
  String? _errorMessage;
  bool _initialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  /// Pre-fill form dari data buku yang sudah ada
  void _prefill(BookModel book) {
    if (_initialized) return;
    _titleCtrl.text = book.title;
    _authorCtrl.text = book.author;
    _descCtrl.text = book.description;
    _contactCtrl.text = book.contactInfo;
    _category = book.category;
    _condition = book.condition.name;
    _currentImageUrl = book.imageUrl;
    _cloudinaryPublicId = book.cloudinaryPublicId;
    _lat = book.latitude;
    _lng = book.longitude;
    _address = book.donorLocation;
    _initialized = true;
  }

  Future<void> _openLocationPicker() async {
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
    if (!_formKey.currentState!.validate()) return;
    if (_address == null) {
      setState(() => _errorMessage = 'Lokasi wajib dipilih.');
      return;
    }

    await ref.read(bookControllerProvider.notifier).updateBook(
          bookId: widget.bookId,
          title: _titleCtrl.text,
          author: _authorCtrl.text,
          category: _category,
          condition: _condition,
          description: _descCtrl.text,
          contactInfo: _contactCtrl.text,
          currentImageUrl: _currentImageUrl,
          cloudinaryPublicId: _cloudinaryPublicId,
          newImageFile: _newImage,
          latitude: _lat,
          longitude: _lng,
          address: _address!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(_bookForEditProvider(widget.bookId));
    final isLoading = ref.watch(bookControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(bookControllerProvider, (_, state) {
      if (state.hasError) {
        setState(() => _errorMessage = state.error.toString());
      } else if (!state.isLoading && !state.hasError && _initialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buku berhasil diperbarui!')),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            border: Border(
              bottom: BorderSide(color: AppColors.black, width: 2.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: PhosphorIcon(
                    PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Edit Buku', style: AppTextStyles.heading2),
              ],
            ),
          ),
        ),
      ),
      body: bookAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('Buku tidak ditemukan.'));
          }
          if (!_initialized) {
            // Pre-fill hanya sekali setelah data tersedia.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _initialized) return;
              setState(() => _prefill(book));
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSurface,
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
                  Text('Foto Buku', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  ImagePickerWidget(
                    imageFile: _newImage,
                    existingUrl: _initialized ? _currentImageUrl : null,
                    onImagePicked: (f) => setState(() => _newImage = f),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
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

                  // ── Kontak ────────────────────────────────────────────────
                  Text('Kontak (opsional)', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoSurface,
                      border: Border.all(
                        color: AppColors.black,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.info(),
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Masukkan WA, IG, atau kontak lainnya agar penerima bisa menghubungimu.',
                            style: AppTextStyles.caption.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  NeoTextField(
                    label: '',
                    controller: _contactCtrl,
                    hint: 'Contoh: wa.me/628123… atau @username_ig',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),

                  // Lokasi
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
                                ? PhosphorIcons.mapPin(PhosphorIconsStyle.fill)
                                : PhosphorIcons.mapPin(),
                            size: 20,
                            color: _address != null
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _address ?? 'Ketuk untuk pilih lokasi',
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
                    label: 'Simpan Perubahan',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
