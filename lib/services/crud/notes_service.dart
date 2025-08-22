import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'crud_exception.dart';

//Constants for Database
const dbName = "notes.db";
const noteTable = "note";
const userTable = "user";
const idColumn = "id";
const emailColumn = "email";
const userIdColumn = "user_id";
const titleColumn = "title";
const textColumn = "text";
const isSyncedWithCloudColumn = "is_synced_with_cloud";

//Database Queries
//User Table
const String createUserTable =
    '''
        CREATE TABLE IF NOT EXISTS $userTable (
          $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
          $emailColumn TEXT UNIQUE NOT NULL
        )''';
//Note Table
const String createNoteTable =
    '''
      CREATE TABLE IF NOT EXISTS $noteTable (
        $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
        $userIdColumn INTEGER NOT NULL,
        $titleColumn TEXT NOT NULL,
        $textColumn TEXT NOT NULL,
        $isSyncedWithCloudColumn INTEGER NOT NULL DEFAULT 0,
        )''';

/*Database Structure*/
class NotesService {
NotesService._sharedInstance();
static final NotesService _shared = NotesService._sharedInstance();
factory NotesService() => _shared;


  Database? _db;

  List<DatabaseNote> _notes = [];

  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  } //Future<void> _cacheNotes()

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String title,
    required String text,
  }) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id); //check if note exists
    final updatesCount = await db.update(noteTable, {
      titleColumn: title,
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });
    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  } //Future<DatabaseNote> updateNote()

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);
    final result = notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
    return result;
  } //Future<Iterable<DatabaseNote>> getAllNotes()

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNoteException();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  } //Future<DatabaseNote> getNote()

  Future<int> deleteAllNotes() async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(noteTable);

    _notes = []; //empties the notes list
    _notesStreamController.add(_notes); //adds an empty list to the stream
    return deletedCount;
  } //Future<int> deleteAllNotes()

  Future<DatabaseNote> createNote({
    required DatabaseUser owner,
    required String title,
    required String text,
  }) async
  {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUserException();
    }
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      titleColumn: title,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });
    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      title: title,
      text: text,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  } //Future<DatabaseNote> createNote()

  Future<void> deleteNote({required int id}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  } //Future<void> deleteNote()

  //User Functions
  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUserException {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e){rethrow;}
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUserException();
    } else {
      return DatabaseUser.fromMap(results.first);
    }
  } //Future<DatabaseUser> getUser()

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }
    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });
    return DatabaseUser(id: userId, email: email);
  } //Future<DatabaseUser> createUser()

  Future<void> deleteUser({required String email}) async {
    await _ensureDBIsOpen();
    await _ensureDBIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  } //Future<void> deleteUser()

  // Database Functions
  Future<void> _ensureDBIsOpen() async{
    try{
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
    }
  } //Future<void> _ensureDBIsOpen()

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpenException();
    } else {
      return db;
    }
  } // Database _getDatabaseOrThrow()

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  } // Future<void> close()

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      //Creating the User Table
      await db.execute(createUserTable);
      //Creating the Note Table
      await db.execute(createNoteTable);

      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  } // Future<void> open()
} // class NotesService. Should be the end of the block every time.

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromMap(Map<String, Object?> map)
    : id = map[idColumn] as int,
      email = map[emailColumn] as String;

  @override
  String toString() => "User(id: $id, email: $email)";

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
} //class DatabaseUser

class DatabaseNote {
  final int id;
  final int userId;
  final String title;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
    : id = map[idColumn] as int,
      userId = map[userIdColumn] as int,
      title = map[titleColumn] as String,
      text = map[textColumn] as String,
      isSyncedWithCloud = (map[isSyncedWithCloudColumn] as int) == 1
          ? true
          : false;

  @override
  String toString() {
    return "Note("
        "id: $id, "
        "userId: $userId, "
        "title: $title, "
        "text: $text, "
        "isSyncedWithCloud: $isSyncedWithCloud,)";
  }

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
} //class DatabaseNote
