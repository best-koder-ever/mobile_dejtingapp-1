import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:dejtingapp/theme/app_theme.dart';

/// Recording state machine.
enum RecorderState { idle, recording, sending }

/// Inline voice-note recorder that replaces the text input bar.
///
/// States:
/// - **idle**: Shows a mic [IconButton] (parent embeds this in the input row).
/// - **recording**: Waveform + timer + cancel (✕) + send (✓).
/// - **sending**: Circular progress spinner.
///
/// When the user taps send, [onSend] fires with the file path and duration.
class VoiceChatRecorder extends StatefulWidget {
  /// Called with (filePath, durationSeconds) when the user confirms the recording.
  final Future<void> Function(String filePath, double durationSeconds)? onSend;

  /// Called when recording is cancelled.
  final VoidCallback? onCancel;

  /// Optional [AudioRecorder] for dependency injection in tests.
  final AudioRecorder? recorder;

  const VoiceChatRecorder({
    super.key,
    this.onSend,
    this.onCancel,
    this.recorder,
  });

  @override
  State<VoiceChatRecorder> createState() => VoiceChatRecorderState();
}

class VoiceChatRecorderState extends State<VoiceChatRecorder> {
  late final AudioRecorder _recorder;
  RecorderState _state = RecorderState.idle;
  Timer? _timer;
  int _elapsedSeconds = 0;
  String? _filePath;
  static const int maxDurationSeconds = 60;

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorder ?? AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'voice_msg_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
      ),
      path: path,
    );

    _filePath = path;
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
      if (_elapsedSeconds >= maxDurationSeconds) {
        _finishRecording();
      }
    });
    setState(() => _state = RecorderState.recording);
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    // Clean up temp file
    if (_filePath != null) {
      final f = File(_filePath!);
      if (await f.exists()) await f.delete();
    }
    _filePath = null;
    setState(() {
      _state = RecorderState.idle;
      _elapsedSeconds = 0;
    });
    widget.onCancel?.call();
  }

  Future<void> _finishRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null || _elapsedSeconds < 1) {
      setState(() => _state = RecorderState.idle);
      return;
    }
    final duration = _elapsedSeconds.toDouble();
    setState(() => _state = RecorderState.sending);
    try {
      await widget.onSend?.call(path, duration);
    } finally {
      if (mounted) {
        setState(() {
          _state = RecorderState.idle;
          _elapsedSeconds = 0;
        });
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case RecorderState.idle:
        return IconButton(
          key: const Key('voice_mic_button'),
          icon: const Icon(Icons.mic, color: AppTheme.primaryColor),
          onPressed: startRecording,
          tooltip: 'Record voice message',
        );

      case RecorderState.recording:
        return Container(
          key: const Key('voice_recording_bar'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              // Cancel button
              IconButton(
                key: const Key('voice_cancel_button'),
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: _cancelRecording,
                tooltip: 'Cancel recording',
              ),
              // Waveform indicator (pulsing dot)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Timer
              Text(
                _formatTimer(_elapsedSeconds),
                key: const Key('voice_timer'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              // Send button
              IconButton(
                key: const Key('voice_send_button'),
                icon: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 32),
                onPressed: _finishRecording,
                tooltip: 'Send voice message',
              ),
            ],
          ),
        );

      case RecorderState.sending:
        return const Center(
          key: Key('voice_sending_spinner'),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        );
    }
  }
}
