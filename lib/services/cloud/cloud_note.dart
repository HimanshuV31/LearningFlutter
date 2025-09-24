import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infinity_notes/services/cloud/cloud_storage_constants.dart';

class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String title;
  final String text;
  final List<String>? links; // ✅ ADD: Nullable links field

  const CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.title,
    required this.text,
    this.links, // ✅ ADD: Optional links parameter
  });

  CloudNote.fromSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
      ) : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName] as String,
        title = snapshot.data()[titleFieldName] as String,
        text = snapshot.data()[textFieldName] as String,
        links = snapshot.data()[linksFieldName] != null
            ? List<String>.from(snapshot.data()[linksFieldName] as List)
            : null; // ✅ ADD: Handle nullable links from Firestore

  // ✅ ADD: Helper methods for links
  bool get hasLinks => links != null && links!.isNotEmpty;
  int get linkCount => links?.length ?? 0;
  List<String> get safeLinks => links ?? [];
}
