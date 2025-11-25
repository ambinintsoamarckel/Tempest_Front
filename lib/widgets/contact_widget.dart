import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../theme/app_theme.dart';
import '../screens/all_screen.dart';

class ContactWidget extends StatelessWidget {
  final Contact contact;
  final bool isSelected;

  const ContactWidget({
    super.key,
    required this.contact,
    this.isSelected = false,
  });

  Widget _buildAvatar(Contact contact, BuildContext context) {
    final hasStory = contact.story.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasStory) {
          _navigateToAllStoriesScreen(context, contact);
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStory
              ? const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        padding: EdgeInsets.all(hasStory ? 3 : 0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          padding: EdgeInsets.all(hasStory ? 2 : 0),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: contact.photo ?? '',
              placeholder: (context, url) => Container(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  size: 28,
                  color: AppTheme.primaryColor,
                ),
              ),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAllStoriesScreen(BuildContext context, Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllStoriesScreen(
          storyIds: contact.story,
          initialIndex: 0,
        ),
      ),
    );
  }

  Widget _buildStatus(Contact user) {
    if (user.presence != 'inactif') {
      return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.secondaryColor,
            border: Border.all(
              color: Colors.white,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTypeIcon(Contact contact) {
    if (contact.type == 'groupe') {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.group,
          size: 16,
          color: AppTheme.primaryColor,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Stack(
        children: [
          _buildAvatar(contact, context),
          _buildStatus(contact),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contact.nom,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (contact.type == 'groupe') ...[
            const SizedBox(width: 8),
            _buildTypeIcon(contact),
          ],
        ],
      ),
      subtitle: contact.presence != 'inactif'
          ? Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'En ligne',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            )
          : Text(
              contact.type == 'groupe' ? 'Groupe' : 'Hors ligne',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: contact.story.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Story',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
