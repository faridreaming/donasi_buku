import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

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
                Expanded(
                  child: Text('Notifikasi', style: AppTextStyles.heading2),
                ),
                // Tandai semua sudah dibaca
                TextButton(
                  onPressed: () {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) markAllRead(uid);
                  },
                  child: Text(
                    'Baca Semua',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: notifsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.bell(),
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada notifikasi.',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (_, i) => _NotifCard(notif: notifs[i]),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;

  const _NotifCard({required this.notif});

  PhosphorIconData get _icon => switch (notif.type) {
        NotifType.requestReceived =>
          PhosphorIcons.bell(PhosphorIconsStyle.fill),
        NotifType.requestApproved =>
          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        NotifType.requestRejected =>
          PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
        NotifType.bookCompleted =>
          PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!notif.isRead) markNotificationRead(notif.id);
        if (notif.bookId != null) {
          context.push('/book/${notif.bookId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.white
              : AppColors.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: notif.isRead ? const Color(0xFFDDDDDD) : AppColors.black,
            width: notif.isRead ? 1.5 : 2.5,
          ),
          boxShadow: notif.isRead ? null : const [AppColors.neoShadowSmall],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon accent
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: notif.accentColor.withValues(alpha: 0.2),
              child: Center(
                child: PhosphorIcon(
                  _icon,
                  size: 20,
                  color: notif.accentColor == AppColors.info ||
                          notif.accentColor == const Color(0xFF7BC67E)
                      ? AppColors.black
                      : notif.accentColor,
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: AppTextStyles.bodyBold.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: AppTextStyles.caption.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeago.format(notif.createdAt, locale: 'id'),
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
