import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class VideoThumb extends StatelessWidget {
  const VideoThumb({super.key, this.path, this.width, this.height, this.radius = 14});

  final String? path;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: context.cs.outlineVariant,
      alignment: Alignment.center,
      child: Icon(Icons.movie_rounded, color: context.muted),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: path == null
            ? placeholder
            : Image.file(
                File(path!),
                fit: BoxFit.cover,
                cacheWidth: 480,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
