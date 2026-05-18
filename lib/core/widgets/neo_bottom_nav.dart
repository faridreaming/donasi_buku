import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class _NavItem {
  final String label;
  final String path;
  final PhosphorIconData icon;
  final PhosphorIconData iconActive;

  const _NavItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.iconActive,
  });
}

final _navItems = <_NavItem>[
  _NavItem(
    label: 'Beranda',
    path: '/',
    icon: PhosphorIcons.house(),
    iconActive: PhosphorIcons.house(PhosphorIconsStyle.fill),
  ),
  _NavItem(
    label: 'Peta',
    path: '/map',
    icon: PhosphorIcons.mapTrifold(),
    iconActive: PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill),
  ),
  _NavItem(
    label: 'Donasi',
    path: '/donate',
    icon: PhosphorIcons.plusCircle(),
    iconActive: PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
  ),
  _NavItem(
    label: 'Aktivitas',
    path: '/activity',
    icon: PhosphorIcons.clockCounterClockwise(),
    iconActive: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
  ),
  _NavItem(
    label: 'Profil',
    path: '/profile',
    icon: PhosphorIcons.user(),
    iconActive: PhosphorIcons.user(PhosphorIconsStyle.fill),
  ),
];

class NeoBottomNav extends StatelessWidget {
  final String currentLocation;

  const NeoBottomNav({super.key, required this.currentLocation});

  bool _isActive(_NavItem item) {
    if (item.path == '/') {
      return currentLocation == '/' || currentLocation.startsWith('/book');
    }
    return currentLocation.startsWith(item.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.black, width: 2.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: _navItems.map((item) {
              final active = _isActive(item);
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(item.path),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: active
                        ? BoxDecoration(
                            color: AppColors.primary,
                            border: Border.all(
                              color: AppColors.black,
                              width: 2,
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          active ? item.iconActive : item.icon,
                          size: 22,
                          color: AppColors.black,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w500,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
