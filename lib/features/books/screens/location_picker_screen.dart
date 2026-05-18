import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/neo_button.dart';

/// Data yang dikembalikan setelah user memilih lokasi.
class LocationResult {
  final double lat;
  final double lng;
  final String address;

  const LocationResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();

  late LatLng _pin;
  String _address = 'Menentukan alamat...';
  bool _loadingAddr = false;
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _pin = LatLng(
      widget.initialLat ?? AppConstants.defaultLat,
      widget.initialLng ?? AppConstants.defaultLng,
    );
    _fetchAddress(_pin);
    if (widget.initialLat == null) _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingGps = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      final ll = LatLng(pos.latitude, pos.longitude);
      _mapController.move(ll, 14);
      setState(() => _pin = ll);
      await _fetchAddress(ll);
    }
    if (mounted) setState(() => _loadingGps = false);
  }

  Future<void> _fetchAddress(LatLng ll) async {
    setState(() {
      _loadingAddr = true;
      _address = 'Menentukan alamat...';
    });
    final addr = await LocationService.getAddressFromLatLng(
      ll.latitude,
      ll.longitude,
    );
    if (mounted) {
      setState(() {
        _address = addr;
        _loadingAddr = false;
      });
    }
  }

  void _onMapTap(TapPosition _, LatLng ll) {
    setState(() => _pin = ll);
    _fetchAddress(ll);
  }

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                IconButton(
                  icon: PhosphorIcon(
                    PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Pilih Lokasi', style: AppTextStyles.heading2),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pin,
              initialZoom: 13,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.farid.donasibuku',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pin,
                    width: 44,
                    height: 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            border: Border.all(
                              color: AppColors.black,
                              width: 2,
                            ),
                            boxShadow: const [AppColors.neoShadowSmall],
                          ),
                          child: PhosphorIcon(
                            PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                            size: 18,
                            color: AppColors.white,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 8,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Hint ─────────────────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.black, width: 2),
              ),
              child: Text(
                'Ketuk peta untuk memilih lokasi',
                style: AppTextStyles.caption,
              ),
            ),
          ),

          // ── GPS button ────────────────────────────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _loadingGps ? null : _goToCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.black, width: 2.5),
                  boxShadow: const [AppColors.neoShadowSmall],
                ),
                child: _loadingGps
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PhosphorIcon(
                        PhosphorIcons.crosshair(PhosphorIconsStyle.bold),
                        size: 20,
                        color: AppColors.black,
                      ),
              ),
            ),
          ),

          // ── Confirm card ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.black, width: 2.5),
                boxShadow: const [AppColors.neoShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.mapPin(),
                        size: 16,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _loadingAddr
                            ? const LinearProgressIndicator(
                                color: AppColors.black,
                              )
                            : Text(
                                _address,
                                style: AppTextStyles.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NeoButton(
                    label: 'Konfirmasi Lokasi',
                    onPressed: _loadingAddr
                        ? null
                        : () => Navigator.pop(
                              context,
                              LocationResult(
                                lat: _pin.latitude,
                                lng: _pin.longitude,
                                address: _address,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
