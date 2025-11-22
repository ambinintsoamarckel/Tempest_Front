// lib/utils/audio_message_player.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'audio_player_manager.dart';
import '../theme/app_theme.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isContact;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    this.isContact = true,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _completeSubscription;
  late AnimationController _waveAnimController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      if (_isDisposed) return;

      _safeSetState(() => _isLoading = true);

      // Charger l'audio
      await _audioPlayer.setSourceUrl(widget.audioUrl);

      // Configuration des listeners AVANT d'attendre la durée
      _setupListeners();

      // Essayer d'obtenir la durée directement
      final duration = await _audioPlayer.getDuration();
      if (duration != null && duration > Duration.zero) {
        _safeSetState(() {
          _duration = duration;
          _isLoading = false;
          _hasError = false;
        });
        return;
      }

      // Sinon attendre l'événement avec timeout
      await _waitForDuration().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          // Si timeout, utiliser une durée par défaut
          if (_duration == Duration.zero) {
            _safeSetState(() {
              _duration = const Duration(minutes: 1);
              _isLoading = false;
            });
          }
        },
      );

      _safeSetState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('❌ Erreur initialisation audio: $e');
      _safeSetState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _waitForDuration() async {
    final completer = Completer<void>();

    final subscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (duration > Duration.zero && !completer.isCompleted) {
        _safeSetState(() => _duration = duration);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    try {
      await completer.future;
    } finally {
      await subscription.cancel();
    }
  }

  void _setupListeners() {
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _safeSetState(() => _position = position);
    });

    _stateSubscription?.cancel();
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      _safeSetState(() => _isPlaying = state == PlayerState.playing);
      if (_isPlaying && !_isDisposed) {
        _waveAnimController.repeat();
      } else if (!_isDisposed) {
        _waveAnimController.stop();
      }
    });

    _completeSubscription?.cancel();
    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) async {
      _safeSetState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
      if (!_isDisposed) {
        _waveAnimController.stop();
      }
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setSourceUrl(widget.audioUrl);
      } catch (e) {
        print('❌ Erreur reset audio: $e');
      }
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _waveAnimController.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_hasError || _isLoading || _isDisposed) return;

    if (_isPlaying) {
      _audioPlayer.pause();
      AudioPlayerManager().pause();
    } else {
      AudioPlayerManager().play(_audioPlayer, widget.audioUrl);
    }
  }

  void _seekToPosition(double progress) async {
    if (_duration == Duration.zero || _isDisposed) return;
    final position = Duration(
      milliseconds: (progress * _duration.inMilliseconds).round(),
    );
    try {
      await _audioPlayer.seek(position);
      _safeSetState(() => _position = position);
    } catch (e) {
      print('❌ Erreur seek: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Color get _backgroundColor {
    if (widget.isContact) {
      return Colors.white;
    }
    return AppTheme.primaryColor;
  }

  Color get _iconColor {
    if (widget.isContact) {
      return AppTheme.primaryColor;
    }
    return Colors.white;
  }

  Color get _waveColor {
    if (widget.isContact) {
      return AppTheme.primaryColor;
    }
    return Colors.white;
  }

  Color get _textColor {
    if (widget.isContact) {
      return Colors.grey.shade700;
    }
    return Colors.white.withOpacity(0.9);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: widget.isContact
            ? []
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Play/Pause
          _buildPlayButton(),
          const SizedBox(width: 8),
          // Waveform avec durée
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform
                GestureDetector(
                  onTapDown: (details) => _handleTap(details),
                  onHorizontalDragUpdate: (details) => _handleDrag(details),
                  child: SizedBox(
                    height: 32,
                    child: AnimatedBuilder(
                      animation: _waveAnimController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 32),
                          painter: WaveformPainter(
                            progress: progress,
                            barCount: 35,
                            color: _waveColor,
                            isPlaying: _isPlaying,
                            animationValue: _waveAnimController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Durée
                Text(
                  _isLoading
                      ? 'Chargement...'
                      : _formatDuration(_isPlaying ? _position : _duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.isContact
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_iconColor),
              ),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: _iconColor,
                size: 20,
              ),
              onPressed: _togglePlayPause,
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 8),
          Text(
            'Audio indisponible',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    if (_isDisposed) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = details.localPosition.dx;
    final width = box.size.width;
    final progress = (localPosition / width).clamp(0.0, 1.0);
    _seekToPosition(progress);
  }

  void _handleDrag(DragUpdateDetails details) {
    if (_isDisposed) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = details.localPosition.dx;
    final width = box.size.width;
    final progress = (localPosition / width).clamp(0.0, 1.0);
    _seekToPosition(progress);
  }
}

/// Painter pour la waveform style WhatsApp
class WaveformPainter extends CustomPainter {
  final double progress;
  final int barCount;
  final Color color;
  final bool isPlaying;
  final double animationValue;

  WaveformPainter({
    required this.progress,
    required this.barCount,
    required this.color,
    required this.isPlaying,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    final barWidth = 2.5;
    final spacing = (size.width - (barCount * barWidth)) / (barCount - 1);
    final maxHeight = size.height;

    // Hauteurs de barres variées pour un effet naturel
    final List<double> baseHeights = [
      0.4,
      0.7,
      0.5,
      0.9,
      0.3,
      0.8,
      0.6,
      0.5,
      0.7,
      0.4,
      0.9,
      0.6,
      0.8,
      0.5,
      0.7,
      0.4,
      0.6,
      0.8,
      0.5,
      0.7,
      0.4,
      0.9,
      0.6,
      0.5,
      0.8,
      0.7,
      0.4,
      0.6,
      0.9,
      0.5,
      0.7,
      0.3,
      0.8,
      0.6,
      0.5,
    ];

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final baseHeight = baseHeights[i % baseHeights.length];

      // Animation de pulsation pendant la lecture
      double animatedHeight = baseHeight;
      if (isPlaying) {
        final wave = (animationValue * 2 * 3.14159) + (i * 0.15);
        animatedHeight =
            baseHeight + (0.08 * (1 + (0.4 * (1 + (animationValue * 2 - 1)))));
      }

      final barHeight = maxHeight * animatedHeight.clamp(0.3, 1.0);
      final y = (maxHeight - barHeight) / 2;

      // Couleur selon la progression
      if (i / barCount <= progress) {
        paint.color = color;
      } else {
        paint.color = color.withOpacity(0.3);
      }

      canvas.drawLine(
        Offset(x + barWidth / 2, y),
        Offset(x + barWidth / 2, y + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.animationValue != animationValue;
  }
}
