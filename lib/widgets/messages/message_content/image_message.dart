// lib/widgets/messages/message_content/image_message.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../cached_image.dart';

class ImageMessage extends StatelessWidget {
  final String imageUrl;
  final String messageId;
// image_message.dart
  final VoidCallback? onSave;

  const ImageMessage({
    super.key,
    required this.imageUrl,
    required this.messageId,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Hero(
        tag: 'image_$messageId',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 250, maxHeight: 350),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: CachedImage(imageUrl: imageUrl),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  onSave?.call();
                },
              ),
            ],
          ),
          body: Center(
            child: Hero(
              tag: 'image_$messageId',
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                loadingBuilder: (_, event) => Center(
                  child: CircularProgressIndicator(
                    value: event?.expectedTotalBytes != null
                        ? event!.cumulativeBytesLoaded /
                            event!.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
