// lib/widgets/messages/message_options_sheet.dart
import 'package:flutter/material.dart';
import '../../models/direct_message.dart';
import '../../theme/app_theme.dart';

class MessageOptionsSheet {
  static void show(
    BuildContext context, {
    required dynamic message,
    required bool isContact,
    required VoidCallback onCopy,
    required Function(String) onTransfer,
    required Future<void> Function(String) onDelete,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OptionsSheetContent(
        message: message,
        isContact: isContact,
        onCopy: onCopy,
        onTransfer: onTransfer,
        onDelete: onDelete,
        onSave: onSave,
      ),
    );
  }
}

class _OptionsSheetContent extends StatefulWidget {
  final DirectMessage message;
  final bool isContact;
  final VoidCallback onCopy;
  final Function(String) onTransfer;
  final Future<void> Function(String) onDelete;
  final VoidCallback onSave;

  const _OptionsSheetContent({
    required this.message,
    required this.isContact,
    required this.onCopy,
    required this.onTransfer,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<_OptionsSheetContent> createState() => _OptionsSheetContentState();
}

class _OptionsSheetContentState extends State<_OptionsSheetContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle moderne
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 24),

                // Titre élégant
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Options avec animations
                if (widget.message.contenu.type == MessageType.texte)
                  _buildAnimatedOption(
                    icon: Icons.copy_rounded,
                    title: 'Copier',
                    subtitle: 'Copier le texte',
                    color: AppTheme.primaryColor,
                    delay: 0,
                    onTap: () {
                      widget.onCopy();
                      Navigator.pop(context);
                    },
                  ),

                _buildAnimatedOption(
                  icon: Icons.forward_rounded,
                  title: 'Transférer',
                  subtitle: 'Envoyer à un contact',
                  color: AppTheme.secondaryColor,
                  delay: 50,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTransfer(widget.message.id);
                  },
                ),

                if ([
                  MessageType.image,
                  MessageType.fichier,
                  MessageType.audio,
                  MessageType.video
                ].contains(widget.message.contenu.type))
                  _buildAnimatedOption(
                    icon: Icons.download_rounded,
                    title: 'Télécharger',
                    subtitle: 'Enregistrer sur l\'appareil',
                    color: Colors.blue,
                    delay: 100,
                    onTap: () async {
                      Navigator.pop(context);
                      widget.onSave();
                    },
                  ),

                _buildAnimatedOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Supprimer',
                  subtitle: 'Supprimer définitivement',
                  color: AppTheme.accentColor,
                  delay: 150,
                  onTap: () {
                    // ✅ Fermer le bottom sheet et montrer le dialog
                    Navigator.pop(context);
                    _showModernDeleteDialog(context);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showModernDeleteDialog(BuildContext sheetContext) {
    // ✅ Utiliser le context du bottom sheet qui est toujours valide
    showDialog(
      context: sheetContext,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteConfirmDialog(
        message: widget.message,
        onDelete: widget.onDelete,
      ),
    );
  }
}

// ✅ Dialog séparé avec son propre context stable
class _DeleteConfirmDialog extends StatefulWidget {
  final DirectMessage message;
  final Future<void> Function(String) onDelete;

  const _DeleteConfirmDialog({
    required this.message,
    required this.onDelete,
  });

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône animée
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.accentColor,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Titre
            const Text(
              'Supprimer le message ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Cette action est irréversible. Le message sera supprimé définitivement.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Boutons modernes
            Row(
              children: [
                // Bouton Annuler
                Expanded(
                  child: TextButton(
                    onPressed:
                        _isDeleting ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Bouton Supprimer
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting ? null : _handleDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Supprimer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    if (_isDeleting || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      // ✅ Suppression
      await widget.onDelete(widget.message.id);

      // ✅ Fermer le dialog SI toujours monté
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Erreur suppression: $e');

      // ✅ Réinitialiser SI toujours monté
      if (mounted) {
        setState(() => _isDeleting = false);

        // ✅ Afficher l'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur de suppression'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
