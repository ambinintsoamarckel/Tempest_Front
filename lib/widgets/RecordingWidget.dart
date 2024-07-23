import 'package:flutter/material.dart';
import 'dart:async';

class RecordingWidget extends StatefulWidget {
  const RecordingWidget({super.key});

  @override
  _RecordingWidgetState createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<RecordingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Timer _timer;
  late Stopwatch _stopwatch;
  late Timer _dotTimer;
  String _recordingTime = '00:00';
  String _dots = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(begin: Colors.red, end: Colors.red)
        .animate(_animationController);

    _stopwatch = Stopwatch();
    _startTimer();
    _startDotTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTime = _formatTime(_stopwatch.elapsed);
      });
    });
  }

  void _startDotTimer() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _dots += '.';
        if (_dots.length > 3) {
          _dots = '';
        }
      });
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    _dotTimer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.mic, // Remplacez par l'icône que vous souhaitez
                color: Colors.white,
                size: 30,
              ),
              Text(
                'Enregistrement $_dots',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              Text(
                _recordingTime,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
