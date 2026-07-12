import 'package:flutter/material.dart';

/// Non-web fallback. This app deploys to web, so this only exists to keep
/// `flutter analyze`/tests compiling on the Dart VM.
Widget htmlIframe({String? srcdoc, String? src, required double height}) {
  return SizedBox(
    height: height,
    child: const Center(child: Text('HTML embed is only available on web.')),
  );
}
