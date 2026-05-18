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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ─────────────────────────────────────────────
            SizedBox(
              width: 100,
              height: 120,
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
                      errorWidget: (_, __, ___) => _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),

            // ── Info ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        border: Border.all(color: AppColors.black, width: 1.5),
                      ),
                      child: Text(
                        book.category,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.black, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      book.title,
                      style: AppTextStyles.bodyBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Condition badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _conditionColor(),
                            border: Border.all(
                              color: AppColors.black,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            AppConstants.conditionLabels[book.condition.name]!,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Location
                        if (book.donorLocation.isNotEmpty) ...[
                          PhosphorIcon(
                            PhosphorIcons.mapPin(),
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              book.donorLocation,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Arrow ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: PhosphorIcon(
                PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                size: 18,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
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
