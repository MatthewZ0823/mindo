import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
  });

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

  void onRecord() async {
    final documentsDir = await getApplicationDocumentsDirectory();

    if (await _recorder.hasPermission()) {
      await _recorder.start(
        const RecordConfig(numChannels: 1),
        path: "${documentsDir.path}/test_audio.m4a",
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

  void onStop() async {
    await _recorder.stop();
  }

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      iconSize: const MaterialStatePropertyAll(48),
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
        onPressed: onRecord,
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
          onPressed: onStop,
          icon: const Icon(Icons.stop),
        ),
      ],
    );
  }
}
