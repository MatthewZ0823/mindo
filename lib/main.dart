import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mindo/custom_block_embeds.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'record_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Scratch'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _record = AudioRecorder();
  final QuillController _controller = QuillController.basic();

  Future<void> _addEditNote(BuildContext context, {Document? document}) async {
    final isEditing = document != null;
    final quillEditorController = QuillController(
      document: document ?? Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, top: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${isEditing ? 'Edit' : 'Add'} note'),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            )
          ],
        ),
        content: QuillEditor.basic(
          configurations: QuillEditorConfigurations(
            controller: quillEditorController,
            readOnly: false,
          ),
        ),
      ),
    );

    if (quillEditorController.document.isEmpty()) return;

    final block = BlockEmbed.custom(
      VoiceMemoEmbed.fromDocument(quillEditorController.document),
    );
    final controller = _controller;
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    if (isEditing) {
      final offset =
          getEmbedNode(controller, controller.selection.start).offset;
      controller.replaceText(
          offset, 1, block, TextSelection.collapsed(offset: offset));
    } else {
      controller.replaceText(index, length, block, null);
    }
  }

  addText() {
    jsonDecode("{}");
    setState(() {
      VoiceMemoEmbed myEmbed = VoiceMemoEmbed.fromDocument(Document());
      _controller.document
          .insert(_controller.selection.extentOffset, "hello world");
      _controller.document.insert(_controller.selection.extentOffset, myEmbed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  width: 80,
                  height: 4,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextButton(
              onPressed: () async {
                final player = AudioPlayer();
                await player
                    .setUrl('file:///C:/Users/emzee/Downloads/vine-boom.mp3');
                await player.play();
              },
              child: const Text("vine BOOM"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    final documentsDir =
                        await getApplicationDocumentsDirectory();

                    if (await _record.hasPermission()) {
                      await _record.start(
                        const RecordConfig(numChannels: 1),
                        path: "${documentsDir.path}/test_audio.m4a",
                      );
                    }
                  },
                  child: const Text("Start Recording"),
                ),
                TextButton(
                  onPressed: () async {
                    await _record.stop();
                  },
                  child: const Text("Stop Recording"),
                ),
              ],
            ),
            Expanded(
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _controller,
                  showCursor: true,
                  scrollable: true,
                  floatingCursorDisabled: true,
                  embedBuilders: [
                    VoiceMemoEmbedBuilder(addEditNote: _addEditNote)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Scratch'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'TODO'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: const RecordButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
