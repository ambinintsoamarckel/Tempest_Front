// lib/widgets/messages/cached_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mini_social_network/theme/app_theme.dart';

class CachedImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onImageLoaded;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.onImageLoaded,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _hasNotified = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,

      // ✅ Quand l'image est chargée (cache ou réseau)
      imageBuilder: (context, imageProvider) {
        if (!_hasNotified && widget.onImageLoaded != null) {
          _hasNotified = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onImageLoaded?.call();
          });
        }

        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
        );
      },

      // Pendant le chargement
      placeholder: (context, url) => Container(
        width: 250,
        height: 200,
        color: Colors.grey.shade200,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      ),

      // En cas d'erreur
      errorWidget: (context, url, error) => Container(
        width: 250,
        height: 200,
        color: Colors.grey.shade300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined,
                size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text('Image non disponible',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),

      // ✅ Options de cache
      cacheKey: widget.imageUrl,
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
      memCacheWidth: 500,
      memCacheHeight: 500,
    );
  }
}
