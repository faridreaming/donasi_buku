import 'package:donasi_buku/features/notifications/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/home_controller.dart';
import '../widgets/book_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    // Sync controller dengan nilai provider yang ada — fix bug teks hilang
    _searchCtrl = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(selectedCategoryProvider);
    final filteredAsync = ref.watch(filteredBooksProvider);
    final totalAsync = ref.watch(booksProvider);

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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DonasiBuku', style: AppTextStyles.heading1),
                              totalAsync
                                          .whenData((list) => list.length)
                                          .valueOrNull !=
                                      null
                                  ? Text(
                                      '${totalAsync.valueOrNull?.length ?? 0} buku gratis menunggumu',
                                      style: AppTextStyles.caption,
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                        Consumer(
                          builder: (_, ref, __) {
                            final count = ref.watch(unreadCountProvider);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    border: Border.fromBorderSide(
                                      BorderSide(
                                          color: AppColors.black, width: 2),
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: PhosphorIcon(PhosphorIcons.bell(),
                                        size: 20),
                                    onPressed: () =>
                                        context.push('/notifications'),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: AppColors.danger,
                                        border: Border.all(
                                            color: AppColors.black, width: 1.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          count > 9 ? '9+' : '$count',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search bar
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.black, width: 2.5),
                        ),
                      ),
                      child: TextField(
                        controller: _searchCtrl, // ← pakai controller yang sync
                        onChanged: (v) =>
                            ref.read(searchQueryProvider.notifier).state = v,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Cari judul atau pengarang...',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: AppColors.textMuted),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: PhosphorIcon(
                              PhosphorIcons.magnifyingGlass(),
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: PhosphorIcon(
                                    PhosphorIcons.x(),
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: _clearSearch, // ← clear keduanya
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category chips ────────────────────────────────────────
          Container(
            color: AppColors.white,
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ),
              itemCount: AppConstants.bookCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = AppConstants.bookCategories[i];
                final isActive =
                    (i == 0 && category == null) || cat == category;
                return GestureDetector(
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = i == 0 ? null : cat,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.black : AppColors.white,
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
                          color: isActive ? AppColors.primary : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.black, thickness: 1),

          // ── Result info bar ───────────────────────────────────────
          if (query.isNotEmpty || category != null)
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: filteredAsync.whenData((l) => l.length).maybeWhen(
                    data: (count) => RichText(
                      text: TextSpan(
                        style: AppTextStyles.caption,
                        children: [
                          TextSpan(
                            text: '$count buku',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const TextSpan(text: ' ditemukan'),
                          if (query.isNotEmpty)
                            TextSpan(text: ' untuk "$query"'),
                          if (category != null)
                            TextSpan(text: ' dalam $category'),
                        ],
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
            ),

          // ── Book list ─────────────────────────────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.black),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.wifiSlash(),
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data', style: AppTextStyles.bodyBold),
                      const SizedBox(height: 6),
                      Text(
                        e.toString(),
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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
                            query.isNotEmpty
                                ? 'Tidak ada buku yang cocok.'
                                : 'Belum ada buku tersedia.',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
