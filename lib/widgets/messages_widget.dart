import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../models/messages.dart';
import '../theme/app_theme.dart';
import '../screens/direct/direct_chat_screen.dart';
import '../screens/group/group_chat_screen.dart';
import '../screens/all_screen.dart';

class ConversationWidget extends StatelessWidget {
  final Conversation conversation;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  const ConversationWidget({super.key, required this.conversation});

  void _showOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOption(
                context,
                icon: Icons.archive_outlined,
                title: 'Archiver la conversation',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Logique archivage
                },
              ),
              _buildOption(
                context,
                icon: Icons.notifications_off_outlined,
                title: 'Désactiver les notifications',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Logique notifications
                },
              ),
              _buildOption(
                context,
                icon: Icons.delete_outline,
                title: 'Supprimer la conversation',
                color: AppTheme.accentColor,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Logique suppression
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).iconTheme.color),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Contact contact, BuildContext context) {
    final hasStory = contact.story.isNotEmpty;
    final isGroup = contact.type == "groupe";

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
                child: Icon(
                  isGroup ? Icons.groups_rounded : Icons.person,
                  size: isGroup ? 30 : 28,
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
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<String?>(
      future: secureStorage.read(key: 'user'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        } else if (snapshot.hasData) {
          final userId = snapshot.data!.replaceAll('"', '');
          final isMessageSentByUser =
              conversation.dernierMessage.expediteur == userId;
          final isUnread = _isUnread(userId);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? (isUnread
                      ? AppTheme.primaryColor.withOpacity(0.08)
                      : Colors.transparent)
                  : (isUnread
                      ? AppTheme.primaryColor.withOpacity(0.05)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToChatScreen(context),
                onLongPress: () => _showOptions(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Avatar avec status
                      Stack(
                        children: [
                          _buildAvatar(conversation.contact, context),
                          _buildStatus(conversation.contact),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conversation.contact.nom,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: isUnread
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(
                                      conversation.dernierMessage.dateEnvoi),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isUnread
                                            ? AppTheme.primaryColor
                                            : Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                        fontWeight: isUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (isMessageSentByUser) ...[
                                  _buildReadStatus(userId),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: isMessageSentByUser
                                      ? _buildSentMessage(context, userId)
                                      : _buildReceivedMessage(context, userId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Badge non lu
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildSentMessage(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = conversation.dernierMessage;
    final content = _getContentSubtitle(message.contenu, true);

    return Text(
      content,
      style: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildReceivedMessage(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = conversation.dernierMessage;
    final content = _getContentSubtitle(message.contenu, false);
    final isRead = message is DernierMessageUtilisateur
        ? message.lu
        : (message as DernierMessageGroupe)
            .luPar
            .any((lecture) => lecture.utilisateurId == userId);

    return Text(
      content,
      style: TextStyle(
        // 🔧 FIX: Couleur adaptée au mode dark pour les messages non lus
        color: isRead
            ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
            : (isDark ? Colors.white : Colors.black87),
        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
        fontSize: 14,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getContentSubtitle(Contenu contenu, bool isSentByUser) {
    const int maxLength = 30;
    String text;

    if (isSentByUser) {
      text = switch (contenu.type) {
        'texte' => 'Vous: ${contenu.texte ?? ''}',
        'image' => 'Vous: 📷 Photo',
        'audio' => 'Vous: 🎤 Message vocal',
        'video' => 'Vous: 🎥 Vidéo',
        _ => 'Vous: 📎 Pièce jointe',
      };
    } else {
      text = switch (contenu.type) {
        'texte' => contenu.texte ?? '',
        'image' => '📷 Photo',
        'audio' => '🎤 Message vocal',
        'video' => '🎥 Vidéo',
        _ => '📎 Pièce jointe',
      };
    }

    if (text.length > maxLength) {
      text = '${text.substring(0, maxLength)}...';
    }

    return text;
  }

  void _navigateToChatScreen(BuildContext context) {
    if (conversation.contact.type == "groupe") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupChatScreen(groupId: conversation.contact.id),
        ),
      );
    } else if (conversation.contact.type == "utilisateur") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DirectChatScreen(contactId: conversation.contact.id),
        ),
      );
    }
  }

  bool _isUnread(String userId) {
    if (conversation.dernierMessage is DernierMessageUtilisateur) {
      DernierMessageUtilisateur message =
          conversation.dernierMessage as DernierMessageUtilisateur;
      return message.expediteur != userId && !message.lu;
    } else if (conversation.dernierMessage is DernierMessageGroupe) {
      DernierMessageGroupe message =
          conversation.dernierMessage as DernierMessageGroupe;
      return message.expediteur != userId &&
          !message.luPar.any((lecture) => lecture.utilisateurId == userId);
    }
    return false;
  }

  Widget _buildReadStatus(String userId) {
    if (conversation.dernierMessage is DernierMessageGroupe) {
      DernierMessageGroupe message =
          conversation.dernierMessage as DernierMessageGroupe;
      if (message.luPar.isNotEmpty) {
        return const Icon(Icons.done_all,
            color: AppTheme.primaryColor, size: 16);
      } else {
        return Icon(Icons.done, color: Colors.grey.shade500, size: 16);
      }
    } else if (conversation.dernierMessage is DernierMessageUtilisateur) {
      DernierMessageUtilisateur message =
          conversation.dernierMessage as DernierMessageUtilisateur;
      if (message.lu) {
        return const Icon(Icons.done_all,
            color: AppTheme.primaryColor, size: 16);
      } else {
        return Icon(Icons.done, color: Colors.grey.shade500, size: 16);
      }
    }
    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    final DateTime adjustedDate = date;
    final now = DateTime.now();

    final nowDate = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(adjustedDate.year, adjustedDate.month, adjustedDate.day);

    final difference = nowDate.difference(messageDate).inDays;

    if (difference == 0) {
      final DateTime adjustedDat = date.add(const Duration(hours: 3));
      return DateFormat.Hm().format(adjustedDat);
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return DateFormat('EEEE', 'fr_FR').format(messageDate);
    } else {
      return DateFormat('dd/MM/yy').format(messageDate);
    }
  }
}
