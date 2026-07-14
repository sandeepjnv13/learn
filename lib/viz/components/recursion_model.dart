/// Flutter-free data model shared by every recursion visualizer: the phase
/// vocabulary and the call-stack frame snapshot. Kept pure so deterministic
/// step recorders (which must not import Flutter) can build frame snapshots
/// directly, and the Flutter-side [CallStackPanel] just renders them.
library;

/// The phase a recursive algorithm is in *this step*. This is the shared
/// vocabulary that makes every recursion visualizer read the same way: you are
/// always either going **down** into a subtree, hitting a **base case**,
/// **combining** children's results, or handing a value back **up**.
enum RecursionPhase {
  /// Descending - a new recursive call is about to run (a frame is pushed).
  descend,

  /// A base case fired - this call returns immediately without recursing.
  base,

  /// Combining the resolved results of child calls in the current frame.
  combine,

  /// Returning a value up to the parent (a frame is popped).
  returnUp,
}

/// A local variable inside a recursion frame (e.g. `leftLca`), shown in the
/// call-stack card. Until the child call that fills it returns, it is
/// [resolved] == false and rendered as a faded `…` placeholder - so you can
/// literally see which sub-result the frame is still waiting on.
class FrameLocal {
  final String name;
  final String value;
  final bool resolved;

  const FrameLocal(this.name, this.value, {this.resolved = true});
}

/// One stack frame in a call-stack render. Display-only: a [signature] label
/// (e.g. `lca(5)`), its [locals], and - once known - the [returns] value.
/// [refId] optionally links the frame to a node in a structure primitive so a
/// view can light up the matching node / spine.
class RecursionFrame {
  final String signature;
  final List<FrameLocal> locals;

  /// The value this frame will return, once resolved (null while still running).
  final String? returns;

  /// True for the frame currently executing (top of stack).
  final bool active;

  /// True on the step where this frame hands its result back up (pop).
  final bool returning;

  /// Optional link to a structure node id (tree/graph), for spine highlighting.
  final int? refId;

  const RecursionFrame({
    required this.signature,
    this.locals = const [],
    this.returns,
    this.active = false,
    this.returning = false,
    this.refId,
  });
}
