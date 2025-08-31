import 'package:flutter/material.dart';


typedef DialogOptionBuilder<T> = Map<String, DialogOption<T>> Function();

class DialogOption<T> {
  final T? value;
  final ButtonStyle? style;
  final Color? textColor;
  DialogOption({this.value, this.style,this.textColor});
}

// (PRIVATE) Generic Dialog
Future<T?> _showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required DialogOptionBuilder<T> optionBuilder,
})
{
  final options = optionBuilder();
  return showDialog<T>(
    context: context,
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
            onPressed:(){
                Navigator.of(context).pop(optionDataMessage.value);
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
    optionBuilder: () => {
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
      optionBuilder: ()=> {
        "OK": DialogOption<void>(value: null),
      }
  );
}

//Logout Dialog
Future<bool> showLogoutDialog ({required BuildContext context}){
  return _showGenericDialog<bool>(
    context: context,
    title: "Logout",
    content: "Are you sure you want to logout?",
    optionBuilder:()=>{
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
Future<void> showCannotShareEmptyNoteDialog(BuildContext context){
  return _showGenericDialog<void>(
      context: context,
      title: "Can't Share Empty Notes",
      content: 'Error while sharing an empty note. Please select a non-empty note to share.',
      optionBuilder: ()=> {
        "OK": DialogOption<void>(value: null),
      }
  );
}
