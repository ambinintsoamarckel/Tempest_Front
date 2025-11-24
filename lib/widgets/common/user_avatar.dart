// lib/widgets/common/user_avatar.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

/// Widget d'avatar réutilisable avec support de présence, stories et placeholder
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final String? presence; // 'actif', 'absent', 'ne pas déranger', 'inactif'
  final bool showPresence;
  final bool hasStory;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24.0,
    this.presence,
    this.showPresence = false,
    this.hasStory = false,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasStory
            ? Border.all(
                color: AppTheme.primaryColor,
                width: radius > 25 ? 3.0 : 2.0,
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(hasStory ? 3.0 : 0),
        child: Stack(
          children: [
            _buildAvatarContent(),
            if (showPresence && presence != null && presence != 'inactif')
              _buildPresenceIndicator(),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }

  Widget _buildAvatarContent() {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? AppTheme.primaryColor.withOpacity(0.2),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: radius * 0.6,
                    height: radius * 0.6,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Text(
      initial,
      style: TextStyle(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
      ),
    );
  }

  Widget _buildPresenceIndicator() {
    final size = radius > 25 ? 14.0 : 10.0;
    final borderWidth = radius > 25 ? 2.5 : 2.0;

    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getPresenceColor(),
          border: Border.all(
            color: Colors.white,
            width: borderWidth,
          ),
        ),
      ),
    );
  }

  Color _getPresenceColor() {
    return switch (presence?.toLowerCase()) {
      'actif' || 'en ligne' => AppTheme.secondaryColor,
      'absent' => Colors.orange,
      'ne pas déranger' => AppTheme.accentColor,
      _ => Colors.grey,
    };
  }
}
