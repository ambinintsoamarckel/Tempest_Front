import 'package:flutter/material.dart';
import '../models/grouped_stories.dart';
import '../theme/app_theme.dart';
import '../models/stories.dart';

class StoryTile extends StatelessWidget {
  final GroupedStory story;

  const StoryTile({super.key, required this.story});

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.purple;
    }
    try {
      // Supporte les formats: #RRGGBB, #AARRGGBB, ou 0xAARRGGBB
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstStory = story.stories[0];
    final bool isTextStory = firstStory.contenu.type == StoryType.texte;
    final bool isImageStory = firstStory.contenu.type == StoryType.image;
    final bool isVideoStory = firstStory.contenu.type == StoryType.video;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            _buildBackground(
                firstStory, isTextStory, isImageStory, isVideoStory),

            // Gradient overlay pour meilleure lisibilité
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Contenu de la story texte
            if (isTextStory) _buildTextContent(firstStory),

            // Caption pour image/vidéo
            if ((isImageStory || isVideoStory) && firstStory.hasCaption)
              _buildCaption(firstStory),

            // Avatar de l'utilisateur (en haut à gauche)
            Positioned(
              top: 12,
              left: 12,
              child: _buildUserAvatar(),
            ),

            // Nom de l'utilisateur (en bas à gauche)
            Positioned(
              bottom: 12,
              left: 12,
              right: 60,
              child: _buildUserName(),
            ),

            // Compteur de stories multiples
            if (story.stories.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: _buildStoryCounter(),
              ),

            // Badge pour le type de story
            Positioned(
              bottom: 12,
              right: 12,
              child: _buildStoryTypeBadge(isTextStory, isVideoStory),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(Story firstStory, bool isTextStory, bool isImageStory,
      bool isVideoStory) {
    if (isTextStory) {
      // Story texte avec background personnalisé
      final bgColor = _parseColor(firstStory.contenu.backgroundColor);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgColor,
              bgColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    } else if (isImageStory && firstStory.contenu.image != null) {
      // Story image
      return Image.network(
        firstStory.contenu.image!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          );
        },
      );
    } else if (isVideoStory && firstStory.contenu.video != null) {
      // Story vidéo (thumbnail)
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 60,
            color: Colors.white,
          ),
        ),
      );
    }

    // Fallback
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.secondaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildTextContent(Story firstStory) {
    final textColor = _parseColor(firstStory.contenu.textColor);
    final fontSize = firstStory.contenu.fontSize ?? 20.0;
    final fontWeight = firstStory.contenu.fontWeight == 'bold'
        ? FontWeight.bold
        : FontWeight.normal;

    TextAlign textAlign = TextAlign.center;
    if (firstStory.contenu.textAlign == 'left') {
      textAlign = TextAlign.left;
    } else if (firstStory.contenu.textAlign == 'right') {
      textAlign = TextAlign.right;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          firstStory.contenu.texte ?? '',
          textAlign: textAlign,
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: fontSize,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(Story firstStory) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          firstStory.contenu.caption!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: story.utilisateur.photo != null
            ? NetworkImage(story.utilisateur.photo!)
            : null,
        child: story.utilisateur.photo == null
            ? const Icon(Icons.person, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildUserName() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        story.utilisateur.nom,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStoryCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.layers_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${story.stories.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTypeBadge(bool isTextStory, bool isVideoStory) {
    IconData icon;
    if (isTextStory) {
      icon = Icons.text_fields_rounded;
    } else if (isVideoStory) {
      icon = Icons.play_circle_filled_rounded;
    } else {
      icon = Icons.image_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
