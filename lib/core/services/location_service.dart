import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Minta izin lalu ambil posisi GPS saat ini.
  /// Kembalikan null kalau izin ditolak atau GPS mati.
  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Koordinat → nama kota/kecamatan (Bahasa Indonesia-friendly).
  static Future<String> getAddressFromLatLng(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Lokasi tidak diketahui';

      final p = placemarks.first;
      final parts = <String>[
        if (p.subLocality?.isNotEmpty == true) p.subLocality!,
        if (p.locality?.isNotEmpty == true) p.locality!,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
      ];
      return parts.isEmpty ? 'Lokasi tidak diketahui' : parts.join(', ');
    } catch (_) {
      return 'Lokasi tidak diketahui';
    }
  }
}
