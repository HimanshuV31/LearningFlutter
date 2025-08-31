import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinity_notes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinity_notes/services/notes_actions/handle_long_press_note.dart';
import 'package:infinity_notes/constants/routes.dart';
import 'package:infinity_notes/enums/menu_actions.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
// import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
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

  // late final NotesService _notesService;
  late final FirebaseCloudStorage _notesService;

  String get userId => AuthService.firebase().currentUser!.id;

  Future<void> newNote() async {
    await Navigator.of(context).pushNamed(CreateUpdateNoteRoute);
  }

  // Future<void> openNote(DatabaseNote note) async {
  Future<void> openNote(CloudNote note) async {
    await Navigator.of(
      context,
    ).pushNamed(CreateUpdateNoteRoute, arguments: note);
  }

  late bool _showListView = false;

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    // _notesService.open();
    super.initState();
  }

  @override
  void dispose() {
    // _notesService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF3993ad);
    const foregroundColor = Colors.white;
    // final _userEmail = AuthService.firebase().currentUser?.email;
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      final shouldLogout = await showLogoutDialog(
                        context: context,
                      );
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
            child:
                // FutureBuilder<DatabaseUser>(
                //   future: _notesService.getOrCreateUser(email: userEmail),
                //   builder: (context, snapshot) {
                //     switch (snapshot.connectionState) {
                //       case ConnectionState.done:
                //         if (snapshot.hasError) {
                //           return Center(child: Text(snapshot.error.toString()));
                //         } else if (snapshot.hasData) {
                //           final user = snapshot.data!; // 👈 got DatabaseUser
                FutureBuilder<Stream<Iterable<CloudNote>>>(
                  future:
                      _notesService.allNotes(ownerUserId: userId)
                          as Future<Stream<Iterable<CloudNote>>>?,
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (futureSnapshot.hasError) {
                      return Center(
                        child: Text("Error: ${futureSnapshot.error}"),
                      );
                    }
                    if (!futureSnapshot.hasData) {
                      return const Center(child: Text("No notes found."));
                    }

                    // }
                    return StreamBuilder<Iterable<CloudNote>>(
                      // stream: _notesService.notesForUser(user.id),
                      stream: futureSnapshot.data,
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.active:
                            if (snapshot.hasData) {
                              final allNotes = snapshot
                                  .data; /* as List<DatabaseNote>;  //👈 your note model*/

                              // //Filter
                              // final realNotes = allNotes
                              //     .where(
                              //       (n) =>
                              //           n.text.trim().isNotEmpty ||
                              //           n.title.trim().isNotEmpty,
                              //     )
                              //     .toList();
                              // realNotes.sort((a, b) {
                              //   final dateA = DateTime.parse(a.updatedAt);
                              //   final dateB = DateTime.parse(b.updatedAt);
                              //   return dateB.compareTo(dateA);
                              // }); /*No need to filter the notes as they
                              //       are already filtered in the cloud storage*/
                              // if (realNotes.isEmpty) {
                              if (allNotes!.isEmpty) {
                                return const Center(
                                  child: Text("No notes yet. Create one!"),
                                );
                              }

                              if (_showListView) {
                                return NotesListView(
                                  // notes: realNotes,
                                  notes: allNotes,
                                  onTapNote: (note) => openNote(note),
                                  onLongPressNote: (note) => handleLongPressNote(
                                      context: context,
                                      note: note,
                                      notesService :_notesService,
                                    ),
                                  );
                              } else {
                                return NotesTileView(
                                  // notes: realNotes,
                                  notes: allNotes,
                                  onTapNote: (note) => openNote(note),
                                  onLongPressNote: (note) => handleLongPressNote(
                        context: context,
                        note: note,
                        notesService :_notesService,
                        ),
                                );
                              }
                            } else {
                              return const Center(
                                child: Text("No notes found."),
                              );
                            }
                          default:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                        }
                      },
                    );
                    // ),

                    //         } else {
                    //           return const Center(child: Text("Error loading user"));
                    //         }
                    //       default:
                    //         return const Center(child:CircularProgressIndicator());
                    //     }
                  },
                ) /*FutureBuilder*/,
          ),
        ),
      ],
    );
  }
}
