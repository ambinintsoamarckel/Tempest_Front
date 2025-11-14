// lib/widgets/messages/message_footer.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class MessageFooter extends StatelessWidget {
  final DateTime date;
  final bool isContact;
  final bool? isSending;
  final bool? sendFailed;
  final bool isRead;
  final bool isGroup;

  const MessageFooter({
    super.key,
    required this.date,
    required this.isContact,
    this.isSending,
    this.sendFailed,
    required this.isRead,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: isContact ? Colors.grey.shade600 : Colors.white70,
                ),
          ),
          if (!isContact) ...[
            const SizedBox(width: 4),
            _buildStatusIcon(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    // ❌ Échec d'envoi
    if (sendFailed == true) {
      return const Icon(
        Icons.error_outline,
        color: Colors.redAccent,
        size: 16,
      );
    }

    // ⏳ En cours d'envoi
    if (isSending == true) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    }

    // ✅✅ Lu (double check bleu)
    if (isRead) {
      return Icon(
        Icons.done_all,
        color: isGroup ? Colors.blue : AppTheme.secondaryColor,
        size: 16,
      );
    }

    // ✅ Envoyé mais pas lu (simple check gris)
    return Icon(
      Icons.done,
      color: Colors.grey.shade400,
      size: 16,
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.Hm().format(date.add(const Duration(hours: 3)));
  }
}
