import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/widgets/neo_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider); // ← pakai shared provider

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              border: Border.all(
                                color: AppColors.black,
                                width: 2.5,
                              ),
                              boxShadow: const [AppColors.neoShadow],
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.display
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(user.name, style: AppTextStyles.heading1),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textMuted),
                          ),
                          if (user.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.mapPin(),
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.location,
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Stats ────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.black, width: 2.5),
                      bottom: BorderSide(color: AppColors.black, width: 2.5),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCell(
                            value: '${user.donatedCount}',
                            label: 'Buku Didonasi',
                            icon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
                          ),
                        ),
                        Container(width: 2, color: AppColors.black),
                        Expanded(
                          child: _StatCell(
                            value: '${user.receivedCount}',
                            label: 'Buku Diterima',
                            icon:
                                PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Menu ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: PhosphorIcons.pencilSimple(),
                        label: 'Edit Profil',
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        icon: PhosphorIcons.info(),
                        label: 'Tentang DonasiBuku',
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),

                      // Tombol keluar — dengan confirm dialog
                      NeoButton(
                        label: 'Keluar',
                        backgroundColor: AppColors.dangerSurface, // ← fix warna
                        onPressed: () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Keluar dari Akun',
                            message: 'Kamu yakin ingin keluar?',
                            confirmLabel: 'Keluar',
                            cancelLabel: 'Batal',
                            isDestructive: true,
                          );
                          if (ok && context.mounted) {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signOut();
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final PhosphorIconData icon;

  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          PhosphorIcon(icon, size: 22, color: AppColors.black),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.heading1),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: const [AppColors.neoShadowSmall],
        ),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 20, color: AppColors.black),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            PhosphorIcon(
              PhosphorIcons.caretRight(),
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
