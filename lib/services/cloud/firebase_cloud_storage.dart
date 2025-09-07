import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/cloud/cloud_storage_constants.dart';
import 'package:infinity_notes/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  //Constants and Declarations
  final notes = FirebaseFirestore.instance.collection('notes');
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();

  //singleton constructor
  FirebaseCloudStorage._sharedInstance();

  factory FirebaseCloudStorage() => _shared;

  //Methods
  Future<CloudNote> createNewNote({
    required String ownerUserId,
    String title = "",
    String text = "",
  }) async {
    try {
      final document = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        titleFieldName: title,
        textFieldName: text,
      });

      final fetchedNote = await document.get();
      return CloudNote(
        documentId: fetchedNote.id,
        ownerUserId: ownerUserId,
        title: fetchedNote.data()![titleFieldName] ?? "",
        text: fetchedNote.data()![textFieldName] ?? "",
      );
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  // Future<Iterable<CloudNote>> getNotes({required String ownerUserId}) async {
  //   try {
  //     return await notes
  //         .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
  //         .get()
  //         .then((value) {
  //       return value.docs.map((doc) {
  //         return CloudNote.fromSnapshot(doc);
  //       });
  //     });
  //   } on FirebaseException catch (e) {
  //     if (e.plugin == "cloud_firestore") {
  //       throw CloudStorageException.fromCode(e.code);
  //     }
  //     rethrow;
  //   }
  // }

  Future<Stream<Iterable<CloudNote>>> allNotes({
    required String ownerUserId,
  }) async {
    final allNotes = notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) => event.docs.map((doc) => CloudNote.fromSnapshot(doc)));
    return allNotes;
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
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }
}
