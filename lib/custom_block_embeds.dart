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
    final duration = VoiceMemoEmbed.fromEmbedData(embedData).duration;

    return Chip(
      avatar: const Icon(Icons.mic, color: Colors.black),
      backgroundColor: Colors.red,
      side: BorderSide.none,
      label: Text(duration == null ? "--:--" : _printDuration(duration)),
    );
  }
}
