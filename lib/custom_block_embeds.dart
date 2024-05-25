import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'utils.dart';

class VoiceMemoEmbed extends CustomBlockEmbed {
  static const separator = ";";
  static const embedType = 'voiceMemo';

  final String _audioPath;
  // The total duration of the audio is encoded inside the data string
  // This is for preformance reaons, only having to read the metadata of the file then caching it
  final Duration? _duration;

  VoiceMemoEmbed._(embedData, this._audioPath, this._duration)
      : super(embedType, embedData);

  factory VoiceMemoEmbed.fromEmbedData(String embedData) {
    String audioPath, durationString;
    Duration? duration;

    try {
      [audioPath, durationString] = embedData.split(separator);
    } catch (_) {
      throw ArgumentError("Invalid embedData format");
    }

    try {
      if (durationString == "null") {
        duration = null;
      } else {
        duration = durationString.parseDuration();
      }
    } catch (_) {
      throw ArgumentError("Could not parse duration in embedData");
    }

    return VoiceMemoEmbed._(embedData, audioPath, duration);
  }

  static Future<VoiceMemoEmbed> fromPath(String audioPath) async {
    final player = AudioPlayer();
    await player.setUrl(audioPath);

    return VoiceMemoEmbed._(
      "$audioPath$separator${player.duration ?? "null"}",
      audioPath,
      player.duration,
    );
  }

  Duration? get duration => _duration;
  String get audioPath => _audioPath;
}

class VoiceMemoEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'voiceMemo';
  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final String embedData = node.value.data;
    final embed = VoiceMemoEmbed.fromEmbedData(embedData);
    final duration = embed.duration;
    final audioPath = embed.audioPath;

    return RecordingChip(
      duration: duration,
      textStyle: textStyle,
      audioPath: audioPath,
    );
  }
}

/// Widget that displays the audio recordings as chips. Also allows users to interact with an audio player
class RecordingChip extends StatefulWidget {
  const RecordingChip({
    super.key,
    required this.duration,
    required this.textStyle,
    required this.audioPath,
  });

  final Duration? duration;
  final TextStyle textStyle;
  final String audioPath;

  @override
  State<RecordingChip> createState() => _RecordingChipState();
}

class _RecordingChipState extends State<RecordingChip> {
  late AudioPlayer _player;
  StreamSubscription? _processingStateSubscription;

  @override
  void initState() {
    _player = AudioPlayer();
    _player.setUrl(widget.audioPath);

    _processingStateSubscription =
        _player.processingStateStream.listen((processState) {
      // Listen for [_player] completing the audio clip
      if (processState == ProcessingState.completed) {
        restartAudio();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _player.dispose();
    _processingStateSubscription?.cancel();

    super.dispose();
  }

  void playAudio() {
    setState(() {
      _player.play();
    });
  }

  void pauseAudio() {
    setState(() {
      _player.pause();
    });
  }

  void restartAudio() {
    setState(() {
      _player.seek(Duration.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: restartAudio,
      child: ActionChip(
        onPressed: _player.playing ? pauseAudio : playAudio,
        avatar: Icon(
          _player.playing ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
        ),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.red),
        label: TimeRemaining(
          player: _player,
          textStyle: widget.textStyle,
          totalDuration: widget.duration,
        ),
      ),
    );
  }
}

/// Widget that displays the time remaining in the audio clip as text
class TimeRemaining extends StatelessWidget {
  const TimeRemaining({
    super.key,
    required AudioPlayer player,
    required TextStyle textStyle,
    required Duration? totalDuration,
  })  : _player = player,
        _textStyle = textStyle,
        _totalDuration = totalDuration;

  final AudioPlayer _player;
  final TextStyle _textStyle;
  final Duration? _totalDuration;

  String _getText(AsyncSnapshot<Duration> snapshot) {
    if (_totalDuration == null) return '--:--';
    if (!snapshot.hasData) return _totalDuration.printDuration();
    return (_totalDuration - snapshot.data!).printDuration();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _player.positionStream,
      builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
        return Text(
          _getText(snapshot),
          style: _textStyle,
        );
      },
    );
  }
}
