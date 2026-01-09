import 'package:video_player/video_player.dart';

class VideoService {
  static VideoPlayerController? _controller;
  static bool _isInitialized = false;

  static Future<void> preloadVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/images/introjj.mp4');
      await _controller!.initialize();
      _controller!.setLooping(true);
      _isInitialized = true;
    } catch (e) {
      print('Video preload failed: $e');
      _isInitialized = false;
    }
  }

  static VideoPlayerController? get controller => _controller;
  static bool get isInitialized => _isInitialized;

  static void play() {
    if (_isInitialized && _controller != null) {
      _controller!.play();
    }
  }

  static void pause() {
    if (_isInitialized && _controller != null) {
      _controller!.pause();
    }
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}