import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        image: _getBackgroundImage(),
      ),
      child: child,
    );
  }

  DecorationImage? _getBackgroundImage() {
    // Try to load background image from assets
    try {
      return const DecorationImage(
        image: AssetImage('assets/images/background.png'),
        fit: BoxFit.cover,
        opacity: 0.15,
      );
    } catch (e) {
      // If no background image, return null
      return null;
    }
  }
}
