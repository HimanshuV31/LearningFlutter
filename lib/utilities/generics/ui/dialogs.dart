import 'package:flutter/material.dart';


typedef DialogOptionBuilder<T> = Map<String, DialogOption<T>> Function();

class DialogOption<T> {
  final T? value;
  final ButtonStyle? style;
  final Color? textColor;
  final VoidCallback? onPressed;

  DialogOption({this.value, this.style, this.textColor, this.onPressed});
}

// (PRIVATE) Generic Dialog
Future<T?> _showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required DialogOptionBuilder<T> optionBuilder,
  bool? barrierDismissible,
})
{
  final options = optionBuilder();
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible ?? true,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: options.entries.map((entry) {
          final optionTitle = entry.key;
          final optionDataMessage = entry.value;
          final optionTextColor = entry.value.textColor;
          return ElevatedButton(
            style: optionDataMessage.style
                ?? TextButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              if (optionDataMessage.onPressed != null) {
                Navigator.of(context).pop();
                optionDataMessage.onPressed!();
              } else {
                Navigator.of(context).pop(optionDataMessage.value);
              }
            },
            child: Text(
              optionTitle,
              style: TextStyle(
                color: optionTextColor ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ); //ElevatedButton
        }).toList(), //actions
      ); //return AlertDialog
    }, //builder
  ); //return showDialog
}

//Delete Dialog
Future<bool> showDeleteDialog({required BuildContext context}) {
  return _showGenericDialog<bool>(
    context: context,
    title: 'Delete',
    content: 'Are you sure you want to delete this item?',
    optionBuilder: () =>
    {
      'Cancel': DialogOption<bool>(
        value: false,
        style: TextButton.styleFrom(
          backgroundColor: Colors.red,
        ),
      ),
      'Delete': DialogOption<bool>(
        value: true,
        style: TextButton.styleFrom(
          backgroundColor: Colors.black,
        ),
        textColor: Colors.red,
      ),
    },
  ).then((value) => value ?? false);
}

//Warning Dialog
Future<void> showWarningDialog({
  required BuildContext context,
  required String title,
  required String message,})
{
  return _showGenericDialog<void>(
      context: context,
      title: title,
      content: message,
      barrierDismissible: false,
      optionBuilder: () =>
      {
        "OK": DialogOption<void>(value: null),
      }
  );
}

//Logout Dialog
Future<bool> showLogoutDialog({required BuildContext context}) {
  return _showGenericDialog<bool>(
    context: context,
    title: "Logout",
    content: "Are you sure you want to logout?",
    optionBuilder: () =>
    {
      "Cancel": DialogOption<bool>(
        value: false,
        style: TextButton.styleFrom(backgroundColor: Colors.red),
      ),
      "Logout": DialogOption<bool>(
        value: true,
        style: TextButton.styleFrom(backgroundColor: Colors.black),
        textColor: Colors.red,
      ),
    },
  ).then((value) => value ?? false);
}

//Can't share empty Notes
Future<void> showCannotShareEmptyNoteDialog(BuildContext context) {
  return _showGenericDialog<void>(
      context: context,
      title: "Can't Share Empty Notes",
      content: 'Error while sharing an empty note. Please select a non-empty note to share.',
      optionBuilder: () =>
      {
        "OK": DialogOption<void>(value: null),
      }
  );
}

//Custom Routing Dialog
Future<void> showCustomRoutingDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String routeButtonText,
  required String routeToPush,
  String? cancelButtonText,
  ButtonStyle? cancelButtonStyle,
  ButtonStyle? routeButtonStyle,
  bool? barrierDismissible,
})
{
  return _showGenericDialog<void>(
    context: context,
    title: title,
    content: content,
    barrierDismissible: barrierDismissible ?? true,
    optionBuilder: () => {
      if (cancelButtonText != null)
        cancelButtonText: DialogOption<void>(
          value: null,
          style: cancelButtonStyle ?? TextButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(),
        ),
      routeButtonText: DialogOption<void>(
        value: null,
        style: routeButtonStyle ?? TextButton.styleFrom(backgroundColor: Colors.black),
        onPressed: () => Navigator.pushNamed(context, routeToPush),
      ),
    },
  );
}

//Loading Dialog
typedef CloseDialog = void Function();
CloseDialog showLoadingDialog({
  required BuildContext context,
  required String text,
}) {
    final dialog= AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          Text(text),
        ],
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => dialog,
    );
    return () => Navigator.of(context).pop();
}