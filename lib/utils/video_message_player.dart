import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_theme.dart';

class VideoMessagePlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onSave;

  const VideoMessagePlayer({
    super.key,
    required this.videoUrl,
    this.onSave,
  });

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;

  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showControls = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(false);
  final ValueNotifier<double> _sliderValue = ValueNotifier<double>(0.0);

  bool _isFullScreen = false;
  bool _isDraggingSlider = false;
  Timer? _hideTimer;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _startProgressTimer();
        }
      }).catchError((error) {
        debugPrint('❌ Erreur initialisation vidéo: $error');
      })
      ..setLooping(true);

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (!mounted) return;

    // Mise à jour du statut de lecture
    final isPlaying = _controller.value.isPlaying;
    if (_isPlaying.value != isPlaying) {
      _isPlaying.value = isPlaying;

      if (isPlaying) {
        _fadeController.forward();
        _startHideTimer();
      } else {
        _fadeController.reverse();
        _showControls.value = true;
        _hideTimer?.cancel();
      }
    }

    // Mise à jour du buffering
    final isBuffering = _controller.value.isBuffering;
    if (_isBuffering.value != isBuffering) {
      _isBuffering.value = isBuffering;
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted || !_controller.value.isInitialized) {
          timer.cancel();
          return;
        }

        // Ne pas mettre à jour si l'utilisateur drag le slider
        if (!_isDraggingSlider &&
            _controller.value.duration.inMilliseconds > 0) {
          final position = _controller.value.position.inMilliseconds.toDouble();
          final duration = _controller.value.duration.inMilliseconds.toDouble();
          _sliderValue.value = (position / duration).clamp(0.0, 1.0);
        }
      },
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _isPlaying.dispose();
    _showControls.dispose();
    _isBuffering.dispose();
    _sliderValue.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;

    HapticFeedback.lightImpact();

    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _enterFullScreen() {
    setState(() => _isFullScreen = true);

    // Garder l'état de lecture actuel
    final wasPlaying = _controller.value.isPlaying;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenVideoPlayer(
              controller: _controller,
              onExit: () {
                setState(() => _isFullScreen = false);
                Navigator.of(context).pop();
              },
              onSave: widget.onSave,
              formatDuration: _formatDuration,
              sliderValue: _sliderValue,
              isPlaying: _isPlaying,
              showControls: _showControls,
              isBuffering: _isBuffering,
              onTogglePlayPause: _togglePlayPause,
              onSliderChanged: _onSliderChanged,
              onSliderChangeStart: _onSliderChangeStart,
              onSliderChangeEnd: _onSliderChangeEnd,
              onToggleControls: _toggleControls,
              wasPlaying: wasPlaying,
            ),
          );
        },
      ),
    );
  }

  void _toggleControls() {
    HapticFeedback.selectionClick();
    _showControls.value = !_showControls.value;

    if (_showControls.value && _controller.value.isPlaying) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        _showControls.value = false;
      }
    });
  }

  void _onSliderChangeStart(double value) {
    _isDraggingSlider = true;
    _hideTimer?.cancel();
    HapticFeedback.selectionClick();
  }

  void _onSliderChanged(double value) {
    if (!_controller.value.isInitialized) return;

    // Mise à jour visuelle immédiate
    _sliderValue.value = value;
  }

  void _onSliderChangeEnd(double value) async {
    if (!_controller.value.isInitialized) return;

    HapticFeedback.mediumImpact();

    // Calculer la nouvelle position
    final duration = _controller.value.duration;
    final newPosition = duration * value;

    // Effectuer le seek
    await _controller.seekTo(newPosition);

    _isDraggingSlider = false;

    // Redémarrer le timer de masquage si la vidéo joue
    if (_controller.value.isPlaying) {
      _startHideTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: _enterFullScreen,
      child: Hero(
        tag: 'video_${widget.videoUrl}',
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vidéo
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),

                // Overlay gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),

                // Indicateur de buffering
                ValueListenableBuilder<bool>(
                  valueListenable: _isBuffering,
                  builder: (context, isBuffering, child) {
                    if (!isBuffering) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                    );
                  },
                ),

                // Bouton play central
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlaying,
                  builder: (context, isPlaying, child) {
                    if (isPlaying) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                ),

                // Durée en bas à droite
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          color: AppTheme.primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_controller.value.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[850]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chargement...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget fullscreen séparé pour de meilleures performances
class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onExit;
  final VoidCallback? onSave;
  final String Function(Duration) formatDuration;
  final ValueNotifier<double> sliderValue;
  final ValueNotifier<bool> isPlaying;
  final ValueNotifier<bool> showControls;
  final ValueNotifier<bool> isBuffering;
  final VoidCallback onTogglePlayPause;
  final Function(double) onSliderChanged;
  final Function(double) onSliderChangeStart;
  final Function(double) onSliderChangeEnd;
  final VoidCallback onToggleControls;
  final bool wasPlaying;

  const _FullScreenVideoPlayer({
    required this.controller,
    required this.onExit,
    required this.onSave,
    required this.formatDuration,
    required this.sliderValue,
    required this.isPlaying,
    required this.showControls,
    required this.isBuffering,
    required this.onTogglePlayPause,
    required this.onSliderChanged,
    required this.onSliderChangeStart,
    required this.onSliderChangeEnd,
    required this.onToggleControls,
    required this.wasPlaying,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  @override
  void initState() {
    super.initState();
    // Reprendre la lecture si la vidéo jouait avant
    if (widget.wasPlaying && !widget.controller.value.isPlaying) {
      widget.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: widget.onToggleControls,
          child: Stack(
            children: [
              // Vidéo centrée
              Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              ),

              // Indicateur de buffering
              ValueListenableBuilder<bool>(
                valueListenable: widget.isBuffering,
                builder: (context, isBuffering, child) {
                  if (!isBuffering) return const SizedBox.shrink();
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),

              // Contrôles
              ValueListenableBuilder<bool>(
                valueListenable: widget.showControls,
                builder: (context, show, child) {
                  return AnimatedOpacity(
                    opacity: show ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.2, 0.7, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeader(),
                          _buildBottomControls(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onExit();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressBar(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.isPlaying,
            builder: (context, isPlaying, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onTap: widget.onTogglePlayPause,
                    size: 32,
                  ),
                  _buildControlButton(
                    icon: Icons.stop_rounded,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.controller.pause();
                      widget.controller.seekTo(Duration.zero);
                      widget.onExit();
                    },
                  ),
                  if (widget.onSave != null)
                    _buildControlButton(
                      icon: Icons.download_rounded,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onSave!();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.sliderValue,
      builder: (context, value, child) {
        final duration = widget.controller.value.duration;
        final currentPosition = duration * value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                widget.formatDuration(currentPosition),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: value.clamp(0.0, 1.0),
                    onChangeStart: widget.onSliderChangeStart,
                    onChanged: widget.onSliderChanged,
                    onChangeEnd: widget.onSliderChangeEnd,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.formatDuration(duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 24,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}
