import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../books/models/book_model.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  Color _conditionColor() => switch (book.condition) {
        BookCondition.likeNew => const Color(0xFF4ECDC4),
        BookCondition.good => const Color(0xFFFFE234),
        BookCondition.fair => const Color(0xFFFFB347),
        BookCondition.poor => const Color(0xFFFF6B6B),
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.black, width: 2.5),
          ),
          boxShadow: [AppColors.neoShadow],
        ),
        child: IntrinsicHeight(
          // ← baru
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // ← stretch agar kolom sama tinggi
            children: [
              // ── Photo ────────────────────────────────────────
              SizedBox(
                width: 96,
                child: book.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.background,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const _ImagePlaceholder(),
                      )
                    : const _ImagePlaceholder(),
              ),

              // ── Info ─────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Baris badge: category + condition
                      Row(
                        children: [
                          _Badge(
                            label: book.category,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 6),
                          _Badge(
                            label: AppConstants
                                .conditionLabels[book.condition.name]!,
                            color: _conditionColor(),
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Judul
                      Text(
                        book.title,
                        style: AppTextStyles.bodyBold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Penulis
                      Text(
                        book.author,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Lokasi
                      if (book.donorLocation.isNotEmpty)
                        Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.mapPin(),
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                book.donorLocation,
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 11),
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

              // ── Arrow ─────────────────────────────────────────
              Container(
                width: 38,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.black.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: PhosphorIcon(
                  PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                  size: 18,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge helper ─────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final FontWeight fontWeight;

  const _Badge({
    required this.label,
    required this.color,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: fontWeight,
          color: AppColors.black,
        ),
      ),
    );
  }
}

// ── Image placeholder ─────────────────────────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: PhosphorIcon(
          PhosphorIcons.book(),
          size: 32,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
