import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:steps_recovery_flutter/features/mindfulness/models/mindfulness_models.dart';

class MindfulnessAudioSourceException implements Exception {
  final String userMessage;

  const MindfulnessAudioSourceException(this.userMessage);

  @override
  String toString() => userMessage;
}

/// Audio service for mindfulness playback
class MindfulnessAudioService extends ChangeNotifier {
  static final MindfulnessAudioService _instance =
      MindfulnessAudioService._internal();
  factory MindfulnessAudioService() => _instance;
  MindfulnessAudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  MindfulnessTrack? _currentTrack;
  MindfulnessPlayerState _state = MindfulnessPlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;

  // Getters
  MindfulnessTrack? get currentTrack => _currentTrack;
  MindfulnessPlayerState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  double get speed => _speed;

  bool get isPlaying => _state == MindfulnessPlayerState.playing;
  bool get isLoading => _state == MindfulnessPlayerState.loading;

  /// Initialize audio service
  Future<void> initialize() async {
    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      _updateState(state);
    });

    // Listen to position updates
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });
  }

  void _updateState(PlayerState playerState) {
    if (playerState.playing) {
      _state = MindfulnessPlayerState.playing;
    } else if (playerState.processingState == ProcessingState.loading ||
        playerState.processingState == ProcessingState.buffering) {
      _state = MindfulnessPlayerState.loading;
    } else if (playerState.processingState == ProcessingState.completed) {
      _state = MindfulnessPlayerState.completed;
    } else {
      _state = MindfulnessPlayerState.paused;
    }
    notifyListeners();
  }

  /// Set the current track
  Future<void> setTrack(MindfulnessTrack track) async {
    _currentTrack = track;
    _state = MindfulnessPlayerState.loading;
    notifyListeners();

    try {
      final sourceUrl = track.audioUrl.trim();
      final sourceUri = Uri.tryParse(sourceUrl);

      final hasValidHttpScheme =
          sourceUri != null &&
          (sourceUri.scheme == 'http' || sourceUri.scheme == 'https');
      final hasHost = sourceUri?.host.isNotEmpty ?? false;

      if (sourceUrl.isEmpty ||
          sourceUrl.contains('example.com') ||
          !hasValidHttpScheme ||
          !hasHost) {
        throw MindfulnessAudioSourceException(
          'This session does not have a playable audio source yet.',
        );
      }
      await _player.setUrl(sourceUrl);
      _state = MindfulnessPlayerState.idle;
      notifyListeners();
    } catch (e) {
      _state = MindfulnessPlayerState.error;
      notifyListeners();
      if (e is MindfulnessAudioSourceException) {
        rethrow;
      }
      throw MindfulnessAudioSourceException(
        'Could not load "${track.title}". Please check your internet connection and try again.',
      );
    }
  }

  /// Play current track
  Future<void> play() async {
    if (_currentTrack == null) return;

    try {
      await _player.play();
      _state = MindfulnessPlayerState.playing;
      notifyListeners();
    } catch (e) {
      _state = MindfulnessPlayerState.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Pause current track
  Future<void> pause() async {
    await _player.pause();
    _state = MindfulnessPlayerState.paused;
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> playPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _state = MindfulnessPlayerState.idle;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _player.setSpeed(_speed);
    notifyListeners();
  }

  /// Skip forward by seconds
  Future<void> skipForward([int seconds = 15]) async {
    final newPosition = _position + Duration(seconds: seconds);
    if (newPosition < _duration) {
      await seek(newPosition);
    }
  }

  /// Skip backward by seconds
  Future<void> skipBackward([int seconds = 15]) async {
    final newPosition = _position - Duration(seconds: seconds);
    if (newPosition > Duration.zero) {
      await seek(newPosition);
    }
  }

  /// Reset player
  Future<void> reset() async {
    await _player.stop();
    await _player.dispose();
    _currentTrack = null;
    _state = MindfulnessPlayerState.idle;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
