import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

int _counter = 0;

/// Renders raw HTML in a sandboxed iframe as a Flutter platform view.
Widget htmlIframe({String? srcdoc, String? src, required double height}) {
  final viewType = 'viz-html-${_counter++}';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final iframe = web.HTMLIFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('sandbox', 'allow-scripts allow-same-origin');
    if (srcdoc != null) {
      iframe.setAttribute('srcdoc', srcdoc);
    } else if (src != null) {
      iframe.setAttribute('src', src);
    }
    return iframe;
  });

  return SizedBox(
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
