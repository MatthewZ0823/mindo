import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

//// Manages the loading, saving, and auto-saving of a Quill document.
class DocumentManager {
  /// The controller of the document to manage.
  final QuillController controller;

  /// Function that returns what date should be used for saving and loading documents.
  final DateTime Function() dateProvider;

  /// Creates a [DocumentManager] with the given [controller] and [dateProvider].
  DocumentManager(this.controller, this.dateProvider);

  StreamSubscription<DocChange>? _changeSubscription;
  Timer? _autoSaveTimer;

  static final _fileDateFormatter = DateFormat('y-m-d');

  /// Returns the directory where documents should be saved.
  Future<Directory> _getSaveDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = path.join(directory.path, "scratch_documents");

    return Directory(savePath);
  }

  /// Generates the name of the associated save file for the date returned by [dateProvider].
  String _generateSaveFileName() =>
      "${_fileDateFormatter.format(dateProvider())}.json";

  /// Loads the document assosiated with the date returned by [dateProvider].
  ///
  /// If the document exists, it is loaded into the [controller].
  /// If the document does not exist, a new document is created.
  void loadDocument() async {
    // TODO: Make UI do something when loading document
    final saveDir = await _getSaveDirectory();
    final file = File(path.join(saveDir.path, _generateSaveFileName()));

    try {
      final documentString = await file.readAsString();
      final json = jsonDecode(documentString);

      cancelAutoSave();
      controller.document = Document.fromJson(json);
    } on PathNotFoundException {
      controller.document = Document();
    }

    setupAutoSave();
  }

  /// Saves the current document to the file associated with the date returned by [dateProvider].
  void saveDocument() async {
    final jsonString = jsonEncode(controller.document.toDelta().toJson());

    final saveDir = await _getSaveDirectory();
    saveDir.create();

    final file = File(path.join(saveDir.path, _generateSaveFileName()));
    file.writeAsString(jsonString);
  }

  /// Sets up auto-saving for the document.
  ///
  /// Auto-save triggers after the specified [autoSaveDelay] duration following a document change.
  /// If no [autoSaveDelay] is provided, it defaults to 1 second.
  void setupAutoSave([Duration autoSaveDelay = const Duration(seconds: 1)]) {
    cancelAutoSave();

    _changeSubscription = controller.changes.listen(
      (DocChange change) {
        _autoSaveTimer?.cancel();
        _autoSaveTimer = Timer(autoSaveDelay, () => saveDocument());
      },
      cancelOnError: false,
    );
  }

  /// Cancels any active auto-save operations.
  ///
  /// Remember to cancel auto-save when it's no longer needed
  void cancelAutoSave() {
    _changeSubscription?.cancel();
  }
}
