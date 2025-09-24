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

  // ✅ UPDATED: Add optional links parameter
  Future<CloudNote> createNewNote({
    required String ownerUserId,
    String title = "",
    String text = "",
    List<String>? links, // ✅ ADD: Optional links parameter
  }) async {
    try {
      final document = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        titleFieldName: title,
        textFieldName: text,
        linksFieldName: links, // ✅ ADD: Store links (null or List<String>)
      });
      final fetchedNote = await document.get();
      return CloudNote(
        documentId: fetchedNote.id,
        ownerUserId: ownerUserId,
        title: fetchedNote.data()![titleFieldName] ?? "",
        text: fetchedNote.data()![textFieldName] ?? "",
        links: fetchedNote.data()![linksFieldName] != null
            ? List<String>.from(fetchedNote.data()![linksFieldName] as List)
            : null, // ✅ ADD: Handle nullable links
      );
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  Stream<Iterable<CloudNote>> allNotes({
    required String ownerUserId,
  }) {
    final allNotes = notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) => event.docs.map((doc) => CloudNote.fromSnapshot(doc)));
    return allNotes;
  }

  // ✅ UPDATED: Add optional links parameter
  Future<void> updateNote({
    required String documentId,
    required String title,
    required String text,
    List<String>? links, // ✅ ADD: Optional links parameter
  }) async {
    try {
      await notes.doc(documentId).update({
        titleFieldName: title,
        textFieldName: text,
        linksFieldName: links, // ✅ ADD: Update links field
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  // ✅ ADD: Helper method to update only links
  Future<void> updateNoteLinks({
    required String documentId,
    required List<String>? links,
  }) async {
    try {
      await notes.doc(documentId).update({
        linksFieldName: links,
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  // ✅ ADD: Helper method to add single link using Firestore array operations
  Future<void> addLinkToNote({
    required String documentId,
    required String linkUrl,
  }) async {
    try {
      await notes.doc(documentId).update({
        linksFieldName: FieldValue.arrayUnion([linkUrl]),
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  // ✅ ADD: Helper method to remove single link using Firestore array operations
  Future<void> removeLinkFromNote({
    required String documentId,
    required String linkUrl,
  }) async {
    try {
      await notes.doc(documentId).update({
        linksFieldName: FieldValue.arrayRemove([linkUrl]),
      });
    } on FirebaseException catch (e) {
      if (e.plugin == "cloud_firestore") {
        throw CloudStorageException.fromCode(e.code);
      }
      rethrow;
    }
  }

  // ✅ ADD: Query notes containing specific links
  Stream<Iterable<CloudNote>> notesWithLink({
    required String ownerUserId,
    required String linkUrl,
  }) {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .where(linksFieldName, arrayContains: linkUrl)
        .snapshots()
        .map((event) => event.docs.map((doc) => CloudNote.fromSnapshot(doc)));
  }

  // ✅ ADD: Get notes that have any links
  Stream<Iterable<CloudNote>> notesWithAnyLinks({
    required String ownerUserId,
  }) {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .where(linksFieldName, isNotEqualTo: null)
        .snapshots()
        .map((event) => event.docs.map((doc) => CloudNote.fromSnapshot(doc)));
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
