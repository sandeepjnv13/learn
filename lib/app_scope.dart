import 'package:flutter/material.dart';

import 'services/content_service.dart';

/// App-wide singletons made available to the widget tree.
class AppScope extends InheritedWidget {
  final ContentService content;
  final ValueNotifier<ThemeMode> themeMode;

  const AppScope({
    super.key,
    required this.content,
    required this.themeMode,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      content != oldWidget.content || themeMode != oldWidget.themeMode;
}
