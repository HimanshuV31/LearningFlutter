import 'package:flutter/src/widgets/framework.dart';
import 'package:share_plus/share_plus.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';

Future<void> shareNote ({required CloudNote note, required BuildContext context})async {
    final content = 'Title: ${note.title}\n\n${note.text}';
    SharePlus.instance.share(
      ShareParams(
        text: content,
        title: 'Share Note',
        subject: note.title.isNotEmpty ? note.title : "Untitled Note",
      ),
    );
}