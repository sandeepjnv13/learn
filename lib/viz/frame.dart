/// Generic snapshot of an array-like structure at one step of an algorithm.
///
/// Both hand-authored `frames:` in markdown and Dart algorithm recorders
/// (Phase 3) produce the same `ArrayFrame` list, so renderers never need to
/// know which produced them.
class ArrayFrame {
  final List<num> data;
  final List<int> highlight; // indices to emphasize
  final Map<String, int> pointers; // named pointers, e.g. {"i": 0, "j": 3}
  final String? note; // caption shown under the visual for this step

  const ArrayFrame({
    required this.data,
    this.highlight = const [],
    this.pointers = const {},
    this.note,
  });

  factory ArrayFrame.fromMap(Map<String, dynamic> m) {
    return ArrayFrame(
      data: (m['data'] as List<dynamic>? ?? const [])
          .map((e) => e as num)
          .toList(),
      highlight: (m['highlight'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      pointers: (m['pointers'] as Map<dynamic, dynamic>? ?? const {}).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
      note: m['note'] as String?,
    );
  }
}
