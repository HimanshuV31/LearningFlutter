import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
// import '../../services/crud/notes_service.dart';
import '../../utilities/generics/ui/custom_app_bar.dart';
import '../../utilities/generics/ui/dialogs.dart';
import '../../services/cloud/cloud_note.dart';
// import '../../services/cloud/cloud_storage_exceptions.dart';
import '../../services/cloud/firebase_cloud_storage.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  final Color backgroundColor = const Color(0xFF62B0D5);
  final Color foregroundColor = Colors.white;

  CloudNote? _note;
  // DatabaseNote? _note;

  // late final NotesService _notesService;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  String _initialTitle = "";
  String _initialText = "";

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // _notesService = NotesService();
    _notesService = FirebaseCloudStorage();
    _titleController = TextEditingController();
    _textController = TextEditingController();
    _setupListeners();
  }

  void _setupListeners() {
    _titleController.addListener(_onTitleChanged);
    _textController.addListener(_onTextChanged);
  }

  void _onTitleChanged() {
    setState(() {});
    _debouncedHandleChange();
  }

  void _onTextChanged() {
    setState(() {});
    _debouncedHandleChange();
  }

  void _debouncedHandleChange() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _handleChange();
    });
  }

  Future<void> _handleChange() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (_note != null && title == _initialTitle && text == _initialText) {
      // No changes, no action
      return;
    }

    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;

    if ((title.isNotEmpty || text.isNotEmpty) && _note == null) {
      await _createNote(userId, title, text);
      return;
    }

    if (_note != null) {
      if (title.isEmpty && text.isEmpty) {
        await _deleteNote();
        return;
      }
      await _updateNote(title, text);
    }
  }

  Future<void> _createNote(String userId, String title, String text) async {
    // final owner = await _notesService.getUser(email: email);
    // // Older create note logic:
    // final newNote = await _notesService.createNote(
    //   owner: owner,
    //   title: title,
    //   text: text,
    // );
    final newNote = await _notesService.createNewNote(
        ownerUserId: userId,
        title: title,
        text: text,
    );
    setState(() {
      _note = newNote;
      _initialTitle = title;
      _initialText = text;
    });
  }

  Future<void> _updateNote(String title, String text) async {
    // final updatedNote = await _notesService.updateNote(
    //   note: _note!,
    //   title: title,
    //   text: text,
    // );
    await _notesService.updateNote(
      documentId: _note!.documentId,
      title: title,
      text: text,
    );
    setState(() {
      _initialTitle = title;
      _initialText = text;
      // If updateNote returns updated note, assign here:
      // _note = updatedNote;
    });
  }

  Future<void> _deleteNote() async {
    // await _notesService.deleteNote(id: _note!.id);
    await _notesService.deleteNote(documentId: _note!.documentId);
    setState(() {
      _note = null;
      _initialTitle = "";
      _initialText = "";
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    // if (args != null && args is DatabaseNote) {
    if (args != null && args is CloudNote) {
      _note = args;
      _titleController.text = _note!.title;
      _textController.text = _note!.text;

      _initialTitle = _note!.title;
      _initialText = _note!.text;
    } else {
      _initialText = "";
      _initialTitle = "";
    }
  }

  @override
  void dispose() {
    debugPrint("Note Title Before Disposing: ${_titleController.text}");
    debugPrint("Note Text Before Disposing: ${_textController.text}");
    _titleController.dispose();
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
    debugPrint("Note Title After Disposing: ${_titleController.text}");
    debugPrint("Note Text After Disposing: ${_textController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _titleController.text.isEmpty
            ? "New Note"
            : _titleController.text,
        themeColor: backgroundColor,
        backgroundColor: Colors.black,
        foregroundColor: foregroundColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "delete" && _note != null) {
                final delete = await showDeleteDialog(context: context);
                if (delete) {
                  await _deleteNote();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "delete", child: Text("Delete Note")),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Title",
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _textController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              style: const TextStyle(fontSize: 15.0),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Text",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
