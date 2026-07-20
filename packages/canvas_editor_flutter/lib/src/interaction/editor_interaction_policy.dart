// Path: oss_packages/canvas_editor_flutter/lib/src/interaction/editor_interaction_policy.dart
import 'package:flutter/foundation.dart';
import 'package:canvas_core/canvas_core_runtime.dart';

typedef NodeMovePermission = bool Function(Node node);

typedef NodeTransformChromePermission = bool Function(Node node);

@immutable
class EditorInteractionPolicy {
  const EditorInteractionPolicy({
    this.canMoveNode,
    this.showTransformChromeNode,
  });

  /// Custom movement rule.
  ///
  /// By default, unlocked nodes can be moved.
  /// Applications can restrict movement through this policy.
  final NodeMovePermission? canMoveNode;

  /// Custom transform-chrome visibility rule.
  ///
  /// This is intentionally separate from [canMoveNode]. Some nodes may be
  /// non-movable for placement/layout reasons and should not show resize handles,
  /// while other non-movable states may still want their normal selection chrome.
  final NodeTransformChromePermission? showTransformChromeNode;

  bool canMove(Node node) {
    if (node.locked) return false;
    return canMoveNode?.call(node) ?? true;
  }

  bool showTransformChrome(Node node) {
    return showTransformChromeNode?.call(node) ?? true;
  }

  EditorInteractionPolicy merge(EditorInteractionPolicy other) {
    return EditorInteractionPolicy(
      canMoveNode: _mergeCanMove(canMoveNode, other.canMoveNode),
      showTransformChromeNode: _mergeShowTransformChrome(
        showTransformChromeNode,
        other.showTransformChromeNode,
      ),
    );
  }
}

NodeMovePermission? _mergeCanMove(
  NodeMovePermission? a,
  NodeMovePermission? b,
) {
  if (a == null) return b;
  if (b == null) return a;

  // All composed policies must allow movement.
  return (node) => a(node) && b(node);
}

NodeTransformChromePermission? _mergeShowTransformChrome(
  NodeTransformChromePermission? a,
  NodeTransformChromePermission? b,
) {
  if (a == null) return b;
  if (b == null) return a;

  // All composed policies must allow transform chrome.
  return (node) => a(node) && b(node);
}
