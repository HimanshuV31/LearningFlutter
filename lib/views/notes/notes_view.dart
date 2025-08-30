import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinity_notes/constants/routes.dart';
import 'package:infinity_notes/enums/menu_actions.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/crud/notes_service.dart';
import 'package:infinity_notes/utilities/generics/ui/background_image.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';
import 'package:infinity_notes/utilities/generics/ui/icon_toggle_switch.dart';
import 'package:infinity_notes/views/notes/notes_list_view.dart';
import 'package:infinity_notes/views/notes/notes_tile_view.dart';


class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  String get userEmail => AuthService.firebase().currentUser!.email;
  late final NotesService _notesService;

  Future<void> newNote() async {
    await Navigator.of(context).pushNamed(CreateUpdateNoteRoute);
  }

  Future<void> openNote(DatabaseNote note) async {
    await Navigator.of(context).pushNamed(CreateUpdateNoteRoute, arguments: note);
  }

  Future<void> deleteNote(DatabaseNote note) async {
    final shouldDelete = await showDeleteDialog(context: context);
    if (shouldDelete) {
      await _notesService.deleteNote(id: note.id);
      if (!mounted) return;
      showCustomToast(context, "Note Deleted");
    }
  }

  late bool _showListView = false;

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
    return Stack(
      children: [
        const BackgroundImage(),
      Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: "Infinity Notes | Notes",
        backgroundColor: Colors.black,
        foregroundColor: foregroundColor,
        themeColor: Colors.black26,
        actions: [
          Tooltip(
            message: "New Note",
            child: IconButton(onPressed: newNote, icon: Icon(Icons.add)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconToggleSwitch(
              value: _showListView,
              onChanged: (value) {
                setState(() {
                  _showListView = value;
                });
              },
              activeIcon: Icons.list_rounded,
              inactiveIcon: Icons.grid_view,
              activeColor: Colors.cyan,
              inactiveColor: Colors.blue,
              width: 70,
              height: 40,
              toggleSize: 33,
            ),


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
      body: SafeArea(
      child: FutureBuilder<DatabaseUser>(
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

                          if(_showListView){
                            return NotesListView(
                              notes: realNotes,
                              onTapNote: openNote,
                              onLongPressNote: deleteNote,
                            );
                          }else{
                            return NotesTileView(
                              notes: realNotes,
                              onTapNote: openNote,
                              onLongPressNote: deleteNote,
                            );
                          }
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
              return const Center(child:CircularProgressIndicator());
          }
        },
      ) /*FutureBuilder*/,
    ),
      ),
      ],
    );
  }
}
