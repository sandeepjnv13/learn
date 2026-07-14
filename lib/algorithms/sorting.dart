import '../viz/frame.dart';

/// Bubble sort, instrumented to record a frame at each comparison and swap.
/// The real algorithm logic is untouched - `frames.add(...)` is the only
/// addition, and it is what drives the animation.
List<ArrayFrame> bubbleSort(List<num> input) {
  final a = List<num>.from(input);
  final frames = <ArrayFrame>[
    ArrayFrame(data: List.of(a), note: 'Start'),
  ];

  for (var i = 0; i < a.length - 1; i++) {
    var swappedAny = false;
    for (var j = 0; j < a.length - 1 - i; j++) {
      frames.add(ArrayFrame(
        data: List.of(a),
        highlight: [j, j + 1],
        pointers: {'j': j},
        note: 'Compare ${a[j]} and ${a[j + 1]}',
      ));
      if (a[j] > a[j + 1]) {
        final tmp = a[j];
        a[j] = a[j + 1];
        a[j + 1] = tmp;
        swappedAny = true;
        frames.add(ArrayFrame(
          data: List.of(a),
          highlight: [j, j + 1],
          pointers: {'j': j},
          note: 'Swap → ${a[j]}, ${a[j + 1]}',
        ));
      }
    }
    if (!swappedAny) break;
  }

  frames.add(ArrayFrame(data: List.of(a), note: 'Sorted'));
  return frames;
}
