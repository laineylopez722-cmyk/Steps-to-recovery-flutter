import 'package:flutter/material.dart';

/// Mindfulness track model
class MindfulnessTrack {
  final String id;
  final String title;
  final String description;
  final String category;
  final Duration duration;
  final String audioUrl;
  final MindfulnessCategory mindfulnessCategory;
  final bool isPremium;

  const MindfulnessTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.audioUrl,
    this.mindfulnessCategory = MindfulnessCategory.breathing,
    this.isPremium = false,
  });

  /// Get formatted duration string (e.g., "5:30")
  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Mindfulness categories
enum MindfulnessCategory {
  breathing('Breathing', Icons.air),
  bodyScan('Body Scan', Icons.accessibility_new),
  visualization('Visualization', Icons.image),
  grounding('Grounding', Icons.landscape),
  lovingKindness('Loving-Kindness', Icons.favorite),
  sleep('Sleep', Icons.bedtime),
  anxiety('Anxiety Relief', Icons.healing),
  craving('Craving Surfing', Icons.waves);

  final String displayName;
  final IconData icon;

  const MindfulnessCategory(this.displayName, this.icon);
}

/// Player state enum
enum MindfulnessPlayerState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Progress tracking for mindfulness tracks
class MindfulnessProgress {
  final String trackId;
  final String userId;
  final int timesCompleted;
  final Duration totalListenTime;
  final DateTime lastPlayedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MindfulnessProgress({
    required this.trackId,
    required this.userId,
    this.timesCompleted = 0,
    this.totalListenTime = Duration.zero,
    required this.lastPlayedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  MindfulnessProgress copyWith({
    String? trackId,
    String? userId,
    int? timesCompleted,
    Duration? totalListenTime,
    DateTime? lastPlayedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MindfulnessProgress(
      trackId: trackId ?? this.trackId,
      userId: userId ?? this.userId,
      timesCompleted: timesCompleted ?? this.timesCompleted,
      totalListenTime: totalListenTime ?? this.totalListenTime,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
