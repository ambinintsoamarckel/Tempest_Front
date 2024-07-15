import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'audio_player_manager.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;

  AudioMessagePlayer({required this.audioUrl});

  @override
  _AudioMessagePlayerState createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isSeeking = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSourceUrl(widget.audioUrl);
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });
    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        if (!_isSeeking) {
          _position = p;
        }
      });
    });
    _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      setState(() {
        _isPlaying = s == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      AudioPlayerManager().play(_audioPlayer, widget.audioUrl);
    }
  }

  void _seekToPosition(double progress) async {
    setState(() {
      _isSeeking = true;
    });
    final position = Duration(milliseconds: (progress * _duration.inMilliseconds).round());
    await _audioPlayer.seek(position);
    setState(() {
      _isSeeking = false;
      _position = position;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final progress = _position.inMilliseconds / (_duration.inMilliseconds + 1);
    int barCount = 15;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 200, 230, 202),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            onPressed: _togglePlayPause,
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final progress = localPosition.dx / box.size.width;
                _seekToPosition(progress);
              },
              onTapUp: (details) {
                RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final progress = localPosition.dx / box.size.width;
                _seekToPosition(progress);
              },
              child: Waveform(
                progress: progress,
                barCount: barCount,
              ),
            ),
          ),
          Text(
            _formatDuration(_duration),
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final int barCount;

  WaveformPainter({required this.progress, required this.barCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    final barWidth = (size.width - (barCount - 1) * 4) / barCount;
    final maxHeight = size.height;
    final barHeights = [0.6, 0.9, 0.5, 0.8, 0.4, 0.7, 0.3, 0.6, 0.9, 0.5, 0.8, 0.4, 0.7, 0.3, 0.6, 0.9, 0.5, 0.8, 0.4, 0.7];

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 4);
      final barHeight = maxHeight * barHeights[i % barHeights.length];
      final y = (maxHeight - barHeight) / 2;

      paint.color = i / barCount <= progress ? Colors.white : Colors.white.withOpacity(0.5);

      canvas.drawLine(Offset(x, y), Offset(x, y + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.barCount != barCount;
  }
}

class Waveform extends StatelessWidget {
  final double progress;
  final int barCount;

  Waveform({required this.progress, required this.barCount});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, 40),
      painter: WaveformPainter(progress: progress, barCount: barCount),
    );
  }
}
