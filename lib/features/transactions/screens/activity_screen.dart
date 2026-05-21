import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neo_button.dart';
import '../../books/models/book_model.dart';
import '../../books/controllers/book_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';
import '../../../core/utils/dialogs.dart';
import '../../profile/models/user_model.dart';

// ── Provider untuk fetch informasi receiver ─────────────────────────────────
final _receiverInfoProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.clockCounterClockwise(
                            PhosphorIconsStyle.bold,
                          ),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text('Aktivitas', style: AppTextStyles.heading1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tab bar
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.black, width: 2),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: const BoxDecoration(
                        color: AppColors.black,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.black,
                      labelStyle: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: AppTextStyles.label,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Donasiku'),
                        Tab(text: 'Permintaanku'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.black, thickness: 2),

          // ── Tab views ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _DonatedTab(),
                _RequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Donasiku ──────────────────────────────────────────────────────────

class _DonatedTab extends ConsumerWidget {
  const _DonatedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(myDonatedBooksProvider);

    return snap.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.black),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (querySnap) {
        if (querySnap is! QuerySnapshot) {
          return const Center(child: Text('Format data tidak sesuai.'));
        }
        final books = (querySnap).docs.map(BookModel.fromFirestore).toList();

        if (books.isEmpty) {
          return _EmptyState(
            icon: PhosphorIcons.heart(),
            message: 'Kamu belum mendonasikan buku apapun.',
            action: 'Donasikan Buku',
            onTap: () => context.go('/donate'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (_, i) => _DonatedBookCard(book: books[i]),
        );
      },
    );
  }
}

class _DonatedBookCard extends ConsumerStatefulWidget {
  final BookModel book;
  const _DonatedBookCard({required this.book});

  @override
  ConsumerState<_DonatedBookCard> createState() => _DonatedBookCardState();
}

class _DonatedBookCardState extends ConsumerState<_DonatedBookCard> {
  bool _expanded = false;

  Color get _statusColor => switch (widget.book.status) {
        BookStatus.available => AppColors.success,
        BookStatus.reserved => AppColors.info,
        BookStatus.donated => const Color(0xFF7BC67E),
      };

  String get _statusLabel => switch (widget.book.status) {
        BookStatus.available => 'Tersedia',
        BookStatus.reserved => 'Dipesan',
        BookStatus.donated => 'Selesai',
      };

