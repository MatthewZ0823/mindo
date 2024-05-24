import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

String _printDuration(Duration duration) {
  String negativeSign = duration.isNegative ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

Duration parseDuration(String s) {
  int hours = 0;
  int minutes = 0;
  int micros;
  List<String> parts = s.split(':');
  if (parts.length > 2) {
    hours = int.parse(parts[parts.length - 3]);
  }
  if (parts.length > 1) {
    minutes = int.parse(parts[parts.length - 2]);
  }
  micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
  return Duration(hours: hours, minutes: minutes, microseconds: micros);
}

class VoiceMemoEmbed extends CustomBlockEmbed {
  static const separator = ";";
  static const embedType = 'voiceMemo';

  final String _audioPath;
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
        duration = parseDuration(durationString);
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
  StreamSubscription? playingSubscription;

  @override
  void initState() {
    _player = AudioPlayer();
    _player.setUrl(widget.audioPath);

    playingSubscription = _player.playingStream.listen((playing) {
      // Listen for [_player] auto stopping after recording is finished
      if (!playing) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _player.dispose();
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
      _player.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This exists so promoting [duration] is possible
    final $duration = widget.duration;

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
        label: Text(
          $duration == null ? "--:--" : _printDuration($duration),
          style: widget.textStyle,
        ),
      ),
    );
  }
}
