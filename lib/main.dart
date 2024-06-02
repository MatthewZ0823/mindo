import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:scratch/custom_block_embeds.dart';
import 'package:scratch/document_manager.dart';

import 'date_controller.dart';
import 'record_button.dart';
import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scratch',
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
  final QuillController _controller = QuillController.basic();

  /// The date of the note
  DateTime _noteDate = DateTime.now().roundDownDate();

  late FocusNode _focusNode;
  late DocumentManager _documentManager;

  void addDaysToNoteDate(int numDays) {
    final newDate = _noteDate.addDays(numDays);

    if (newDate.isAfter(DateTime.now())) return;

    setState(() {
      _noteDate = newDate;
    });
    _documentManager.loadDocument();
  }

  @override
  void initState() {
    _focusNode = FocusNode();
    _documentManager = DocumentManager(_controller, () => _noteDate);

    _documentManager.loadDocument();
    _documentManager.setupAutoSave();

    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _documentManager.cancelAutoSave();

    super.dispose();
  }

  void handleRecordingStopped(String? audioPath) async {
    // TODO: Display something while loading myEmbed
    VoiceMemoEmbed myEmbed = await VoiceMemoEmbed.fromPath(audioPath ?? '');
    setState(() {
      _controller.document.insert(_controller.selection.extentOffset, myEmbed);
      _focusNode.requestFocus();
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
            DateController(
              onLeftArrowPressed: () => addDaysToNoteDate(-1),
              onRightArrowPressed: () => addDaysToNoteDate(1),
              date: _noteDate,
            ),
            Expanded(
              child: QuillEditor.basic(
                focusNode: _focusNode,
                configurations: QuillEditorConfigurations(
                  expands: true,
                  controller: _controller,
                  showCursor: true,
                  scrollable: true,
                  floatingCursorDisabled: true,
                  embedBuilders: [VoiceMemoEmbedBuilder()],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: RecordButton(
        onRecordingStopped: handleRecordingStopped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
