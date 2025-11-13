// lib/widgets/messages/cached_image.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CachedImage extends StatefulWidget {
  final String imageUrl;
  const CachedImage({super.key, required this.imageUrl});

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: 250,
          height: 200,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              color: AppTheme.primaryColor,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
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
    );
  }
}
