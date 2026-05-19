import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neo_button.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../books/models/book_model.dart';
import '../../profile/models/user_model.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../transactions/models/transaction_model.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final _bookDetailProvider =
    StreamProvider.family<BookModel?, String>((ref, id) {
  return FirebaseFirestore.instance
      .collection('books')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? BookModel.fromFirestore(doc) : null);
});

final _donorProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

// ── Screen ──────────────────────────────────────────────────────────────────

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(_bookDetailProvider(bookId));

    return bookAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),
      data: (book) {
        if (book == null) {
          return const Scaffold(
            body: Center(child: Text('Buku tidak ditemukan.')),
          );
        }
        return _BookDetailView(book: book);
      },
    );
  }
}

// Ganti class _BookDetailView sepenuhnya:

class _BookDetailView extends ConsumerWidget {
  final BookModel book;
  const _BookDetailView({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == book.donorId;
    final donorAsync = ref.watch(_donorProvider(book.donorId));
    final activeReqAsync = ref.watch(activeRequestProvider(book.id));

    final conditionColor = switch (book.condition) {
      BookCondition.likeNew => const Color(0xFF4ECDC4),
      BookCondition.good => const Color(0xFF7BC67E),
      BookCondition.fair => const Color(0xFFFFB347),
      BookCondition.poor => const Color(0xFFFF6B6B),
    };

    return Scaffold(
      backgroundColor: AppColors.background,

      // ── AppBar solid + sticky (issue 6) ─────────────────────
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                      size: 20,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    book.title,
                    style: AppTextStyles.bodyBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          // ── Scrollable content ───────────────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book image (scrolls with content)
                SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: book.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF0ECE6),
                            child: Center(
                              child: PhosphorIcon(
                                PhosphorIcons.bookOpen(),
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0ECE6),
                          child: Center(
                            child: PhosphorIcon(
                              PhosphorIcons.bookOpen(),
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),

                // ── Chips + title ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Chip(
                              label: book.category, bg: AppColors.infoSurface),
                          _Chip(
                            label: AppConstants
                                .conditionLabels[book.condition.name]!,
                            bg: conditionColor.withValues(alpha: 0.2),
                          ),
                          _Chip(
                            label: book.status == BookStatus.available
                                ? 'Tersedia'
                                : book.status == BookStatus.reserved
                                    ? 'Dipesan'
                                    : 'Sudah Didonasi',
                            bg: book.status == BookStatus.available
                                ? AppColors.successSurface
                                : AppColors.dangerSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(book.title, style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      Text(
                        'oleh ${book.author}',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.clock(),
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(book.createdAt, locale: 'id'),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const _Divider(),

                if (book.description.isNotEmpty) ...[
                  _Section(
                    title: 'Deskripsi',
                    icon: PhosphorIcons.textAlignLeft(),
                    child: Text(
                      book.description,
                      style: AppTextStyles.body.copyWith(height: 1.6),
                    ),
                  ),
                  const _Divider(),
                ],

                if (book.hasLocation) ...[
                  _Section(
                    title: 'Lokasi Buku',
                    icon: PhosphorIcons.mapPin(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 160,
                          decoration: const BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.black, width: 2.5),
                            ),
                            boxShadow: [AppColors.neoShadowSmall],
                          ),
                          child: ClipRect(
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter:
                                    LatLng(book.latitude!, book.longitude!),
                                initialZoom: 14,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.farid.donasibuku',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        book.latitude!,
                                        book.longitude!,
                                      ),
                                      width: 36,
                                      height: 36,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.danger,
                                          border: Border.all(
                                            color: AppColors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: PhosphorIcon(
                                          PhosphorIcons.mapPin(
                                            PhosphorIconsStyle.fill,
                                          ),
                                          size: 18,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                              size: 14,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                book.donorLocation,
                                style: AppTextStyles.body,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const _Divider(),
                ],

                _Section(
                  title: 'Pendonor',
                  icon: PhosphorIcons.user(),
                  child: donorAsync.when(
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    error: (_, __) =>
                        Text('Gagal memuat', style: AppTextStyles.caption),
                    data: (donor) => donor == null
                        ? const SizedBox.shrink()
                        : _DonorCard(donor: donor),
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky bottom action (issue 5: SafeArea) ─────────
          if (!isOwner && book.status == BookStatus.available)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                // Dekorasi warna putih sekarang membungkus sampai ke ujung layar paling bawah
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.black, width: 2.5),
                  ),
                ),
                // SafeArea ditaruh di dalam agar memotong PADDING kontennya saja, bukan background-nya
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: activeReqAsync.when(
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (existing) => existing != null
                          ? _StatusBanner(status: existing.status)
                          : NeoButton(
                              label: 'Minta Buku Ini',
                              onPressed: () => _showRequestSheet(context, book),
                            ),
                    ),
                  ),
                ),
              ),
            ),

          if (isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.black, width: 2.5),
                    ),
                  ),
                  child: NeoButton(
                    label: 'Lihat Permintaan Masuk',
                    backgroundColor: AppColors.black,
                    onPressed: () => _showIncomingRequests(context, book.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showRequestSheet(BuildContext context, BookModel book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestSheet(book: book),
    );
  }

  void _showIncomingRequests(BuildContext context, String bookId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomingRequestsSheet(bookId: bookId, book: book),
    );
  }
}

