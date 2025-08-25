import 'dart:async';
import 'package:flutter/material.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/crud/notes_service.dart';
import 'package:infinity_notes/ui/custom_app_bar.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  Color backgroundColor = const Color(0xFF62B0D5);
  Color foregroundColor = Colors.white;

  DatabaseNote? _note;

  late final NotesService _notesService;
  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  Timer? _debounce;


  @override
  void initState() {
    super.initState();
    _notesService = NotesService();
    _titleController = TextEditingController();
    _textController = TextEditingController();
    _setupListeners();
  }

  // ✅ Listeners to update DB in realtime
  void _setupListeners() {
    _titleController.addListener(_onTitleChanged);
    _textController.addListener(_onTextChanged);
  }
  void _onTitleChanged(){
    setState(() {});
    _handleChange();
  }
  void _onTextChanged(){
    setState(() {});
    _handleChange();
  }
  Future<void> _handleChange() async {
    if(_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final currentUser = AuthService.firebase().currentUser!;
      final email = currentUser.email!;
      final owner = await _notesService.getUser(email: email);
      final title = _titleController.text.trim();
      final text = _textController.text.trim();
      // Create note once, after user enters any non empty text
      if ((title.isNotEmpty || text.isNotEmpty)
          && _note == null) {
        final newNote = await _notesService.createNote(
          owner: owner,
          title: title,
          text: text,
        );
        setState(() {
          _note = newNote;
        });
        return;
      }
      if (_note != null) {
      if(title.isEmpty && text.isEmpty) {
        await _notesService.deleteNote(id: _note!.id);
        setState(() {
          _note = null;
        });
        return;
      }
        final updatedNote = await _notesService.updateNote(
          note: _note!,
          title: title,
          text: text,
        );
      setState(() => _note = updatedNote);
      }
    });
  } // Future<void> _handleChange()

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is DatabaseNote) {
      // ✅ Existing note case
      _note = args;
      _titleController.text = _note!.title;
      _textController.text = _note!.text;
    }
  }


  @override
  void dispose() {
    //Delete if note is empty
    // if((_titleController.text.isEmpty && _textController.text.isEmpty)
    //     && _note != null){
    //   _notesService.deleteNote(id: _note!.id);
    // }
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
        title:_titleController.text.isEmpty
            ? "New Note"
            : _titleController.text
        ,
        themeColor: backgroundColor,
        backgroundColor: Colors.black,
        foregroundColor: foregroundColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "delete" && _note != null) {
                _notesService.deleteNote(id: _note!.id);
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "delete",
                child: Text("Delete Note"),
              ),
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
                  const SizedBox(height: 22), // 👈 add some space
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
            )
    );
  }
}
