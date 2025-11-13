// lib/screens/direct/widgets/message_date_badge.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mini_social_network/theme/app_theme.dart';

class MessageDateBadge extends StatelessWidget {
  final DateTime date;

  const MessageDateBadge({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppTheme.dateBadgeDecoration(context),
        child: Text(
          _formatDate(date),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDate).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return "Hier";
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(date);
  }
}
