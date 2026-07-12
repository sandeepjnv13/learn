import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app_scope.dart';
import 'router.dart';
import 'services/content_service.dart';
import 'theme/app_theme.dart';
import 'viz/init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // clean URLs (no #); paired with 404.html on Pages
  registerVisualizers();

  final content = ContentService();
  await content.load();

  runApp(LearnApp(content: content));
}

class LearnApp extends StatefulWidget {
  final ContentService content;
  const LearnApp({super.key, required this.content});

  @override
  State<LearnApp> createState() => _LearnAppState();
}

class _LearnAppState extends State<LearnApp> {
  final _themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  late final _router = buildRouter(widget.content);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      content: widget.content,
      themeMode: _themeMode,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, mode, _) {
          return MaterialApp.router(
            title: 'Learn',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
