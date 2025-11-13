import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mini_social_network/theme/app_theme.dart';

/// Widget moderne pour l'enregistrement vocal
/// Utilisation simple dans DirectChatScreen
class VoiceRecordingButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final bool useModernMode;

  const VoiceRecordingButton({
    Key? key,
    required this.isRecording,
    required this.onStartRecording,
    this.useModernMode = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isRecording) return const SizedBox.shrink();

    return GestureDetector(
      onTap: useModernMode ? onStartRecording : null,
      onLongPressStart: !useModernMode ? (_) => onStartRecording() : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// Widget d'interface d'enregistrement actif
class RecordingInterface extends StatefulWidget {
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final bool showDuration;

  const RecordingInterface({
    Key? key,
    required this.onStop,
    required this.onCancel,
    this.showDuration = true,
  }) : super(key: key);

  @override
  State<RecordingInterface> createState() => _RecordingInterfaceState();
}

class _RecordingInterfaceState extends State<RecordingInterface>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showDuration) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _recordingDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Indicateur de pulsation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Durée ou texte
          if (widget.showDuration) ...[
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 8),
          ],

          const Text(
            'Enregistrement...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),

          // Bouton Annuler
          _buildActionButton(
            icon: Icons.close,
            color: AppTheme.accentColor,
            onPressed: widget.onCancel,
            tooltip: 'Annuler',
          ),
          const SizedBox(width: 8),

          // Bouton Envoyer
          _buildActionButton(
            icon: Icons.check,
            color: AppTheme.secondaryColor,
            onPressed: widget.onStop,
            tooltip: 'Valider',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
