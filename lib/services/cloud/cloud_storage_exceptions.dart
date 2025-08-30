

class CloudStorageException implements Exception {
  const CloudStorageException();


}

class CouldNotCreateNoteException extends CloudStorageException {
  const CouldNotCreateNoteException();
}

class CouldNotGetAllNotesException extends CloudStorageException {
  const CouldNotGetAllNotesException();
}

class CouldNotDeleteNoteException extends CloudStorageException {
  const CouldNotDeleteNoteException();
}

class CouldNotUpdateNoteException extends CloudStorageException {
  const CouldNotUpdateNoteException();
}

class CouldNotReadNoteException extends CloudStorageException {
  const CouldNotReadNoteException();
}
