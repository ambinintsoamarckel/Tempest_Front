// lib/screens/direct/widgets/attachment_menu.dart
import 'package:flutter/material.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'package:mini_social_network/models/attachment_option.dart';

class AttachmentMenu extends StatelessWidget {
  final List<AttachmentOption> options;

  const AttachmentMenu({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    // Détection du thème actif
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de glissement
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Titre avec couleur adaptative
              Text(
                'Envoyer une pièce jointe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              // Options en grille
              Wrap(
                spacing: 16,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: options.map((opt) => _buildOption(context, opt)).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, AttachmentOption opt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: opt.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône avec effet glassmorphism
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        opt.color.withOpacity(0.15),
                        opt.color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: opt.color.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: opt.color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    opt.icon,
                    color: opt.color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                // Label avec couleur adaptative
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}