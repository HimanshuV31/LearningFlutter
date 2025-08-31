import 'package:flutter/material.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
// import '../../services/crud/notes_service.dart';
import '../../services/platform/platform_utils.dart';

class NotesListView extends StatelessWidget {
  // final List<DatabaseNote> notes;
  // final Function(DatabaseNote) onLongPressNote;
  // final Function(DatabaseNote) onTapNote;
  final Iterable<CloudNote> notes;
  final Function(CloudNote) onTapNote;
  final Function(CloudNote) onLongPressNote;

  const NotesListView({
    super.key,
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
  });

  int _getCrossAxisCount() {
    if (PlatformUtils.isWeb ||
        PlatformUtils.isWindows ||
        PlatformUtils.isMacOS ||
        PlatformUtils.isLinux) return 3;
    return 1; // Mobile platforms
  }

  @override
  Widget build(BuildContext context) {
    final columns = _getCrossAxisCount();

    if (columns == 1) {
      // ListView for mobiles
      return ListView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.all(10),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          // final note = notes[index];
          final note = notes.elementAt(index);
          return NoteListTile(
            note: note,
            onTap: () => onTapNote(note),
            onLongPress: () => onLongPressNote(note),
          );
        },
      );
    } else {
      // GridView for desktop/web
      return GridView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.all(10),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.5,
        ),
        itemBuilder: (context, index) {
          final note = notes.elementAt(index);
          return NoteListTile(
            note: note,
            onTap: () => onTapNote(note),
            onLongPress: () => onLongPressNote(note),
          );
        },
      );
    }
  }
}

class NoteListTile extends StatelessWidget {
  // final DatabaseNote note;
  final CloudNote note;
  final  onTap;
  final  onLongPress;

  const NoteListTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF3993ad);
    const foregroundColor = Colors.white60;
    final hasText = note.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        color: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: const BorderSide(color: backgroundColor, width: 2),
        ),
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? "Untitled" : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              Text(
                note.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
