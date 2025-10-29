import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LandImageWidget extends StatelessWidget {
  final String? imagePath;
  final double height;
  final BoxFit fit;

  const LandImageWidget({
    super.key,
    required this.imagePath,
    this.height = 180,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it's a URL or local path
    if (imagePath!.startsWith('http')) {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath!,
        height: height,
        width: double.infinity,
        fit: fit,
        placeholder: (context, url) => Container(
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      // Local file
      final file = File(imagePath!);
      return Image.file(
        file,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
}
