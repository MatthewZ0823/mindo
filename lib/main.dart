import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:mindo/custom_block_embeds.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
  final QuillController _controller = QuillController.basic();
  Timer? _autoSaveTimer;
  StreamSubscription<DocChange>? _changeSubscription;

  /// The date of the note
  DateTime _noteDate = DateTime.now().roundDownDate();

  static final _fileDateFormatter = DateFormat('y-m-d');

  late FocusNode _focusNode;

  void addDaysToNoteDate(int numDays) {
    final newDate = _noteDate.addDays(numDays);

    if (newDate.isAfter(DateTime.now())) return;

    setState(() {
      _noteDate = newDate;
    });
    _loadDocument();
  }

  void _setupAutoSave() {
    _changeSubscription?.cancel();
    _changeSubscription = _controller.changes.listen(
      (DocChange change) {
        print('changing');
        _autoSaveTimer?.cancel();
        _autoSaveTimer = Timer(const Duration(seconds: 1), _saveDocument);
      },
      onError: (e) => print(e),
      cancelOnError: false,
    );
  }

  @override
  void initState() {
    _focusNode = FocusNode();

    _loadDocument();
    _setupAutoSave();

    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _changeSubscription?.cancel();
    super.dispose();
  }

  String _getSaveFileName() => "${_fileDateFormatter.format(_noteDate)}.json";
  Future<Directory> _getSaveDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = path.join(directory.path, "mindo_documents");

    return Directory(savePath);
  }

  void _saveDocument() async {
    print('saving');
    final jsonString = jsonEncode(_controller.document.toDelta().toJson());

    final saveDir = await _getSaveDirectory();
    saveDir.create();

    final file = File(path.join(saveDir.path, _getSaveFileName()));
    file.writeAsString(jsonString);
  }

  void _loadDocument() async {
    final saveDir = await _getSaveDirectory();

    final file = File(path.join(saveDir.path, _getSaveFileName()));

    try {
      final documentString = await file.readAsString();
      final json = jsonDecode(documentString);

      _changeSubscription?.cancel();
      _controller.document = Document.fromJson(json);
      _setupAutoSave();
    } on PathNotFoundException {
      _controller.document = Document();
      _setupAutoSave();
    }
  }

  void handleRecordingStopped(String? audioPath) async {
    // TODO: Display something while loading myEmbed
    VoiceMemoEmbed myEmbed = await VoiceMemoEmbed.fromPath(audioPath ?? '');
    _controller.document.insert(_controller.selection.extentOffset, myEmbed);
    _focusNode.requestFocus();
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
            TextButton(onPressed: _saveDocument, child: const Text("save")),
            TextButton(onPressed: _loadDocument, child: const Text("load")),
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
