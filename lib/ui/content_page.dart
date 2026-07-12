import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/content_service.dart';
import 'markdown/markdown_document.dart';

/// Loads and renders a single markdown page.
class ContentPage extends StatefulWidget {
  final String asset;
  const ContentPage({super.key, required this.asset});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  Future<PageContent>? _future;
  String? _loadedAsset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedAsset != widget.asset) {
      _loadedAsset = widget.asset;
      _future = AppScope.of(context).content.loadPage(widget.asset);
    }
  }

  @override
  void didUpdateWidget(ContentPage old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) {
      _loadedAsset = widget.asset;
      _future = AppScope.of(context).content.loadPage(widget.asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PageContent>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return Center(child: Text('Could not load page.\n${snap.error ?? ''}'));
        }
        final page = snap.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 80),
          child: MarkdownDocument(
            body: page.body,
            pageAsset: widget.asset,
          ),
        );
      },
    );
  }
}
