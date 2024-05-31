import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class RecordButton extends StatefulWidget {
  final void Function(String? audioPath) onRecordingStopped;

  const RecordButton({super.key, required this.onRecordingStopped});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  final _recorder = AudioRecorder();
  RecordState _recordState = RecordState.stop;

  @override
  void initState() {
    _recorder.onStateChanged().listen((recordState) {
      setState(() {
        _recordState = recordState;
      });
    });
    super.initState();
  }

  void handleRecord() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final scratchPath = path.join(documentsDir.path, "scratch_recordings");
    final scratchDir = await Directory(scratchPath).create();

    final now = DateTime.now();
    final fileName =
        "${now.year}-${now.month}-${now.day}--${now.hour}-${now.minute}-${now.second}.m4a";

    final audioPath = path.join(scratchDir.path, fileName);

    if (await _recorder.hasPermission()) {
      await _recorder.start(
        const RecordConfig(numChannels: 1),
        path: audioPath,
      );
    }
  }

  void togglePause() async {
    if (_recordState == RecordState.pause) {
      await _recorder.resume();
    } else if (_recordState == RecordState.record) {
      await _recorder.pause();
    }
  }

  void handleStop() async {
    final audioPath = await _recorder.stop();
    widget.onRecordingStopped(audioPath);
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      iconSize: const MaterialStatePropertyAll(30),
      fixedSize: const MaterialStatePropertyAll(Size.square(56)),
      iconColor: MaterialStatePropertyAll(
          Theme.of(context).colorScheme.onPrimaryContainer),
      backgroundColor: MaterialStatePropertyAll(
          Theme.of(context).colorScheme.primaryContainer),
      shape: const MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );

    if (_recordState == RecordState.stop) {
      return IconButton(
        style: style,
        onPressed: handleRecord,
        icon: const Icon(Icons.mic),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          style: style,
          color: Theme.of(context).colorScheme.primary,
          onPressed: togglePause,
          icon: (_recordState == RecordState.pause)
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.pause),
        ),
        const SizedBox(width: 10),
        IconButton(
          style: style,
          color: Theme.of(context).colorScheme.primary,
          onPressed: handleStop,
          icon: const Icon(Icons.stop),
        ),
      ],
    );
  }
}
