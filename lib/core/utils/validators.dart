abstract class Validators {
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong.';
    }
    if (value.trim().length < 2) return 'Nama terlalu pendek.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email tidak boleh kosong.';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Format email tidak valid.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong.';
    if (value.length < 8) return 'Password minimal 8 karakter.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi.';
    }
    if (value != original) return 'Password tidak cocok.';
    return null;
  }
}
