import 'package:flutter/material.dart';
import 'neo_bottom_nav.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NeoBottomNav(currentLocation: location),
    );
  }
}
