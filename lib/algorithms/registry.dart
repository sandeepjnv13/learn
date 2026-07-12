import '../viz/frame.dart';
import 'sorting.dart';
import 'searching.dart';

/// Maps an `algo:` name to a Dart function that runs the real algorithm and
/// records an [ArrayFrame] per step. This is the "live" visualizer model:
/// the algorithm itself produces the animation.
///
/// Add an algorithm = write a recorder function + register it here.
typedef AlgorithmRunner = List<ArrayFrame> Function(List<num> input);

class AlgorithmRegistry {
  AlgorithmRegistry._();

  static final Map<String, AlgorithmRunner> _runners = {
    'bubble-sort': bubbleSort,
    'binary-search': binarySearch,
  };

  static List<ArrayFrame> run(String name, List<num> input) {
    final runner = _runners[name];
    if (runner == null) {
      return [
        ArrayFrame(data: input, note: 'Unknown algorithm: "$name"'),
      ];
    }
    return runner(input);
  }
}
