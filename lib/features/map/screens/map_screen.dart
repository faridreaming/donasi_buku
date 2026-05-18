import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neo_button.dart';
import '../../books/models/book_model.dart';
import '../../home/controllers/home_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _center = LatLng(
    AppConstants.defaultLat,
    AppConstants.defaultLng,
  );

  BookModel? _selected;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      body: booksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (books) {
          final mapped = books.where((b) => b.hasLocation).toList();

          return Stack(
            children: [
              // ── Map ───────────────────────────────────────────────
              FlutterMap(
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 11,
                  onTap: (_, __) => setState(() => _selected = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.farid.donasibuku',
                  ),
                  MarkerLayer(
                    markers: mapped.map((book) {
                      final isSelected = _selected?.id == book.id;
                      return Marker(
                        point: LatLng(book.latitude!, book.longitude!),
                        width: isSelected ? 48 : 38,
                        height: isSelected ? 48 : 38,
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = book),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.primary,
                              border: Border.all(
                                color: AppColors.black,
                                width: 2.5,
                              ),
                              boxShadow: const [AppColors.neoShadowSmall],
                            ),
                            child: Center(
                              child: PhosphorIcon(
                                PhosphorIcons.bookOpen(
                                  PhosphorIconsStyle.bold,
                                ),
                                size: isSelected ? 24 : 18,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // ── Stats header ──────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(
                              color: AppColors.black,
                              width: 2.5,
                            ),
                            boxShadow: const [AppColors.neoShadowSmall],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PhosphorIcon(
                                PhosphorIcons.mapTrifold(
                                  PhosphorIconsStyle.bold,
                                ),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${mapped.length} buku gratis',
                                style: AppTextStyles.bodyBold,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Total semua wilayah
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            border: Border.all(
                              color: AppColors.black,
                              width: 2.5,
                            ),
                            boxShadow: const [AppColors.neoShadowSmall],
                          ),
                          child: Text(
                            '${books.length} total',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Selected book card ─────────────────────────────────
              if (_selected != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BookPreviewCard(
                    book: _selected!,
                    onClose: () => setState(() => _selected = null),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BookPreviewCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onClose;

  const _BookPreviewCard({required this.book, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: 2.5),
        boxShadow: const [AppColors.neoShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(book.category,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: PhosphorIcon(PhosphorIcons.x(), size: 18),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Foto
                SizedBox(
                  width: 72,
                  height: 90,
                  child: book.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.background,
                          child: Center(
                            child: PhosphorIcon(
                              PhosphorIcons.book(),
                              size: 28,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.mapPin(),
                            size: 12,
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
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: NeoButton(
              label: 'Lihat Detail',
              onPressed: () => context.push('/book/${book.id}'),
            ),
          ),
        ],
      ),
    );
  }
}
