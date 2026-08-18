import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// Thin wrapper around CachedNetworkImage so every image in the app uses the
// same placeholder and error fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: colors.surfaceContainerHighest,
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Icon(
            Icons.image_not_supported_outlined,
            color: colors.onSurfaceVariant,
          ),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
