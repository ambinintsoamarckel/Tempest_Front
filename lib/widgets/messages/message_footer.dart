// lib/widgets/messages/message_footer.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

// Ajoute ce paramètre optionnel
class MessageFooter extends StatelessWidget {
  final DateTime date;
  final bool isContact;
  final bool? isSending;
  final bool? sendFailed;
  final bool isRead;
  final bool isGroup; // NOUVEAU

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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 11, color: Colors.grey.shade600),
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
    if (sendFailed == true) {
      return const Icon(Icons.error_outline,
          color: AppTheme.accentColor, size: 16);
    } else if (isSending == true) {
      return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2));
    } else if (isGroup) {
      return Icon(isRead ? Icons.done_all : Icons.done,
          color: isRead ? Colors.blue : Colors.grey.shade500, size: 16);
    } else {
      return Icon(isRead ? Icons.done_all : Icons.done,
          color: isRead ? AppTheme.secondaryColor : Colors.grey.shade500,
          size: 16);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat.Hm().format(date.add(const Duration(hours: 3)));
  }
}
