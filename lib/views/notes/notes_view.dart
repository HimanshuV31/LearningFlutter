import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'
    show ReadContext, BlocListener, BlocProvider, BlocBuilder;
import 'package:infinity_notes/constants/routes.dart';
import 'package:infinity_notes/enums/menu_actions.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
// import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinity_notes/services/notes_actions/handle_long_press_note.dart';
import 'package:infinity_notes/services/search/bloc/search_bloc.dart';
import 'package:infinity_notes/services/search/bloc/search_event.dart';
import 'package:infinity_notes/services/search/bloc/search_state.dart';
import 'package:infinity_notes/utilities/generics/ui/background_image.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_sliver_app_bar.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';
import 'package:infinity_notes/views/notes/notes_list_view.dart';
import 'package:infinity_notes/views/notes/notes_tile_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  String get userEmail => AuthService.firebase().currentUser!.email;
  late final FirebaseCloudStorage _notesService;
  String get userId => AuthService.firebase().currentUser!.id;
  CloseDialog? _closeDialogHandle;
  late bool _showListView = false;
  late SearchBloc _searchBloc;
  final themeColor = Color(0xFF3993ad);
  final foregroundColor = Colors.white;

  Future<void> newNote() async {
    await Navigator.of(context).pushNamed(CreateUpdateNoteRoute);
  }

  Future<void> openNote(CloudNote note) async {
    await Navigator.of(
      context,
    ).pushNamed(CreateUpdateNoteRoute, arguments: note);
  }

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    _searchBloc = SearchBloc();
    super.initState();
  }

  @override
  void dispose() {
    // _notesService.close();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthStateLoggedOut && state.exception != null) {
            final closeDialog = _closeDialogHandle;
            if (!state.isLoading && closeDialog != null) {
              closeDialog();
              _closeDialogHandle = null;
            } else if (state.isLoading && closeDialog == null) {
              _closeDialogHandle = showLoadingDialog(
                context: context,
                text: "Loading... .. .",
              );
            }

            // Display error dialogs for login failure
            final e = state.exception;
            if (e is AuthException) {
              showWarningDialog(
                context: context,
                title: e.title,
                message: e.message,
              );
            }
          }
        },
        child: Stack(
          children: [
            const BackgroundImage(),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child:
                    StreamBuilder<Iterable<CloudNote>>(
                      stream: _notesService.allNotes(ownerUserId: userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        }
                        final allNotes = snapshot.data ?? <CloudNote>[];
                        final hasNotes = allNotes.isNotEmpty;

                        return CustomScrollView(
                          slivers: [
                            // AppBar
                            CustomSliverAppBar(
                              title: "Infinity Notes",
                              userEmail: userEmail,
                              hasNotes: hasNotes,
                              menuItems: _buildMenuItems(),
                              backgroundColor: Colors.black,
                              foregroundColor: foregroundColor,
                              isListView: _showListView,
                              onToggleView: () => setState(
                                () => _showListView = !_showListView,
                              ),
                              onSearchChanged: (query) =>
                                  _searchBloc.add(SearchQueryChanged(query)),
                            ), // CustomSliverAppBar

                            //Notes with Search Implementation
                            BlocBuilder<SearchBloc, SearchState>(
                              builder: (context, searchState) {
                                return _buildNotesContent(
                                  allNotes,
                                  searchState,
                                );
                              },
                            ), //BlocBuilder for Notes and Search
                          ], // slivers
                        ); //return statement (CustomScrollView)
                      }, //builder
                    ), //streamBuilder
              ), //body:safeArea
              floatingActionButton: _buildCustomFAB(),
            ), //scaffold
          ], //children
        ), //child:stack
      ),
    );
  }

  void _handleMenuAction(MenuAction action) async {
    switch (action) {
      case MenuAction.logout:
        final shouldLogout = await showLogoutDialog(context: context);
        if (!mounted) return;
        if (!shouldLogout) return;
        context.read<AuthBloc>().add(const AuthEventLogOut());
        if (!mounted) return;
        showCustomToast(context, "Logout Successful");
        break;
    }
  }

  List<PopupMenuEntry> _buildMenuItems() {
    return [
      PopupMenuItem<MenuAction>(
        value: MenuAction.logout,
        onTap: () => _handleMenuAction(MenuAction.logout),
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: Colors.white70),
            SizedBox(width: 8),
            Text("Logout", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ];
  }

  Widget _buildNotesContent(
    Iterable<CloudNote> allNotes,
    SearchState searchState,
  ) {
    Iterable<CloudNote> notesToShow = allNotes;

    // Apply Search Filter
    if (searchState is SearchResults) {
      notesToShow = searchState.results;
    } else if (searchState is SearchEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                "No results found for: ${searchState.query}",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    if (notesToShow.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_add, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                "No notes found. Create one!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    //Return appropriate sliver
    if (_showListView) {
      return SliverToBoxAdapter(
        child: NotesListView(
            notes: notesToShow,
            onTapNote: (note) => openNote(note),
            onLongPressNote:(note) => handleLongPressNote(
              context: context,
              note: note,
              notesService: _notesService,
            ),
        ),
      );
    } else {
      return SliverToBoxAdapter(
        child: NotesTileView(
            notes: notesToShow,
            onTapNote: (note) => openNote(note),
            onLongPressNote: (note) => handleLongPressNote(
              context: context,
              note: note,
              notesService: _notesService,
            ),
        ),
      );
    }
  }

  Widget _buildCustomFAB() {
    return FloatingActionButton(
      onPressed: newNote,
      backgroundColor: themeColor,
      foregroundColor: Colors.black,
      child: Icon(Icons.add, color: Colors.white),
    );
  }
}
