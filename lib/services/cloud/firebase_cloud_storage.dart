import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_note.dart';
import 'cloud_storage_constants.dart';
import 'cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  //Constants and Declarations
  final notes = FirebaseFirestore.instance.collection('notes');
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();

  //singleton constructor
  FirebaseCloudStorage._sharedInstance();

  factory FirebaseCloudStorage() => _shared;

  //Methods
  void createNewNote({required String ownerUserId}) async {
    try {
      notes.add({
        ownerUserIdFieldName: ownerUserId,
        titleFieldName: '',
        textFieldName: '',
      });
    } catch (e) {
      throw CouldNotCreateNoteException();
    }
  }

  Future<Iterable<CloudNote>> getNotes({required String ownerUserId}) async {
    try {
      return await notes
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .get()
          .then((value) {
            return value.docs.map((doc) {
              return CloudNote(
                documentId: doc.id,
                ownerUserId: doc.data()[ownerUserIdFieldName] as String,
                title: doc.data()[titleFieldName] as String,
                text: doc.data()[textFieldName] as String,
              );
            });
          });
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  Future<Stream<Iterable<CloudNote>>> allNotes({required String ownerUserId}) async {
    return notes.snapshots().map(
      (event) => event.docs
          .map((doc) => CloudNote.fromSnapshot(doc))
          .where((note) => note.ownerUserId == ownerUserId),
    );
  }

  Future<void> updateNote({
    required String documentId,
    required String title,
    required String text,
  }) async {
    try {
      await notes.doc(documentId).update({
        titleFieldName: title,
        textFieldName: text,
      });
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }
}
