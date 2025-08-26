import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinity_notes/enums/menu_actions.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/crud/notes_service.dart';
import 'package:infinity_notes/ui/custom_app_bar.dart';
import 'package:infinity_notes/ui/custom_toast.dart';
import 'package:infinity_notes/ui/dialogs.dart';
import 'package:infinity_notes/views/notes/notes_tile_view.dart';

import '../../constants/routes.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  String get userEmail => AuthService.firebase().currentUser!.email!;
  late final NotesService _notesService;

  Future<void> newNote() async {
    await Navigator.of(context).pushNamed(newNoteRoute);
  }

  Future<void> openNote(DatabaseNote note) async {
    await Navigator.of(context).pushNamed(newNoteRoute, arguments: note);
  }

  Future<void> deleteNote(DatabaseNote note) async {
    final shouldDelete = await showDeleteDialog(context: context);
    if (shouldDelete) {
      await _notesService.deleteNote(id: note.id);
      if (!mounted) return;
      showCustomToast(context, "Note Deleted");
    }
  }

  @override
  void initState() {
    _notesService = NotesService();
    _notesService.open();
    super.initState();
  }

  @override
  void dispose() {
    _notesService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF3993ad);
    const foregroundColor = Colors.white;
    final _userEmail = AuthService.firebase().currentUser?.email;
    return Scaffold(
      appBar: CustomAppBar(
        title: "Infinity Notes | Notes",
        backgroundColor: Colors.black,
        foregroundColor: foregroundColor,
        actions: [
          Tooltip(
            message: "New Note",
            child: IconButton(onPressed: newNote, icon: Icon(Icons.add)),
          ),

          PopupMenuButton<MenuAction>(
            icon: const Icon(Icons.menu_rounded),
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context: context);
                  if (!mounted) return;
                  if (!shouldLogout) return;
                  await AuthService.firebase().signOut();
                  if (!mounted) return;
                  showCustomToast(context, "Logout Successful");
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(loginRoute, (_) => false);
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text("Logout"),
                ),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder<DatabaseUser>(
        future: _notesService.getOrCreateUser(email: userEmail),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              } else if (snapshot.hasData) {
                final user = snapshot.data!; // 👈 got DatabaseUser

                return StreamBuilder(
                  stream: _notesService.notesForUser(user.id),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                      case ConnectionState.active:
                        if (snapshot.hasData) {
                          final allNotes =
                              snapshot.data
                                  as List<DatabaseNote>; // 👈 your note model
                          //Filter
                          final realNotes = allNotes
                              .where(
                                (n) =>
                                    n.text.trim().isNotEmpty ||
                                    n.title.trim().isNotEmpty,
                              )
                              .toList();
                          realNotes.sort((a, b) {
                            final dateA = DateTime.parse(a.updatedAt);
                            final dateB = DateTime.parse(b.updatedAt);
                            return dateB.compareTo(dateA);
                          });
                          if (realNotes.isEmpty) {
                            return const Center(
                              child: Text("No notes yet. Create one!"),
                            );
                          }

                          //Notes in Display
                          //Options can be provided of List and Tile views based using
                          //the commented code below. The args is for demo.
                          /*
                            SwitchListTile(
                                value: year2023,
                                title: year2023
                                  ? /* ListView */
                                  : /* TileView */,
                                onChanged: (bool value) {
                                  setState(() {
                                    year2023 = !year2023;
                                  });
                                },
                             ),
                          */
                          return NotesTileView(
                            notes: realNotes,
                            onTapNote: (DatabaseNote note) => openNote(note),
                            onLongPressNote: (DatabaseNote note) =>
                                deleteNote(note),
                            /* onDeleteNote: (DatabaseNote note) {  },*/
                          );
                        } else {
                          return const Center(child: Text("No notes found."));
                        }
                      default:
                        return const Center(child: CircularProgressIndicator());
                    }
                  },
                );
              } else {
                return const Center(child: Text("Error loading user"));
              }
            default:
              return const CircularProgressIndicator();
          }
        },
      ) /*FutureBuilder*/,
    );
  }
}