// _ActionButton — fix warna (issue 8)
class _ActionButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color border;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.bg,
    required this.border,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg, // pakai AppColors.dangerSurface / successSurface
          border: Border.all(color: border, width: 2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.button.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

// ── Request sheet ────────────────────────────────────────────────────────────

class _RequestSheet extends ConsumerStatefulWidget {
  final BookModel book;

  const _RequestSheet({required this.book});

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_msgCtrl.text.trim().isEmpty) return;

    await ref.read(transactionControllerProvider.notifier).createRequest(
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          bookImageUrl: widget.book.imageUrl,
          donorId: widget.book.donorId,
          message: _msgCtrl.text,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Permintaan terkirim! Tunggu konfirmasi dari pendonor.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionControllerProvider).isLoading;
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.black, width: 2.5),
          boxShadow: const [AppColors.neoShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Text('Minta Buku Ini', style: AppTextStyles.heading2),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book mini info
                  Text(
                    widget.book.title,
                    style: AppTextStyles.bodyBold,
                  ),
                  Text(
                    'oleh ${widget.book.author}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 20),

                  NeoTextField(
                    label: 'Kenapa kamu ingin buku ini? *',
                    controller: _msgCtrl,
                    hint: 'Ceritakan sedikit alasanmu...',
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Pesan tidak boleh kosong.'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  NeoButton(
                    label: 'Kirim Permintaan',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Incoming requests sheet (donor view) ─────────────────────────────────────

class _IncomingRequestsSheet extends ConsumerWidget {
  final String bookId;
  final BookModel book;

  const _IncomingRequestsSheet({
    required this.bookId,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider(bookId));
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.black, width: 2.5),
          boxShadow: const [AppColors.neoShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.black,
              child: Text(
                'Permintaan Masuk',
                style:
                    AppTextStyles.heading2.copyWith(color: AppColors.primary),
              ),
            ),
            Flexible(
              child: requestsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.black),
                ),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (requests) => requests.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.tray(),
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada permintaan.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _RequestCard(
                          tx: requests[i],
                          book: book,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final TransactionModel tx;
  final BookModel book;

  const _RequestCard({required this.tx, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(transactionControllerProvider).isLoading;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [AppColors.neoShadowSmall],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                size: 32,
                color: AppColors.black,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pemohon', style: AppTextStyles.label),
                    Text(
                      timeago.format(tx.createdAt, locale: 'id'),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: AppColors.black,
                width: 1.5,
              ),
            ),
            child: Text(
              tx.requestMessage,
              style: AppTextStyles.body.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Tolak',
                  bg: AppColors.dangerSurface,
                  border: AppColors.danger,
                  loading: isLoading,
                  onTap: () async {
                    await ref
                        .read(transactionControllerProvider.notifier)
                        .updateStatus(
                          tx,
                          TransactionStatus.rejected,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Setujui',
                  bg: AppColors.successSurface,
                  border: AppColors.success,
                  loading: isLoading,
                  onTap: () async {
                    await ref
                        .read(transactionControllerProvider.notifier)
                        .updateStatus(
                          tx,
                          TransactionStatus.approved,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final PhosphorIconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, size: 16, color: AppColors.black),
              const SizedBox(width: 6),
              Text(title, style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 1,
      color: const Color(0xFFE8E8E8),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;

  const _Chip({required this.label, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: AppColors.black,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final UserModel donor;

  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [AppColors.neoShadowSmall],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border.all(color: AppColors.black, width: 2),
            ),
            child: Center(
              child: Text(
                donor.name.isNotEmpty ? donor.name[0].toUpperCase() : '?',
                style: AppTextStyles.heading1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donor.name, style: AppTextStyles.bodyBold),
                if (donor.location.isNotEmpty)
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.mapPin(),
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(donor.location, style: AppTextStyles.caption),
                    ],
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${donor.donatedCount}',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.black,
                ),
              ),
              Text('donasi', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      TransactionStatus.pending => 'Permintaanmu sedang menunggu konfirmasi',
      TransactionStatus.approved => 'Permintaanmu telah disetujui!',
      _ => '',
    };
    final color = switch (status) {
      TransactionStatus.pending => AppColors.info,
      TransactionStatus.approved => AppColors.success,
      _ => AppColors.background,
    };
    final icon = switch (status) {
      TransactionStatus.pending => PhosphorIcons.hourglassMedium(),
      TransactionStatus.approved =>
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
      _ => PhosphorIcons.info(),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 20, color: AppColors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyBold),
          ),
        ],
      ),
    );
  }
}
