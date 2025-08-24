import 'package:flutter/material.dart';
import 'package:infinity_notes/ui/custom_app_bar.dart';


class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}




class _NewNoteViewState extends State<NewNoteView> {
  Color backgroundColor= Color(0xFF62B0D5);
  Color foregroundColor= Colors.white;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            title: "New Note",
          themeColor: backgroundColor,
          backgroundColor: Colors.black,
          foregroundColor: foregroundColor,
          actions: [

            //1 save button and a menu for other options like delete and all
          ],
        ), //CustomAppBar
        body: const Text("New Note View"),
    );

  }
}
