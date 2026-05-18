import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/home_controller.dart';
import '../widgets/book_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredBooksProvider);
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DonasiBuku', style: AppTextStyles.heading1),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            border: Border.fromBorderSide(
                              BorderSide(color: AppColors.black, width: 2),
                            ),
                          ),
                          child: IconButton(
                            icon: PhosphorIcon(
                              PhosphorIcons.bell(),
                              size: 20,
                            ),
                            onPressed: () {},
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Search bar
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.black, width: 2.5),
                        ),
                      ),
                      child: TextField(
                        onChanged: (v) =>
                            ref.read(searchQueryProvider.notifier).state = v,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Cari judul atau pengarang...',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: AppColors.textMuted),
                          prefixIcon: PhosphorIcon(
                            PhosphorIcons.magnifyingGlass(),
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: PhosphorIcon(
                                    PhosphorIcons.x(),
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => ref
                                      .read(searchQueryProvider.notifier)
                                      .state = '',
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category filter ───────────────────────────────────────
          Container(
            color: AppColors.white,
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: AppConstants.bookCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = AppConstants.bookCategories[i];
                final isActive =
                    (i == 0 && category == null) || cat == category;
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state =
                        i == 0 ? null : cat;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.white,
                      border: Border.all(
                        color: AppColors.black,
                        width: isActive ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.black, thickness: 1),

          // ── Book List ─────────────────────────────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.black),
              ),
              error: (e, _) => Center(
                child: Text('Gagal memuat data.', style: AppTextStyles.body),
              ),
              data: (books) => books.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.bookOpenText(),
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada buku tersedia.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: books.length,
                      itemBuilder: (_, i) => BookCard(
                        book: books[i],
                        onTap: () => context.push('/book/${books[i].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
