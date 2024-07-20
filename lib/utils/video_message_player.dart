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

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true);

    _controller.addListener(() {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) => Scaffold(
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
              _buildControls(),
            ],
          ),
        ),
      ),
    );
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
    return VideoProgressIndicator(
      _controller,
      allowScrubbing: true,
      colors: VideoProgressColors(
        playedColor: Colors.red,
        backgroundColor: Colors.grey,
      ),
    );
  }

  Widget _buildControls() {
    return Container(

      color: Colors.black54,
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,

            ),
            onPressed: _togglePlayPause,
          ),

          IconButton(
            icon: Icon(Icons.stop, color: Colors.white),
            onPressed: () {
              _controller.pause();
              _controller.seekTo(Duration.zero);
            },
          ),
          IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: _isFullScreen ? _exitFullScreen : _enterFullScreen,
          ),
          IconButton(
            icon: Icon(Icons.download, color: Colors.white),
            onPressed: _downloadVideo,

          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized

        ? GestureDetector(
            onTap: () {
              _controller.play();
              setState(() {
                _isPlaying = true;
              });
              _enterFullScreen();
            },
            child: Column(
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
                _buildProgressBar(),
                _buildControls(),
              ],
            ),
          )
        : const CircularProgressIndicator();
  }
}
