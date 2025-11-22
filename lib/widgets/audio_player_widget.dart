// lib/widgets/audio_player_widget.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget audio player réutilisable et modulaire
class AudioPlayerWidget extends StatefulWidget {
  final File audioFile;
  final Color? primaryColor;
  final double height;
  final bool showFileName;

  const AudioPlayerWidget({
    super.key,
    required this.audioFile,
    this.primaryColor,
    this.height = 60,
    this.showFileName = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AudioPlayerController(widget.audioFile);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).primaryColor;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: _controller.hasError
              ? _buildError(color)
              : Row(
                  children: [
                    _buildPlayButton(color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildProgressSection(color),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPlayButton(Color color) {
    return GestureDetector(
      onTap: _controller.isInitialized ? _controller.togglePlayPause : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: _controller.isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(
                _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                color: color,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildProgressSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.showFileName) ...[
          Text(
            _controller.fileName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
        ],
        // Barre de progression avec clé pour gérer la largeur
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (details) =>
                  _handleProgressTap(details, constraints.maxWidth),
              onHorizontalDragUpdate: (details) =>
                  _handleProgressDrag(details, constraints.maxWidth),
              child: SizedBox(
                width: constraints.maxWidth,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _controller.progress,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        // Durée
        Text(
          _controller.durationText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildError(Color color) {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Impossible de lire ce fichier audio',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleProgressTap(TapDownDetails details, double width) {
    if (!_controller.isInitialized) return;

    final localPosition = details.localPosition.dx;
    final value = (localPosition / width).clamp(0.0, 1.0);
    _controller.seekTo(value);
  }

  void _handleProgressDrag(DragUpdateDetails details, double width) {
    if (!_controller.isInitialized) return;

    final localPosition = details.localPosition.dx;
    final value = (localPosition / width).clamp(0.0, 1.0);
    _controller.seekTo(value);
  }
}

/// Contrôleur audio séparé pour une meilleure modularité
class AudioPlayerController extends ChangeNotifier {
  final File audioFile;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  AudioPlayerController(this.audioFile);

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  String get fileName => audioFile.path.split('/').last;

  String get durationText {
    if (!_isInitialized && _isLoading) return 'Chargement...';
    if (!_isInitialized) return '00:00';
    return '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}';
  }

  /// Initialise l'audio player
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // ✅ Méthode alternative pour obtenir la durée
      await _audioPlayer.setSourceDeviceFile(audioFile.path);

      // Timeout de 3 secondes pour la durée
      await Future.any([
        _waitForDuration(),
        Future.delayed(const Duration(seconds: 3)),
      ]);

      // Si après 3s on n'a toujours pas la durée, on essaie de la récupérer manuellement
      if (_totalDuration == Duration.zero) {
        final duration = await _audioPlayer.getDuration();
        if (duration != null && duration > Duration.zero) {
          _totalDuration = duration;
        } else {
          // Fallback: estimer la durée en fonction de la taille du fichier
          _totalDuration = _estimateDuration();
        }
      }

      _setupListeners();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur initialisation audio: $e');
      _hasError = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Attend que la durée soit disponible
  Future<void> _waitForDuration() async {
    final completer = Completer<void>();
    final subscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (duration > Duration.zero && !completer.isCompleted) {
        _totalDuration = duration;
        completer.complete();
      }
    });

    await completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => subscription.cancel(),
    );
    subscription.cancel();
  }

  /// Estime la durée basée sur la taille du fichier (fallback)
  Duration _estimateDuration() {
    try {
      final bytes = audioFile.lengthSync();
      // Estimation grossière: ~128kbps pour MP3
      final seconds = (bytes / 16000).round();
      return Duration(seconds: seconds);
    } catch (e) {
      return const Duration(minutes: 1); // Durée par défaut
    }
  }

  /// Configure les listeners
  void _setupListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (duration > Duration.zero) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) async {
      _isPlaying = false;
      _currentPosition = _totalDuration;
      notifyListeners();

      // ✅ Réinitialiser le player pour permettre une nouvelle lecture
      await _audioPlayer.stop();
      await _audioPlayer.setSourceDeviceFile(audioFile.path);
    });
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (!_isInitialized) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Si on est à la fin, on recommence depuis le début
        if (_currentPosition >=
            _totalDuration - const Duration(milliseconds: 100)) {
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.resume();
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('❌ Erreur play/pause: $e');
      // En cas d'erreur, on essaie de relancer complètement
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
      } catch (e2) {
        print('❌ Erreur relance audio: $e2');
      }
    }
  }

  /// Seek to position (0.0 to 1.0)
  Future<void> seekTo(double value) async {
    if (!_isInitialized || _totalDuration == Duration.zero) return;

    try {
      final position = Duration(
        milliseconds: (value * _totalDuration.inMilliseconds).toInt(),
      );
      await _audioPlayer.seek(position);
    } catch (e) {
      print('❌ Erreur seek: $e');
    }
  }

  /// Formate une durée en MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
