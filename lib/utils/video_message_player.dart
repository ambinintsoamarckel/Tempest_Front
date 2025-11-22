import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';

class VideoMessagePlayer extends StatefulWidget {
  final String videoUrl;

  const VideoMessagePlayer({super.key, required this.videoUrl});

  @override
  _VideoMessagePlayerState createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animationController;
  ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  ValueNotifier<bool> _showControls = ValueNotifier<bool>(true);
  bool _isFullScreen = false;
  ValueNotifier<Duration> _currentPosition = ValueNotifier(Duration.zero);
  Timer? _hideTimer;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      })
      ..setLooping(true);

    _controller.addListener(_videoListener);

    // Timer pour mettre à jour la progression de manière fluide
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_controller.value.isInitialized && _controller.value.isPlaying) {
        _currentPosition.value = _controller.value.position;
      }
    });
  }

  void _videoListener() {
    if (!mounted) return;

    final isPlaying = _controller.value.isPlaying;
    if (_isPlaying.value != isPlaying) {
      _isPlaying.value = isPlaying;

      if (isPlaying) {
        _startHideTimer();
      } else {
        _showControls.value = true;
        _hideTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _currentPosition.dispose();
    _isPlaying.dispose();
    _showControls.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;

    if (_controller.value.isPlaying) {
      _controller.pause();
      _animationController.reverse();
    } else {
      _controller.play();
      _animationController.forward();
    }
  }

  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });

    _controller.play();

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (BuildContext context, _, __) => WillPopScope(
          onWillPop: () async {
            _controller.pause();
            setState(() {
              _isFullScreen = false;
            });
            return true;
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  _buildFullScreenControls(),
                ],
              ),
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isPlaying.value = _controller.value.isPlaying;
        });
      }
    });
  }

  void _exitFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
    Navigator.pop(context);
  }

  void _downloadVideo() {
    downloadFile(context, widget.videoUrl, "video");
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _currentPosition,
      builder: (context, position, child) {
        final duration = _controller.value.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final newPosition = duration * value;
                          _controller.seekTo(newPosition);
                          _currentPosition.value = newPosition;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _toggleControls() {
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

  Widget _buildFullScreenControls() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showControls,
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
                // Header avec bouton retour
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _exitFullScreen,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Contrôles en bas
                Column(
                  children: [
                    _buildProgressBar(),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isPlaying,
                      builder: (context, isPlaying, child) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlButton(
                                icon:
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                onTap: _togglePlayPause,
                                size: 32,
                              ),
                              _buildControlButton(
                                icon: Icons.stop,
                                onTap: () {
                                  _controller.pause();
                                  _controller.seekTo(Duration.zero);
                                  _currentPosition.value = Duration.zero;
                                  _exitFullScreen();
                                },
                              ),
                              _buildControlButton(
                                icon: Icons.file_download_outlined,
                                onTap: _downloadVideo,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
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

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: _enterFullScreen,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    // Overlay avec gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                    // Bouton play central
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
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
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam,
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
          )
        : Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[900],
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
          );
  }

  Future<void> downloadFile(
      BuildContext context, String url, String type) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception(
              "Impossible d'obtenir le répertoire de stockage externe.");
        }

        final downloadDirectory =
            Directory('${directory.path}/houatsapy/$type');

        if (!await downloadDirectory.exists()) {
          await downloadDirectory.create(recursive: true);
        }

        final fileName = url.split('/').last;
        final file = File('${downloadDirectory.path}/$fileName');

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Vidéo téléchargée avec succès',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.secondaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('Échec du téléchargement');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Erreur : ${e.toString()}'),
                ],
              ),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.block, color: Colors.white),
                SizedBox(width: 12),
                Text('Permission de stockage refusée'),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
