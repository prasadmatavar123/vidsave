import 'package:flutter/material.dart';

class AppRoute {
  static Route<T> fade<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(c),
              child: child,
            ),
          );
        },
      );
}
