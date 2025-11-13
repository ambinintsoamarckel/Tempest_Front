// lib/screens/direct/widgets/attachment_menu.dart
import 'package:flutter/material.dart';
import 'direct_input_area.dart';

class AttachmentMenu extends StatelessWidget {
  final List<AttachmentOption> options;

  const AttachmentMenu({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!, curve: Curves.easeInOut),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: options.map((opt) => _buildOption(opt)).toList(),
        ),
      ),
    );
  }

  Widget _buildOption(AttachmentOption opt) {
    return InkWell(
      onTap: opt.onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: opt.color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(opt.icon, color: opt.color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(opt.label,
              style: TextStyle(
                  fontSize: 12, color: opt.color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
