import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/material.dart';
import 'dart:convert' show jsonDecode, jsonEncode;

class VoiceMemoEmbed extends CustomBlockEmbed {
  const VoiceMemoEmbed(String value) : super(embedType, value);

  static const String embedType = 'voiceMemo';

  static VoiceMemoEmbed fromDocument(Document document) =>
      VoiceMemoEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document => Document.fromJson(jsonDecode(data));
  // Document get document => Document.fromHtml(data);
}

class VoiceMemoEmbedBuilder extends EmbedBuilder {
  VoiceMemoEmbedBuilder({required this.addEditNote});

  Future<void> Function(BuildContext context, {Document? document}) addEditNote;

  @override
  String get key => 'voiceMemo';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final notes = VoiceMemoEmbed(node.value.data).document;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          notes.toPlainText().replaceAll('\n', ' '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const Icon(Icons.notes),
        onTap: () => addEditNote(context, document: notes),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
