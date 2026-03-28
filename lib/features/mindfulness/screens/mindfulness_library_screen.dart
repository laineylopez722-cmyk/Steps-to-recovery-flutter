import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/mindfulness_models.dart';
import '../services/mindfulness_audio_service.dart';

/// Mindfulness Library - Browse and play mindfulness tracks
class MindfulnessLibraryScreen extends StatefulWidget {
  const MindfulnessLibraryScreen({super.key});

  @override
  State<MindfulnessLibraryScreen> createState() =>
      _MindfulnessLibraryScreenState();
}

class _MindfulnessLibraryScreenState extends State<MindfulnessLibraryScreen> {
  MindfulnessCategory? _selectedCategory;
  bool _showPlayer = false;

  final List<MindfulnessTrack> _tracks = [
    const MindfulnessTrack(
      id: 'breath-1',
      title: 'Deep Breathing',
      description: 'Simple deep breathing exercise for calm and centering',
      category: 'Breathing',
      duration: Duration(minutes: 3, seconds: 30),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      mindfulnessCategory: MindfulnessCategory.breathing,
    ),
    const MindfulnessTrack(
      id: 'breath-2',
      title: 'Box Breathing',
      description: '4-4-4-4 breathing pattern for stress relief',
      category: 'Breathing',
      duration: Duration(minutes: 5),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      mindfulnessCategory: MindfulnessCategory.breathing,
    ),
    const MindfulnessTrack(
      id: 'body-1',
      title: 'Quick Body Scan',
      description: '5-minute progressive relaxation',
      category: 'Body Scan',
      duration: Duration(minutes: 5),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      mindfulnessCategory: MindfulnessCategory.bodyScan,
    ),
    const MindfulnessTrack(
      id: 'body-2',
      title: 'Full Body Scan',
      description: 'Complete head-to-toe body awareness',
      category: 'Body Scan',
      duration: Duration(minutes: 15),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      mindfulnessCategory: MindfulnessCategory.bodyScan,
    ),
    const MindfulnessTrack(
      id: 'ground-1',
      title: '5-4-3-2-1 Grounding',
      description: 'Classic grounding technique for anxiety',
      category: 'Grounding',
      duration: Duration(minutes: 4),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      mindfulnessCategory: MindfulnessCategory.grounding,
    ),
    const MindfulnessTrack(
      id: 'crave-1',
      title: 'Craving Surf',
      description: 'Ride the wave of craving without acting',
      category: 'Craving Surfing',
      duration: Duration(minutes: 10),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      mindfulnessCategory: MindfulnessCategory.craving,
    ),
    const MindfulnessTrack(
      id: 'sleep-1',
      title: 'Sleep Relaxation',
      description: 'Drift off with gentle guidance',
      category: 'Sleep',
      duration: Duration(minutes: 20),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      mindfulnessCategory: MindfulnessCategory.sleep,
      isPremium: true,
    ),
    const MindfulnessTrack(
      id: 'anxiety-1',
      title: 'Anxiety SOS',
      description: 'Quick relief for acute anxiety',
      category: 'Anxiety Relief',
      duration: Duration(minutes: 7),
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      mindfulnessCategory: MindfulnessCategory.anxiety,
    ),
  ];

  List<MindfulnessTrack> get _filteredTracks {
    if (_selectedCategory == null) return _tracks;
    return _tracks
        .where((track) => track.mindfulnessCategory == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindfulness'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(),

          // Track list
          Expanded(
            child: _filteredTracks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _filteredTracks.length,
                    itemBuilder: (context, index) {
                      final track = _filteredTracks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _TrackCard(
                          track: track,
                          onTap: () => _playTrack(track),
                        ),
                      );
                    },
                  ),
          ),

          // Mini player if a track is loaded
          if (_showPlayer) const _MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _CategoryChip(
            label: 'All',
            icon: Icons.all_inclusive,
            isSelected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...MindfulnessCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _CategoryChip(
                label: category.displayName,
                icon: category.icon,
                isSelected: _selectedCategory == category,
                onTap: () => setState(() => _selectedCategory = category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.mediation_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No tracks in this category',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playTrack(MindfulnessTrack track) async {
    try {
      await MindfulnessAudioService().setTrack(track);
      await MindfulnessAudioService().play();
      setState(() => _showPlayer = true);
    } catch (e) {
      final message = e is MindfulnessAudioSourceException
          ? e.userMessage
          : 'Unable to start this track right now. Please try again.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _TrackCard extends StatelessWidget {
  final MindfulnessTrack track;
  final VoidCallback onTap;

  const _TrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      track.mindfulnessCategory == MindfulnessCategory.craving
                      ? AppColors.info.withValues(alpha: 0.2)
                      : AppColors.primaryAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  track.mindfulnessCategory.icon,
                  color:
                      track.mindfulnessCategory == MindfulnessCategory.craving
                      ? AppColors.info
                      : AppColors.primaryAmber,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.title,
                            style: AppTypography.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (track.isPremium) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAmber,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      track.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      track.durationFormatted,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Play button
              const Icon(
                Icons.play_circle_filled,
                color: AppColors.primaryAmber,
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryAmber.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryAmber,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryAmber : AppColors.textPrimary,
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MindfulnessAudioService(),
      builder: (context, _) {
        final service = MindfulnessAudioService();
        final track = service.currentTrack;

        if (track == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatPosition(service.position),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    service.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: service.playPause,
                  color: AppColors.primaryAmber,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    service.stop();
                    // In a real implementation, we'd update parent state
                  },
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPosition(Duration position) {
    final minutes = position.inMinutes;
    final seconds = position.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
