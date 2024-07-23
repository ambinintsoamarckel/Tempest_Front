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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = _controller.value.isPlaying;
    });
  }

  void _stopVideo() {
    setState(() {
      _controller.pause();
      _controller.seekTo(Duration.zero);
      _isPlaying = false;
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
    void _downloadVideo() {
    downloadFile(context, widget.videoUrl, "video");
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54, // Background color for better visibility
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              backgroundColor: Colors.grey,
            ),
          ),
          Row(
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
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: _stopVideo,
              ),
              IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullScreen,
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _downloadVideo,
              ),
              
            ],
          ),
        ],
      ),
    );
  }

Future<void> downloadFile(BuildContext context, String url, String type) async {
  // Demande la permission de stockage
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  if (status.isGranted) {
    try {
      // Obtenir le répertoire de stockage externe
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
      const SnackBar(content: Text('Permission de stockage refusée')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Column(
            children: [
              SizedBox(
                width: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      _buildControls(),
                    ],
                  ),
                ),
              ),
            ],
          )
        : const CircularProgressIndicator();
  }
}