  Future<void> _confirmDelete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus Buku',
      message:
          'Buku "${widget.book.title}" akan dihapus beserta semua permintaan yang masuk. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Ya, Hapus',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    await ref.read(bookControllerProvider.notifier).deleteBook(widget.book.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku berhasil dihapus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(incomingRequestsProvider(widget.book.id));
    final isDeleting = ref.watch(bookControllerProvider).isLoading;
    final canManage = widget.book.status == BookStatus.available;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2.5),
        boxShadow: const [AppColors.neoShadow],
      ),
      child: Column(
        children: [
          // ── Book row ──────────────────────────────────────────
          GestureDetector(
            onTap: canManage
                ? () => setState(() => _expanded = !_expanded)
                : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Cover
                  SizedBox(
                    width: 56,
                    height: 70,
                    child: widget.book.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.book.imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.background,
                            child: Center(
                              child: PhosphorIcon(
                                PhosphorIcons.book(),
                                size: 22,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: AppTextStyles.bodyBold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.book.author,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: _statusColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _statusLabel,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Request count badge
                            requestsAsync
                                .whenData((list) => list.length)
                                .maybeWhen(
                                  data: (dataCount) => dataCount > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            border: Border.all(
                                              color: AppColors.black,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            '$dataCount permintaan',
                                            style:
                                                AppTextStyles.caption.copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  orElse: () => const SizedBox.shrink(),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tampilkan ikon accordion hanya jika status available
                  if (canManage)
                    PhosphorIcon(
                      _expanded
                          ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold)
                          : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                      size: 16,
                      color: AppColors.black,
                    ),
                ],
              ),
            ),
          ),

          // ── Edit / Delete actions (hanya jika status available) ──
          if (canManage)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE8E8E8), width: 1),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Edit
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push('/book/edit/${widget.book.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PhosphorIcon(
                                PhosphorIcons.pencilSimple(),
                                size: 15,
                                color: AppColors.black,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Edit',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFE8E8E8)),
                    // Hapus
                    Expanded(
                      child: GestureDetector(
                        onTap: isDeleting ? null : _confirmDelete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: isDeleting
                              ? const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PhosphorIcon(
                                      PhosphorIcons.trash(),
                                      size: 15,
                                      color: AppColors.danger,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Hapus',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Expanded: Incoming requests ───────────────────────
          if (_expanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.black, width: 1.5),
                ),
                color: AppColors.background,
              ),
              child: requestsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.black,
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(e.toString(), style: AppTextStyles.caption),
                ),
                data: (requests) => requests.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Belum ada permintaan untuk buku ini.',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      )
                    : Column(
                        children: requests
                            .map((tx) => _CompactRequestTile(
                                  tx: tx,
                                  book: widget.book,
                                ))
                            .toList(),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactRequestTile extends ConsumerWidget {
  final TransactionModel tx;
  final BookModel book;

  const _CompactRequestTile({required this.tx, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(transactionControllerProvider).isLoading;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                size: 20,
                color: AppColors.black,
              ),
              const SizedBox(width: 6),
              Text('Pemohon', style: AppTextStyles.label),
              const Spacer(),
              Text(
                timeago.format(tx.createdAt, locale: 'id'),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tx.requestMessage,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Tolak Permintaan',
                            message: 'Kamu yakin ingin menolak permintaan ini?',
                            confirmLabel: 'Ya, Tolak',
                            isDestructive: true,
                          );
                          if (!ok) return;
                          await ref
                              .read(transactionControllerProvider.notifier)
                              .updateStatus(tx, TransactionStatus.rejected);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Permintaan telah ditolak'),
                                backgroundColor: AppColors.danger,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.danger,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Tolak',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Setujui Permintaan',
                            message:
                                'Buku akan diubah statusnya menjadi "Dipesan". Lanjutkan?',
                            confirmLabel: 'Ya, Setujui',
                          );
                          if (!ok) return;
                          await ref
                              .read(transactionControllerProvider.notifier)
                              .updateStatus(tx, TransactionStatus.approved);
                          if (context.mounted) {
                            // Ambil info receiver untuk ditampilkan di snackbar
                            final receiverAsync = ref.read(
                              _receiverInfoProvider(tx.receiverId),
                            );
                            final receiver = await receiverAsync.when(
                              data: (user) => user,
                              loading: () => null,
                              error: (_, __) => null,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: receiver != null
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Disetujui! Informasi penerima:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Nama: ${receiver.name}'),
                                          Text('Lokasi: ${receiver.location}'),
                                        ],
                                      )
                                    : const Text('Permintaan telah disetujui'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.success,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Setujui',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Permintaanku ──────────────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.black),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (requests) {
        if (requests.isEmpty) {
          return _EmptyState(
            icon: PhosphorIcons.bookmarkSimple(),
            message: 'Kamu belum pernah meminta buku.',
            action: 'Jelajahi Buku',
            onTap: () => context.go('/'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) => _MyRequestCard(
            tx: requests[i],
            ref: ref,
          ),
        );
      },
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final TransactionModel tx;
  final WidgetRef ref;

  const _MyRequestCard({required this.tx, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2.5),
        boxShadow: const [AppColors.neoShadow],
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: tx.statusColor.withValues(alpha: 0.25),
            child: Row(
              children: [
                _statusIcon(tx.status),
                const SizedBox(width: 6),
                Text(
                  tx.statusLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  timeago.format(tx.createdAt, locale: 'id'),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Book cover
                SizedBox(
                  width: 56,
                  height: 70,
                  child: tx.bookImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: tx.bookImageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.background,
                          child: Center(
                            child: PhosphorIcon(
                              PhosphorIcons.book(),
                              size: 22,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.bookTitle,
                        style: AppTextStyles.bodyBold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pesanmu: ${tx.requestMessage}',
                        style: AppTextStyles.caption.copyWith(height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Completed action (jika approved)
          if (tx.status == TransactionStatus.approved)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: NeoButton(
                label: 'Tandai Sudah Diterima',
                backgroundColor: AppColors.success,
                onPressed: () => ref
                    .read(transactionControllerProvider.notifier)
                    .markCompleted(tx),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusIcon(TransactionStatus status) {
    final icon = switch (status) {
      TransactionStatus.pending => PhosphorIcons.hourglassMedium(),
      TransactionStatus.approved =>
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
      TransactionStatus.rejected =>
        PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
      TransactionStatus.completed =>
        PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
    };
    return PhosphorIcon(icon, size: 14, color: AppColors.black);
  }
}

// ── Shared empty state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final PhosphorIconData icon;
  final String message;
  final String action;
  final VoidCallback onTap;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            NeoButton(
              label: action,
              fullWidth: false,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
