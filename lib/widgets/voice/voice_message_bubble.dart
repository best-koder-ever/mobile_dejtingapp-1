import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// A chat bubble that plays a voice message inline.
///
/// Shows play/pause, decorative waveform bars, duration, and timestamp.
/// Sender bubbles are coral/right-aligned; receiver bubbles are dark/left-aligned.
class VoiceMessageBubble extends StatefulWidget {
  /// URL (or local path) to the audio file.
  final String audioUrl;

  /// Duration of the voice clip in seconds.
  final double durationSeconds;

  /// Timestamp of the message (shown below the bubble).
  final DateTime timestamp;

  /// Whether this message was sent by the current user.
  final bool isSender;

  /// Optional [AudioPlayer] for dependency injection in tests.
  final AudioPlayer? player;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.timestamp,
    required this.isSender,
    this.player,
  });

  @override
  State<VoiceMessageBubble> createState() => VoiceMessageBubbleState();
}

class VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = widget.player ?? AudioPlayer();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      final completed =
          state.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = playing && !completed;
      });
      if (completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.duration == null) {
        await _player.setUrl(widget.audioUrl);
      }
      await _player.play();
    }
  }

  String _formatDuration(double seconds) {
    final total = seconds.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isSender ? AppTheme.primaryColor : AppTheme.surfaceElevated;
    final waveColor = widget.isSender
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.primaryColor.withValues(alpha: 0.6);
    final waveActiveColor = widget.isSender
        ? Colors.white
        : AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: widget.isSender
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play / Pause button
              GestureDetector(
                onTap: _toggle,
                child: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: widget.isSender ? Colors.white : AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(width: 8),
              // Waveform + duration
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWaveform(waveColor, waveActiveColor),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(widget.durationSeconds),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isSender
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(widget.timestamp),
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform(Color inactiveColor, Color activeColor) {
    const heights = [
      0.3, 0.5, 0.8, 0.4, 0.9, 0.6, 0.7, 0.5, 0.3, 0.7,
      0.95, 0.6, 0.4, 0.8, 0.5, 0.7, 0.3, 0.6, 0.9, 0.4,
    ];
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (i) {
          final h = heights[i] * 20;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 3,
            height: h,
            decoration: BoxDecoration(
              color: _isPlaying ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}
