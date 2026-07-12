import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'sidebar.dart';

/// Persistent layout: sidebar on wide screens, drawer on narrow ones. On wide
/// screens the sidebar can be collapsed to give the content the full width.
class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _wide = 900.0;

  bool _navCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = AppScope.of(context).themeMode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wide;
        final showSidebar = wide && !_navCollapsed;
        return Scaffold(
          drawer: wide
              ? null
              : Drawer(
                  child: Sidebar(
                    currentRoute: widget.currentRoute,
                    onNavigate: () => Navigator.of(context).maybePop(),
                  ),
                ),
          appBar: wide
              ? null
              : AppBar(
                  title: const Text('Learn'),
                  actions: [_themeButton(themeMode)],
                ),
          body: Row(
            children: [
              if (showSidebar)
                Sidebar(
                  currentRoute: widget.currentRoute,
                  onCollapse: () => setState(() => _navCollapsed = true),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (wide)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                        child: Row(
                          children: [
                            if (_navCollapsed)
                              IconButton(
                                tooltip: 'Show sidebar',
                                icon: const Icon(Icons.menu_rounded),
                                onPressed: () =>
                                    setState(() => _navCollapsed = false),
                              ),
                            const Spacer(),
                            _themeButton(themeMode),
                          ],
                        ),
                      ),
                    // No global width cap here: pages decide their own width so
                    // full-page visualizers can use the space while prose stays
                    // at a readable measure (see MarkdownDocument).
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themeButton(ValueNotifier<ThemeMode> themeMode) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          onPressed: () =>
              themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark,
        );
      },
    );
  }
}
