import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinity_notes/services/notes_actions/share_note.dart';
import 'package:infinity_notes/services/search/bloc/search_bloc.dart';
import 'package:infinity_notes/services/search/bloc/search_event.dart';
import 'package:infinity_notes/services/search/bloc/search_state.dart';
import 'package:infinity_notes/utilities/ai/ai_helper.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';

Future<String?> showNoteActionsDialog({
  required BuildContext context,
  required FirebaseCloudStorage notesService,
  required CloudNote note,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    note.title.isNotEmpty ? note.title : 'Select Action',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Divider(height: 20, thickness: 1),

              InkWell(
                onTap: () => Navigator.pop(context, 'ai_summary'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AIHelper.canSummarizeContent(note.text)
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'AI Summary',
                        style: TextStyle(
                          fontSize: 16,
                          color: AIHelper.canSummarizeContent(note.text)
                              ? null
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 20, thickness: 1),
              InkWell(
                onTap: () => Navigator.pop(context, 'share'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: const [
                      Icon(Icons.share, color: Colors.green),
                      SizedBox(width: 16),
                      Text('Share', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              InkWell(
                onTap: () => Navigator.pop(context, 'delete'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: const [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 16),
                      Text('Delete', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              // Add more options with same pattern here if needed

            ],
          ),
        ),
      );
    },
  );
}

Future<void> handleLongPressNote({
  required BuildContext context,
  required CloudNote note,
  required FirebaseCloudStorage notesService,
}) async {
  final action = await showNoteActionsDialog(
    context: context,
    notesService: notesService,
    note: note,
  );

  if (action == null) return; // user dismissed dialog

  switch (action) {
    case 'ai_summary':
      if (AIHelper.canSummarizeContent(note.text)) {
        AIHelper.handleSummarizeAction(
          context: context,
          content: note.text,
          title: note.title,
          onComplete: () {
            showCustomToast(context, "AI Summary created successfully!");
          },
        );
      } else {
        showCustomToast(context, "Note content is empty or too short to summarize");
      }
      break;
    case 'share':
      shareNote(note: note, context: context);
      break;
    case 'delete':
      final confirm = await showDeleteDialog(context: context);
      if (confirm) {
        await notesService.deleteNote(documentId: note.documentId);
        if (context.mounted) {
          final searchBloc = BlocProvider.of<SearchBloc>(context);
          final currentState = searchBloc.state;
          final updatedNotes = List<CloudNote>.from(searchBloc.allNotes)
            ..removeWhere((n) => n.documentId == note.documentId);
          searchBloc.add(SearchInitiated(updatedNotes));
          if (currentState is SearchResults) {
            searchBloc.add(SearchQueryChanged(currentState.query));
          }

          showCustomToast(context, "Note Deleted Successfully");
        }
      }
      break;
  // case 'archive':
    //   // Future feature handling
    //   break;
  } /*Switch case*/
}
