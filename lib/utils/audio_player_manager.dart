import 'package:audioplayers/audioplayers.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  factory AudioPlayerManager() {
    return _instance;
  }

  AudioPlayerManager._internal();

  AudioPlayer? _currentPlayer;

  void play(AudioPlayer player, String url) {
    _currentPlayer?.pause();
    _currentPlayer = player;
    player.play(UrlSource(url));
  }

  void pause() {
    _currentPlayer?.pause();
  }
}
