import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Import foundation.dart
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkifyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? linkColor;

  const LinkifyText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.linkColor,
      });

  @override
  Widget build(BuildContext context) {
    return Linkify(
      onOpen: (link) => _launchURL(link.url),
      text: text,
      style: style,
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      linkStyle: TextStyle(
        color: linkColor ?? Colors.lightBlueAccent,
        decoration: TextDecoration.underline,
        decorationColor: linkColor ?? Colors.lightBlueAccent,
        fontWeight: FontWeight.w500,
      ),
      options: const LinkifyOptions(
        humanize: false,
        removeWww: false,
        looseUrl: true,
        defaultToHttps: true,
      ),
    );
  }

}
Future<void> _launchURL(String url) async {
  try {
    String processedUrl = url.trim();

    // Simple protocol addition
    if (!processedUrl.startsWith('http://') && !processedUrl.startsWith('https://')) {
      processedUrl = 'https://$processedUrl';
    }

    final uri = Uri.parse(processedUrl);
    debugPrint("🔗 Attempting to launch: $uri");

    // Simple launch - let the system handle the rest
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (launched) {
      debugPrint("🔗 ✅ URL launched successfully");
    } else {
      debugPrint("🔗 ❌ Failed to launch URL");
    }
  } catch (e) {
    debugPrint("🔗 ❌ Error launching URL: $e");
  }
}


void _showLaunchError(String message) {
    showCustomToast(context as BuildContext, message);
    debugPrint("🔗 Error: $message");
  }


