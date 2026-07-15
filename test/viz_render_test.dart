import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/viz/registry.dart';
import 'package:learn/viz/renderers/min_path_dp/min_path_dp_view.dart';
import 'package:learn/viz/renderers/overlapping_subproblems/overlapping_subproblems_view.dart';

/// Render tests for the two dynamic-programming visualizers.
///
/// These pump the real widgets at desktop and narrow widths in both themes: a
/// layout overflow or a failed assertion inside the new `GridBoard` /
/// `RecursionTree` primitives fails the test rather than showing up as a yellow
/// stripe in the browser.
void main() {
  const grid = [
    [1, 3, 1],
    [1, 5, 1],
    [4, 2, 1],
  ];

  VizContext ctx() => const VizContext(
        config: {'grid': grid},
        pageAsset: 'content/ds-algo/dynamic-programming/overlapping-subproblems.md',
      );

  Widget host(Widget child, Brightness brightness) => MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: brightness,
          ),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      );

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Drives the real control bar to the last step. Taps past the end are no-ops
  /// once the button disables, so a generous count is safe.
  Future<void> stepToEnd(WidgetTester tester) async {
    final forward = find.widgetWithIcon(IconButton, Icons.skip_next_rounded);
    for (var i = 0; i < 60; i++) {
      if (tester.widget<IconButton>(forward).onPressed == null) break;
      await tester.tap(forward);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  group('min-path-dp view', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders and steps to the answer (${brightness.name})',
          (tester) async {
        await sized(tester, const Size(1400, 1000));
        await tester.pumpWidget(host(MinPathDpView(ctx()), brightness));
        await tester.pumpAndSettle();

        expect(find.text('Min Cost Path - bottom-up table'), findsOneWidget);

        await stepToEnd(tester);

        expect(find.textContaining('Cheapest path costs 7'), findsOneWidget);
      });
    }

    testWidgets('renders narrow without overflowing', (tester) async {
      await sized(tester, const Size(500, 900));
      await tester.pumpWidget(host(MinPathDpView(ctx()), Brightness.light));
      await tester.pumpAndSettle();
      expect(find.text('Min Cost Path - bottom-up table'), findsOneWidget);
    });

    // A short window pins VizScaffold to its 480px minimum stage height - the
    // tightest the desktop layout ever gets.
    testWidgets('renders in a short window', (tester) async {
      await sized(tester, const Size(1400, 700));
      await tester.pumpWidget(host(MinPathDpView(ctx()), Brightness.light));
      await tester.pumpAndSettle();
      await stepToEnd(tester);
      expect(find.textContaining('Cheapest path costs 7'), findsOneWidget);
    });

    testWidgets('a preset reloads the grid', (tester) async {
      await sized(tester, const Size(1400, 1000));
      await tester.pumpWidget(host(MinPathDpView(ctx()), Brightness.light));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Examples'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Single cell').last);
      await tester.pumpAndSettle();
      await stepToEnd(tester);

      // A 1x1 grid needs no loops - the answer is just grid[0][0].
      expect(find.textContaining('Cheapest path costs 5'), findsOneWidget);
    });
  });

  group('overlapping-subproblems view', () {
    for (final brightness in Brightness.values) {
      testWidgets('toggles naive → memo (${brightness.name})', (tester) async {
        await sized(tester, const Size(1400, 1000));
        await tester.pumpWidget(
            host(OverlappingSubproblemsView(ctx()), brightness));
        await tester.pumpAndSettle();

        // Naive: the exponential tally, no memo table.
        expect(find.textContaining('19 calls to solve 9 distinct cells'),
            findsOneWidget);
        expect(find.text('memo'), findsNothing);
        expect(find.text('×6'), findsOneWidget);

        await tester.tap(find.text('Add a memo'));
        await tester.pumpAndSettle();

        // Memoized: the collapse, plus the filled table beside it.
        expect(find.textContaining('19 nodes → 9 computed'), findsOneWidget);
        expect(find.text('memo'), findsOneWidget);
        expect(find.text('1 compute + 5 hits'), findsOneWidget);
      });
    }

    testWidgets('renders narrow in both modes', (tester) async {
      await sized(tester, const Size(500, 900));
      await tester.pumpWidget(
          host(OverlappingSubproblemsView(ctx()), Brightness.light));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add a memo'));
      await tester.pumpAndSettle();
      expect(find.text('memo'), findsOneWidget);
    });

    testWidgets('renders in a short window', (tester) async {
      await sized(tester, const Size(1400, 700));
      await tester.pumpWidget(
          host(OverlappingSubproblemsView(ctx()), Brightness.light));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add a memo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('19 nodes → 9 computed'), findsOneWidget);
    });

    testWidgets('an oversized grid falls back instead of exploding',
        (tester) async {
      await sized(tester, const Size(1400, 1000));
      await tester.pumpWidget(host(
        OverlappingSubproblemsView(const VizContext(
          // 6x6 would expand to thousands of naive nodes.
          config: {
            'grid': [
              [1, 1, 1, 1, 1, 1],
              [1, 1, 1, 1, 1, 1],
              [1, 1, 1, 1, 1, 1],
              [1, 1, 1, 1, 1, 1],
              [1, 1, 1, 1, 1, 1],
              [1, 1, 1, 1, 1, 1],
            ]
          },
          pageAsset: 'x.md',
        )),
        Brightness.light,
      ));
      await tester.pumpAndSettle();

      // Clamped back to the 3x3 default.
      expect(find.textContaining('19 calls to solve 9 distinct cells'),
          findsOneWidget);
    });
  });
}
