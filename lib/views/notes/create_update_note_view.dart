import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';
import 'package:infinity_notes/services/cloud/firebase_cloud_storage.dart';
import 'package:infinity_notes/services/notes_actions/delete_note.dart';
import 'package:infinity_notes/services/notes_actions/share_note.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  final Color backgroundColor = const Color(0xFF62B0D5);
  final Color foregroundColor = Colors.white;
  CloudNote? _note;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  String _initialTitle = "";
  String _initialText = "";
  Timer? _debounce;

  // ✅ NEW: Link detection
  List<DetectedLink> _detectedLinks = [];

  @override
  void initState() {
    super.initState();
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
    _detectLinks(); // ✅ NEW: Detect links on text change
    _debouncedHandleChange();
  }

  // ✅ NEW: Link detection logic
  void _detectLinks() {
    final text = _textController.text;
    final linkRegex = RegExp(
      r'(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}[^\s]*)',
      caseSensitive: false,
    );

    final foundLinks = <DetectedLink>[];
    for (final match in linkRegex.allMatches(text)) {
      final linkText = match.group(0)!;
      final processedUrl = linkText.startsWith('http') ? linkText : 'https://$linkText';

      foundLinks.add(DetectedLink(
        url: processedUrl,
        displayText: linkText,
        siteName: _extractSiteName(linkText),
      ));
    }

    setState(() {
      _detectedLinks = foundLinks;
    });

    debugPrint("🔗 Detected ${_detectedLinks.length} links");
  }

  String _extractSiteName(String url) {
    try {
      String cleanUrl = url;
      if (cleanUrl.startsWith('www.')) {
        cleanUrl = cleanUrl.substring(4);
      }
      if (cleanUrl.startsWith('http://')) {
        cleanUrl = cleanUrl.substring(7);
      }
      if (cleanUrl.startsWith('https://')) {
        cleanUrl = cleanUrl.substring(8);
      }

      final firstSlash = cleanUrl.indexOf('/');
      if (firstSlash != -1) {
        cleanUrl = cleanUrl.substring(0, firstSlash);
      }

      final parts = cleanUrl.split('.');
      if (parts.length >= 2) {
        return parts[0].toUpperCase();
      }

      return cleanUrl.toUpperCase();
    } catch (e) {
      return 'WEBSITE';
    }
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
      return;
    }

    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;

    if ((title.isNotEmpty || text.isNotEmpty) && _note == null) {
      await _createNote(userId, title, text);
      return;
    }
    if (_note != null && title.isEmpty && text.isEmpty) {
      await deleteNote(
        context: context,
        note: _note!,
        notesService: _notesService,
      );
      return;
    }
    await _updateNote(title, text);
  }

  Future<void> _createNote(String userId, String title, String text) async {
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
    await _notesService.updateNote(
      documentId: _note!.documentId,
      title: title,
      text: text,
    );
    setState(() {
      _initialTitle = title;
      _initialText = text;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is CloudNote) {
      _note = args;
      _titleController.text = _note!.title;
      _textController.text = _note!.text;
      _initialTitle = _note!.title;
      _initialText = _note!.text;
      _detectLinks(); // ✅ Detect links on load
    } else {
      _initialText = "";
      _initialTitle = "";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ✅ NEW: Launch URL
  void _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri);
      debugPrint("🔗 Launched: $uri");
    } catch (e) {
      debugPrint("🔗 Failed to launch: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _titleController.text.isEmpty ? "New Note" : _titleController.text,
        themeColor: backgroundColor,
        backgroundColor: Colors.black,
        foregroundColor: foregroundColor,
        actions: [
          IconButton(
            onPressed: () async {
              if (_note == null ||
                  _titleController.text.isEmpty ||
                  _textController.text.isEmpty) {
                await showCannotShareEmptyNoteDialog(context);
              } else {
                shareNote(context: context, note: _note!);
              }
            },
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "delete" && _note != null) {
                final confirm = await showDeleteDialog(context: context);
                if (confirm) {
                  await _notesService.deleteNote(documentId: _note!.documentId);
                  showCustomToast(context, "Note Deleted Successfully");
                }
                if (!mounted) return;
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "delete", child: Text("Delete Note")),
            ],
          ),
        ],
      ),

      // ✅ NEW: Clean 3-section layout
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1️⃣ Title Field
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Title",
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // 2️⃣ Text Field
            Expanded(
              flex: 3,
              child: TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 18.0),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  hintText: "Write your note here... Links will appear below!",
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3️⃣ Detected Links Section
            if (_detectedLinks.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.link, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "Detected Links (${_detectedLinks.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Links ListView
            Expanded(
              flex: 2,
              child: _detectedLinks.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "No links detected",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  itemCount: _detectedLinks.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final link = _detectedLinks[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Icon(
                          Icons.language,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        link.siteName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        link.displayText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.open_in_new,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                      onTap: () => _launchURL(link.url),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ NEW: DetectedLink model
class DetectedLink {
  final String url;
  final String displayText;
  final String siteName;

  DetectedLink({
    required this.url,
    required this.displayText,
    required this.siteName,
  });
}
