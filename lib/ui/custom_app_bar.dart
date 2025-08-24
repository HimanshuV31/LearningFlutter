import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? themeColor;
  const CustomAppBar({super.key, required this.title,this.themeColor, required this.foregroundColor, required this.backgroundColor, this.actions,});

  @override
  Widget build(BuildContext context) {
    final double fontSize = 23;
    final double strokeWidth = 2;
    return AppBar(
      title: Stack(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..color = backgroundColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
          ),
        ],
      ),
      backgroundColor: themeColor ?? backgroundColor ,
      foregroundColor: foregroundColor,
      elevation: 0,
      actions: actions,
      flexibleSpace: themeColor != null
          ?null
          : LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDesktop
                      ? "assets/images/Web_AppBar_Background.png"
                      : "assets/images/Phone_AppBar_Background.png",
                ),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

