import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class VideoMessagePlayer extends StatefulWidget {
  final String videoUrl;

  const VideoMessagePlayer({super.key, required this.videoUrl});

  @override
  _VideoMessagePlayerState createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  ValueNotifier<Duration> _currentPosition = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true);

    _controller.addListener(() {
      _currentPosition.value = _controller.value.position;
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _currentPosition.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _enterFullScreen() {
  setState(() {
    _isFullScreen = true;
  });

  _controller.play(); // Jouer la vidéo avant de passer en plein écran

  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) => WillPopScope(
        onWillPop: () async {
          _controller.pause();
          setState(() {
            _isFullScreen = false;
          });
          return true; // Permettre le retour
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _exitFullScreen,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),
              _buildProgressBar(),
              FullScreenControls(
                isPlaying: _isPlaying,
                onPlayPause: _togglePlayPause,
                onStop: () {
                  _controller.pause();
                  _controller.seekTo(Duration.zero);
                  setState(() {
                    _isPlaying = false;
                  });
                  _exitFullScreen();
                },
                onExitFullScreen: _exitFullScreen,
                onDownload: _downloadVideo,
              ),
            ],
          ),
        ),
      ),
    ),
  ).then((_) {
    setState(() {
      _isPlaying = true;
    });
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
      builder: (context, value, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Text(
                _formatDuration(value),
                style: TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: value.inSeconds.toDouble(),
                  min: 0,
                  max: _controller.value.duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _controller.seekTo(Duration(seconds: value.toInt()));
                    });
                  },
                  activeColor: Colors.red,
                  inactiveColor: Colors.grey,
                ),
              ),
              Text(
                _formatDuration(_controller.value.duration),
                style: TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: _enterFullScreen,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  size: 64,
                  color: Colors.white,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Text(
                    _formatDuration(_controller.value.duration),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          )
        : CircularProgressIndicator();
  }

  Future<void> downloadFile(BuildContext context, String url, String type) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception("Impossible d'obtenir le répertoire de stockage externe.");
        }

        final downloadDirectory = Directory('${directory.path}/houatsapy/$type');

        if (!await downloadDirectory.exists()) {
          await downloadDirectory.create(recursive: true);
        }

        final fileName = url.split('/').last;
        final file = File('${downloadDirectory.path}/$fileName');

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          print('Fichier téléchargé à: ${file.path}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$type téléchargé sous le nom $fileName dans ${downloadDirectory.path}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec du téléchargement de $type')),
          );
        }
      } catch (e) {
        print('Erreur lors du téléchargement : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement : $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission de stockage refusée')),
      );
    }


  }
}

class FullScreenControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onExitFullScreen;
  final VoidCallback onDownload;

  FullScreenControls({
    required this.isPlaying,
    required this.onPlayPause,
    required this.onStop,
    required this.onExitFullScreen,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: onPlayPause,
          ),
          IconButton(
            icon: Icon(Icons.stop, color: Colors.white),
            onPressed: onStop,
          ),
          IconButton(
            icon: Icon(Icons.download, color: Colors.white),
            onPressed: onDownload,
          ),
        ],
      ),
    );

  }
}
