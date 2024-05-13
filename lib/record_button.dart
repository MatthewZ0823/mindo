import 'package:flutter/material.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  bool isRecording = false;

  void toggleRecording() {
    setState(() {
      isRecording = !isRecording;
    });
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

    if (!isRecording) {
      return IconButton(
        style: style,
        onPressed: toggleRecording,
        icon: const Icon(Icons.mic),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            style: style,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {},
            icon: const Icon(Icons.pause),
          ),
          const SizedBox(width: 10),
          IconButton(
            style: style,
            color: Theme.of(context).colorScheme.primary,
            onPressed: toggleRecording,
            icon: const Icon(Icons.stop),
          ),
        ],
      );
    }
  }
}
