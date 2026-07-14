/// Deterministic step model for the LeetCode 134 (Gas Station) visualizer.
///
/// Like every recorder in the kit we run the real algorithm once, up front,
/// and emit ONE [GasStationStep] per pseudocode line executed - stepping the
/// UI is then pure index movement and can never double-fire.
///
/// One left-to-right sweep tracks a running tank balance. Whenever it dips
/// negative, no station seen so far can be the start, so the candidate start
/// resets to the next station. `totalGas >= totalCost` is the only extra
/// check needed to know a solution exists at all.
library;

enum GasStationStatus { running, found, notFound, empty }

/// Full pseudocode shown in the panel. `line` in a [GasStationStep] is
/// 1-based into this list.
const List<String> gasStationPseudocode = [
  'totalGas ← 0 ; totalCost ← 0 ; runningGas ← 0 ; startIdx ← 0', // 1
  'for i in 0 … n−1:', // 2
  '  totalGas += gas[i]', // 3
  '  totalCost += cost[i]', // 4
  '  runningGas += gas[i] − cost[i]', // 5
  '  if runningGas < 0:', // 6
  '    runningGas ← 0', // 7
  '    startIdx ← i + 1', // 8
  'if totalGas ≥ totalCost: return startIdx', // 9
  'else: return −1', // 10
];

class GasStationStep {
  final int line; // 1-based pseudocode line highlighted
  final int? i; // station currently being processed
  final int totalGas;
  final int totalCost;
  final int runningGas;
  final int startIdx;
  final String? badge; // comparison/decision just made
  final String log; // plain-English trace entry
  final Set<String> changed; // variable names updated this step (for pulse)
  final GasStationStatus status;
  final int? result; // final answer, set only on the terminal step

  const GasStationStep({
    required this.line,
    this.i,
    this.totalGas = 0,
    this.totalCost = 0,
    this.runningGas = 0,
    this.startIdx = 0,
    this.badge,
    required this.log,
    this.changed = const {},
    this.status = GasStationStatus.running,
    this.result,
  });
}

/// Runs the one-pass running-balance scan over [gas]/[cost] (equal length),
/// recording every pseudocode line executed.
List<GasStationStep> generateGasStationSteps(List<int> gas, List<int> cost) {
  final n = gas.length;
  final steps = <GasStationStep>[];

  if (n == 0 || cost.length != n) {
    steps.add(const GasStationStep(
      line: 1,
      status: GasStationStatus.empty,
      log: 'No stations to check - return 0.',
      result: 0,
    ));
    return steps;
  }

  var totalGas = 0;
  var totalCost = 0;
  var runningGas = 0;
  var startIdx = 0;

  steps.add(const GasStationStep(
    line: 1,
    changed: {'totalGas', 'totalCost', 'runningGas', 'startIdx'},
    log: 'totalGas ← 0, totalCost ← 0, runningGas ← 0, startIdx ← 0.',
  ));

  for (var i = 0; i < n; i++) {
    steps.add(GasStationStep(
      line: 2,
      i: i,
      totalGas: totalGas,
      totalCost: totalCost,
      runningGas: runningGas,
      startIdx: startIdx,
      log: 'i ← $i (gas[$i] = ${gas[i]}, cost[$i] = ${cost[i]}).',
    ));

    totalGas += gas[i];
    steps.add(GasStationStep(
      line: 3,
      i: i,
      totalGas: totalGas,
      totalCost: totalCost,
      runningGas: runningGas,
      startIdx: startIdx,
      changed: const {'totalGas'},
      log: 'totalGas += ${gas[i]} → $totalGas.',
    ));

    totalCost += cost[i];
    steps.add(GasStationStep(
      line: 4,
      i: i,
      totalGas: totalGas,
      totalCost: totalCost,
      runningGas: runningGas,
      startIdx: startIdx,
      changed: const {'totalCost'},
      log: 'totalCost += ${cost[i]} → $totalCost.',
    ));

    final net = gas[i] - cost[i];
    runningGas += net;
    steps.add(GasStationStep(
      line: 5,
      i: i,
      totalGas: totalGas,
      totalCost: totalCost,
      runningGas: runningGas,
      startIdx: startIdx,
      changed: const {'runningGas'},
      log: 'runningGas += ($net) → $runningGas.',
    ));

    final deficit = runningGas < 0;
    steps.add(GasStationStep(
      line: 6,
      i: i,
      totalGas: totalGas,
      totalCost: totalCost,
      runningGas: runningGas,
      startIdx: startIdx,
      badge: 'runningGas ($runningGas) < 0 → $deficit',
      log: deficit
          ? 'Tank would go negative here - station $startIdx..$i can\'t start the trip.'
          : 'Still non-negative - keep going.',
    ));

    if (deficit) {
      runningGas = 0;
      steps.add(GasStationStep(
        line: 7,
        i: i,
        totalGas: totalGas,
        totalCost: totalCost,
        runningGas: runningGas,
        startIdx: startIdx,
        changed: const {'runningGas'},
        log: 'runningGas ← 0.',
      ));

      startIdx = i + 1;
      steps.add(GasStationStep(
        line: 8,
        i: i,
        totalGas: totalGas,
        totalCost: totalCost,
        runningGas: runningGas,
        startIdx: startIdx,
        changed: const {'startIdx'},
        log: 'startIdx ← ${i + 1} - move the candidate start past the deficit.',
      ));
    }
  }

  final feasible = totalGas >= totalCost;
  if (feasible) {
    steps.add(GasStationStep(
      line: 9,
      totalGas: totalGas,
      totalCost: totalCost,
      runningGas: runningGas,
      startIdx: startIdx,
      badge: 'totalGas ($totalGas) ≥ totalCost ($totalCost) → true',
      status: GasStationStatus.found,
      result: startIdx,
      log: 'totalGas ≥ totalCost - a solution exists. Return startIdx = $startIdx.',
    ));
  } else {
    steps.add(GasStationStep(
      line: 10,
      totalGas: totalGas,
      totalCost: totalCost,
      runningGas: runningGas,
      startIdx: startIdx,
      badge: 'totalGas ($totalGas) ≥ totalCost ($totalCost) → false',
      status: GasStationStatus.notFound,
      result: -1,
      log: 'totalGas < totalCost - no station can complete the circuit. Return −1.',
    ));
  }

  return steps;
}
