import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecorderUtil {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _filePath;

  AudioRecorderUtil() {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
  }

  Future<void> init() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  Future<void> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder!.startRecorder(toFile: _filePath);
  }

  Future<String?> stopRecording() async {
    await _recorder!.stopRecorder();
    return _filePath;
  }

  Future<void> playAudio(String filePath) async {
    await _player!.startPlayer(fromURI: filePath);
  }

  Future<void> stopAudio() async {
    await _player!.stopPlayer();
  }

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
  }
}
