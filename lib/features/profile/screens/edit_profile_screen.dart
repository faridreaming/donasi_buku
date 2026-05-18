import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neo_button.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _isLoading = false;
  bool _initialized = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nama tidak boleh kosong.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'name': name, 'location': location});

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    // Pre-fill sekali saat data tersedia
    userAsync.whenData((user) {
      if (user != null && !_initialized) {
        _nameCtrl.text = user.name;
        _locationCtrl.text = user.location;
        _initialized = true;
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
                Text('Edit Profil', style: AppTextStyles.heading2),
              ],
            ),
          ),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    border: Border.all(color: AppColors.black, width: 2.5),
                    boxShadow: const [AppColors.neoShadow],
                  ),
                  child: Center(
                    child: Text(
                      _nameCtrl.text.isNotEmpty
                          ? _nameCtrl.text[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.display
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Error
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSurface,
                    border: Border.all(color: AppColors.danger, width: 2),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              NeoTextField(
                label: 'Nama Lengkap',
                controller: _nameCtrl,
                hint: 'Nama kamu',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              NeoTextField(
                label: 'Kota / Lokasi',
                controller: _locationCtrl,
                hint: 'Misal: Medan, Sumatera Utara',
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 28),

              NeoButton(
                label: 'Simpan Perubahan',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
