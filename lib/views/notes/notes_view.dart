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
import 'package:infinity_notes/utilities/generics/ui/ui_constants.dart';
import 'package:infinity_notes/views/notes/notes_list_view.dart';
import 'package:infinity_notes/views/notes/notes_tile_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView>{
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
  void _toggleView() {
    setState(() {
      _showListView = !_showListView;
    });
  }

  @override
  void dispose() {
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
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (hasNotes && _searchBloc.state is SearchInitial) {
                            _searchBloc.add(SearchInitiated(allNotes));
                            debugPrint("🔍 Post-frame: Initialized SearchBloc with ${allNotes.length} notes");
                          }
                        });
                        return CustomScrollView(
                          slivers: [
                            // AppBar
                            CustomSliverAppBar(
                              title: "Infinity Notes",
                              userEmail: userEmail,
                              hasNotes: hasNotes,
                              autoShowSearch: hasNotes,
                              // menuItems: _buildMenuItems(),
                              backgroundColor: Colors.black,
                              foregroundColor: foregroundColor,
                              onToggleView: _toggleView,
                              isListView: _showListView,
                              onLogout:() =>_handleMenuAction(MenuAction.logout),
                              onSearchChanged: (query) =>
                                  _searchBloc.add(SearchQueryChanged(query)),
                            ), // CustomSliverAppBar

                            //Not~s with Search Implementation
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
              floatingActionButton: Container(
                margin: EdgeInsets.only(bottom: 36,right: 10), // ✅ Add margin from bottom
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: UIConstants.strongShadow,
                ),
                child: FloatingActionButton(
                  onPressed: newNote,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: themeColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                      Icons.add,
                      color: themeColor,
                      size: 28,
                      shadows: UIConstants.iconShadow,
                  ),
                ),
              ),
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
      case MenuAction.profile:
        // TODO: Handle this case.
        throw UnimplementedError();
      case MenuAction.settings:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
  //
  // List<PopupMenuEntry> _buildMenuItems() {
  //   return [
  //     PopupMenuItem<MenuAction>(
  //       value: MenuAction.logout,
  //       onTap: () => _handleMenuAction(MenuAction.logout),
  //       child: Row(
  //         children: [
  //           Icon(Icons.logout, size: 20, color: Colors.white70),
  //           SizedBox(width: 8),
  //           Text("Logout", style: TextStyle(color: Colors.white)),
  //         ],
  //       ),
  //     ),
  //   ];
  // }

  Widget _buildNotesContent(
      Iterable<CloudNote> allNotes,
      SearchState searchState,
      ) {
    debugPrint("🔍 _buildNotesContent: searchState = $searchState");

    Iterable<CloudNote> notesToShow;

    switch (searchState.runtimeType) {
      case SearchResults:
        final state = searchState as SearchResults;
        notesToShow = state.results;
        debugPrint("🔍 Showing ${notesToShow.length} search results for '${state.query}'");
        break;

      case SearchEmpty:
        final state = searchState as SearchEmpty;
        debugPrint("🔍 No results found for '${state.query}'");
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  "No results found for: ${state.query}",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        );

      case SearchInitial:
        final state = searchState as SearchInitial;
        notesToShow = state.notes.isNotEmpty ? state.notes : allNotes;
        debugPrint("🔍 Showing all ${notesToShow.length} notes (initial state)");
        break;

      default:
        notesToShow = allNotes;
        debugPrint("🔍 Showing all ${notesToShow.length} notes (default)");
        break;
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

    // ✅ FIXED: Use AnimatedSwitcher instead of AnimatedBuilder in Sliver
    return SliverToBoxAdapter(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: _showListView
            ? NotesListView(
          key: const ValueKey('listView'), // ✅ Key for AnimatedSwitcher
          notes: notesToShow,
          onTapNote: (note) => openNote(note),
          onLongPressNote: (note) => handleLongPressNote(
            context: context,
            note: note,
            notesService: _notesService,
          ),
        )
            : NotesTileView(
          key: const ValueKey('tileView'), // ✅ Key for AnimatedSwitcher
          notes: notesToShow,
          onTapNote: (note) => openNote(note),
          onLongPressNote: (note) => handleLongPressNote(
            context: context,
            note: note,
            notesService: _notesService,
          ),
        ),
      ),
    );
  }


}
