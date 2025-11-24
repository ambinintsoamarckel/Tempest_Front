// lib/screens/direct/widgets/attachment_option.dart
import 'package:flutter/material.dart';

class AttachmentOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
