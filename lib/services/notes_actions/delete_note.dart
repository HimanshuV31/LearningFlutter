import 'package:flutter/material.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';

Future<void> deleteNote({
required BuildContext context,
required CloudNote note,
required FirebaseCloudStorage notesService,
})async {
    final confirm = await showDeleteDialog(context: context);
    if(confirm){
      await notesService.deleteNote(documentId: note.documentId);
      showCustomToast(context, "Note Deleted Successfully");
      Navigator.pop(context);
    }
}