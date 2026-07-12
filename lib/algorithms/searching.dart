import '../viz/frame.dart';

/// Binary search over a sorted array, recording a frame per probe.
/// By convention the target is the last element of `input`; the array searched
/// is everything before it (keeps the markdown config to a single list).
List<ArrayFrame> binarySearch(List<num> input) {
  if (input.isEmpty) return [const ArrayFrame(data: [])];

  final target = input.last;
  final a = input.sublist(0, input.length - 1)..sort();
  final frames = <ArrayFrame>[
    ArrayFrame(data: List.of(a), note: 'Searching for $target'),
  ];

  var lo = 0;
  var hi = a.length - 1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    frames.add(ArrayFrame(
      data: List.of(a),
      highlight: [mid],
      pointers: {'lo': lo, 'mid': mid, 'hi': hi},
      note: 'Probe index $mid → ${a[mid]}',
    ));
    if (a[mid] == target) {
      frames.add(ArrayFrame(
        data: List.of(a),
        highlight: [mid],
        pointers: {'found': mid},
        note: 'Found $target at index $mid',
      ));
      return frames;
    } else if (a[mid] < target) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }

  frames.add(ArrayFrame(data: List.of(a), note: '$target not found'));
  return frames;
}
