

import 'package:infinity_notes/services/cloud/cloud_note.dart';

abstract class SearchEvent {
  const SearchEvent();
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

class SearchInitiated extends SearchEvent {
  final Iterable<CloudNote> notes;
  const SearchInitiated(this.notes);
}