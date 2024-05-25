extension VoiceMemoDurationUtils on Duration {
  String printDuration() {
    String negativeSign = isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

extension VoiceMemoStringUtils on String {
  Duration parseDuration() {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }
}

extension DateUtils on DateTime {
  /// Rounds off the hours, minutes, seconds, and microseconds
  DateTime roundDownDate() {
    return DateTime(year, month, day);
  }

  DateTime addDays(int daysElapsed) {
    return DateTime(year, month, day + daysElapsed);
  }
}
