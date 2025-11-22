import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mini_social_network/theme/app_theme.dart';
import 'package:audioplayers/audioplayers.dart';

/// Bouton pour démarrer l'enregistrement
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

/// Interface d'enregistrement EN COURS
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton annuler
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
            tooltip: 'Annuler',
          ),
          const SizedBox(width: 8),

          // Zone principale avec animation
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1.5,
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
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),

                  // Durée
                  if (widget.showDuration) ...[
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton stop (valider)
          GestureDetector(
            onTap: widget.onStop,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎵 NOUVEAU : Preview audio APRÈS enregistrement (avant envoi)
class AudioPreviewWidget extends StatefulWidget {
  final String audioPath;
  final Duration duration;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const AudioPreviewWidget({
    Key? key,
    required this.audioPath,
    required this.duration,
    required this.onCancel,
    required this.onSend,
  }) : super(key: key);

  @override
  State<AudioPreviewWidget> createState() => _AudioPreviewWidgetState();
}

class _AudioPreviewWidgetState extends State<AudioPreviewWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.duration;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.audioPath));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton fermer
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _audioPlayer.stop();
              widget.onCancel();
            },
            tooltip: 'Annuler',
          ),
          const SizedBox(width: 8),

          // Zone de lecture audio
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Bouton play/pause
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Waveform/Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Barre de progression
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Durée
                        Text(
                          '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton send
          GestureDetector(
            onTap: () {
              _audioPlayer.stop();
              widget.onSend();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

