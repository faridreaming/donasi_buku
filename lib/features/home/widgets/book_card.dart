import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../books/models/book_model.dart';

class BookCard extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _pressed = false;

  Color get _conditionColor => switch (widget.book.condition) {
        BookCondition.likeNew => const Color(0xFF4ECDC4),
        BookCondition.good => const Color(0xFF7BC67E),
        BookCondition.fair => const Color(0xFFFFB347),
        BookCondition.poor => const Color(0xFFFF6B6B),
      };

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 130, // ← tinggi tetap, tidak ikut gambar
        margin: const EdgeInsets.only(bottom: 14),
        transform:
            _pressed ? Matrix4.translationValues(3, 3, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.black, width: 2.5),
          boxShadow: _pressed ? null : const [AppColors.neoShadow],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Condition strip ────────────────────────────────
            Container(width: 5, color: _conditionColor),

            // ── Book cover (fixed size, clip overflow) ─────────
            SizedBox(
              width: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  book.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl,
                          fit: BoxFit.cover, // cover menjaga proporsi dalam box
                          placeholder: (_, __) => const _CoverPlaceholder(),
                          errorWidget: (_, __, ___) =>
                              const _CoverPlaceholder(),
                        )
                      : const _CoverPlaceholder(),

                  // GRATIS badge
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.primary,
                      child: Text(
                        'GRATIS',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + Condition
                    Row(
                      children: [
                        _Chip(label: book.category, bg: AppColors.infoSurface),
                        const SizedBox(width: 5),
                        _Chip(
                          label: AppConstants
                              .conditionLabels[book.condition.name]!,
                          bg: _conditionColor.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      book.title,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Author
                    Text(
                      book.author,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Donor info  ← issue 4
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.donorName.isNotEmpty
                                ? book.donorName
                                : 'Anonim',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Location
                    if (book.donorLocation.isNotEmpty)
                      Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.donorLocation,
                              style:
                                  AppTextStyles.caption.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // ── Arrow ──────────────────────────────────────────
            Container(
              width: 30,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFE8E8E8)),
                ),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                  size: 14,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0ECE6),
      child: Center(
        child: PhosphorIcon(
          PhosphorIcons.bookOpen(),
          size: 28,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
