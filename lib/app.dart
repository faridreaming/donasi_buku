import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'router.dart';

class DonasiBukuApp extends ConsumerStatefulWidget {
  const DonasiBukuApp({super.key});

  @override
  ConsumerState<DonasiBukuApp> createState() => _DonasiBukuAppState();
}

class _DonasiBukuAppState extends ConsumerState<DonasiBukuApp> {
  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  /// Dipanggil saat app dibuka.
  /// Kalau user masih tercatat login tapi dokumen Firestore-nya
  /// tidak ada (akun dihapus), langsung signOut → GoRouter redirect ke /login.
  Future<void> _validateSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Belum login, biarkan router handle

    try {
      // Reload token — lempar exception kalau akun dihapus/disabled
      await user.reload();

      // Cek apakah dokumen user masih ada di Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Token expired / akun dihapus → paksa signOut
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DonasiBuku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      routerConfig: router,
    );
  }
}
