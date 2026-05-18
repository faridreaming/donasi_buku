abstract class AppConstants {
  static const List<String> bookCategories = [
    'Semua',
    'Fiksi',
    'Non-Fiksi',
    'Pelajaran',
    'Agama',
    'Sains & Teknologi',
    'Sejarah',
    'Lainnya',
  ];

  static const Map<String, String> conditionLabels = {
    'likeNew': 'Seperti Baru',
    'good': 'Bagus',
    'fair': 'Cukup',
    'poor': 'Kurang',
  };

  // Default center: Medan, Sumatra Utara
  static const double defaultLat = 3.5896;
  static const double defaultLng = 98.6739;
}
