import 'package:flutter/material.dart';

Future<void> showCustomDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = "OK",
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      );
    },
  );
}

Future<bool> showDeleteDialog({
  required BuildContext context,
}) async {
  const cancelButtonText = "Cancel";
  const deleteButtonText = "Delete";
  final title = "Delete";
  final message = "Are you sure you want to delete?";
  return await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(cancelButtonText),
          ),

          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: Text(deleteButtonText),
          ),
        ],
      );
    },
  );
}
