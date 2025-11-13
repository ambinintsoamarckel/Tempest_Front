// lib/widgets/messages/message_options_sheet.dart
import 'package:flutter/material.dart';
import '../../models/direct_message.dart';
import '../../theme/app_theme.dart';

class MessageOptionsSheet {
  static void show(
    BuildContext context, {
    required dynamic message, // dynamic ou MessageBase
    required bool isContact,
    required VoidCallback onCopy,
    required Function(String) onTransfer,
    required Function(String) onDelete,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
  final Function(String) onDelete;
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

class _OptionsSheetContentState extends State<_OptionsSheetContent> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            if (widget.message.contenu.type == MessageType.texte)
              _optionTile(Icons.copy_rounded, 'Copier', AppTheme.primaryColor,
                  () {
                widget.onCopy();
                Navigator.pop(context);
              }),
            _optionTile(
                Icons.forward_rounded, 'Transférer', AppTheme.secondaryColor,
                () {
              Navigator.pop(context);
              widget.onTransfer(widget.message.id);
            }),
            if ([
              MessageType.image,
              MessageType.fichier,
              MessageType.audio,
              MessageType.video
            ].contains(widget.message.contenu.type))
              _optionTile(Icons.download_rounded, 'Télécharger', Colors.blue,
                  () async {
                Navigator.pop(context);
                widget.onSave();
              }),
            _optionTile(
                Icons.delete_outline_rounded, 'Supprimer', AppTheme.accentColor,
                () {
              Navigator.pop(context);
              _showDeleteDialog(context);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.accentColor),
              SizedBox(width: 12),
              Text('Supprimer le message ?'),
            ],
          ),
          content: const Text('Cette action est irréversible.',
              style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                    style: TextStyle(color: Colors.grey.shade600))),
            ElevatedButton(
              onPressed: _isDeleting
                  ? null
                  : () async {
                      setState(() => _isDeleting = true);
                      try {
                        await widget.onDelete(widget.message.id);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Erreur de suppression')));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Supprimer'),
            ),
          ],
        ),
      ),
    );
  }
}
