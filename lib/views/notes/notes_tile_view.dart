import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/platform/platform_utils.dart';
import 'package:infinity_notes/utilities/generics/ui/linkify_text.dart';

// ✅ CONVERTED: Regular NotesTileView (keep this for other uses)
class NotesTileView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final Function(CloudNote) onTapNote;
  final Function(CloudNote) onLongPressNote;

  const NotesTileView({
    super.key,
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
  });

  int _getCrossAxisCount() {
    if (PlatformUtils.isWeb ||
        PlatformUtils.isWindows ||
        PlatformUtils.isMacOS ||
        PlatformUtils.isLinux) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: _getCrossAxisCount(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      itemCount: notes.length,
      padding: const EdgeInsets.all(10),
      physics: const AlwaysScrollableScrollPhysics(), // ✅ FIXED: Enable scrolling
      itemBuilder: (context, index) {
        final note = notes.elementAt(index);
        return _NoteTile(
          note: note,
          onTap: () => onTapNote(note),
          onLongPress: () => onLongPressNote(note),
        );
      },
    );
  }
}

// ✅ NEW: Sliver version for CustomScrollView
class SliverNotesTileView extends StatelessWidget {
  final Iterable<CloudNote> notes;
  final Function(CloudNote) onTapNote;
  final Function(CloudNote) onLongPressNote;

  const SliverNotesTileView({
    super.key,
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
  });

  int _getCrossAxisCount() {
    if (PlatformUtils.isWeb ||
        PlatformUtils.isWindows ||
        PlatformUtils.isMacOS ||
        PlatformUtils.isLinux) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final notesList = notes.toList();

    // ✅ SLIVER MASONRY GRID: Proper scrolling in CustomScrollView
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: _getCrossAxisCount(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childCount: notesList.length,
        itemBuilder: (context, index) {
          final note = notesList[index];
          return _NoteTile(
            note: note,
            onTap: () => onTapNote(note),
            onLongPress: () => onLongPressNote(note),
          );
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, this.onTap, this.onLongPress});

  final CloudNote note;
  static const maxTextLines = 10;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF3993ad);
    const foregroundColor = Colors.white60;
    final hasText = note.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12), // ✅ ADDED: Internal padding
        decoration: BoxDecoration(
          color: foregroundColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: backgroundColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(1, 1),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              note.title.isEmpty ? "Untitled" : note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
              ),
            ),
            if (hasText) ...[
              const SizedBox(height: 8),
              LinkifyText(
                note.text,
                maxLines: maxTextLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black,
                    height: 1.3,
                ),
              ),
            ],
            // ✅ ADDED: Show timestamp
            if (note.timeAgo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
