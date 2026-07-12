import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'services/content_service.dart';
import 'ui/app_shell.dart';
import 'ui/content_page.dart';
import 'ui/home_page.dart';

/// Builds the router from the loaded content manifest: one route per page,
/// all wrapped in the persistent [AppShell]. Deep links work directly.
GoRouter buildRouter(ContentService content) {
  final pageRoutes = content.allPages().map((page) {
    return GoRoute(
      path: page.route,
      builder: (context, state) => ContentPage(asset: page.asset!),
    );
  }).toList();

  return GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentRoute: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ...pageRoutes,
        ],
      ),
    ],
    errorBuilder: (context, state) => AppShell(
      currentRoute: state.uri.path,
      child: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
}
