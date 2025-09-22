import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/search/bloc/search_event.dart';
import 'package:infinity_notes/services/search/bloc/search_state.dart';
import 'package:infinity_notes/services/search/search_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  Iterable<CloudNote> _allNotes = [];
  Timer? _debounceTimer;

  SearchBloc() : super(const SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SearchCleared>(_onSearchCleared);
    on<SearchInitiated>(_onSearchInitiated);
  }

  void _onSearchInitiated(
    SearchInitiated event,
    Emitter<SearchState> emit,
  ) {
    _allNotes = event.notes;
    emit (const SearchInitial());
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) {
    final query = event.query.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      try{
        final results = SearchService.filterNotes(_allNotes, query);
        if(results.isEmpty)
        {
        emit(SearchEmpty(query: query));}
        else{
          emit(SearchResults(results: results, query: query));
        }
      } catch (e){
        emit(SearchError("Error searching: ${e.toString()}"));
      }
    });
  }

  void _onSearchCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    _debounceTimer?.cancel();
    emit(const SearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
