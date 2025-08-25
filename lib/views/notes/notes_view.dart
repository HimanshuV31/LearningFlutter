import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:infinity_notes/enums/menu_actions.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/crud/notes_service.dart';
import 'package:infinity_notes/ui/custom_app_bar.dart';
import 'package:infinity_notes/ui/custom_toast.dart';
import 'package:infinity_notes/ui/dialogs.dart';

import '../../constants/routes.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  String get userEmail => AuthService.firebase().currentUser!.email!;
  late final NotesService _notesService;

  @override
  void initState() {
    _notesService = NotesService();
    _notesService.open();
    super.initState();
  }

  int _getCrossAxisCount() {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 4;
    }
    return 2; // Mobile platforms
  }

  @override
  void dispose() {
    _notesService.close();
    super.dispose();
  }

  Future<void> newNote() async {
    await Navigator.of(context).pushNamed(newNoteRoute);
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
                  final shouldLogout = await showLogoutDialog(context);
                  if (!mounted) return;
                  if (!shouldLogout) return;
                  if (shouldLogout) {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    if (mounted) {
                      showCustomToast(context, "Logout Successful");
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(loginRoute, (_) => false);
                    }
                  }
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
                          return MasonryGridView.count(
                            crossAxisCount: _getCrossAxisCount(),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            itemCount: realNotes.length,
                            padding: const EdgeInsets.all(10),
                            // shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final note = realNotes[index];
                              return _NoteTile(
                                note: note,
                                onTap: () async {
                                  await Navigator.of(
                                    context,
                                  ).pushNamed(newNoteRoute, arguments: note);
                                },
                                onLongPress: () async {
                                  final shouldDelete = await showDeleteDialog(
                                    context: context,
                                  );
                                  if (shouldDelete) {
                                    await _notesService.deleteNote(id: note.id);
                                    if (!mounted) return;
                                    showCustomToast(context, "Note Deleted");
                                  }
                                },
                              );
                            },
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

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, this.onTap, this.onLongPress});

  final DatabaseNote note;
  static const maxTextLines = 10;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF3993ad);
    const foregroundColor = Colors.transparent;
    final hasText = note.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: foregroundColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: backgroundColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              note.title.isEmpty ? "Untitled" : note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (hasText) ...[
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  note.text,
                  maxLines: maxTextLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to Logout?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Logout"),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
} // Future<bool> showLogoutDialog()
