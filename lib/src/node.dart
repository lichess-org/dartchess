import 'package:meta/meta.dart';

/// Parent node containing a list of child nodes (does not contain any data itself).
class Node<T> {
  final List<ChildNode<T>> children = [];

  /// Implements an [Iterable] to iterate the mainline.
  Iterable<T> mainline() sync* {
    var node = this;
    while (node.children.isNotEmpty) {
      final child = node.children[0];
      yield child.data;
      node = child;
    }
  }

  /// Function to walk through each node and transform this node tree into
  /// a [Node<U>] tree.
  Node<U> transform<U, C>(C ctx, TransformResult<C, U>? Function(C, T, int) f) {
    final root = Node<U>();
    final stack = [_TransformFrame<T, U, C>(this, root, ctx)];

    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      for (int childIdx = 0;
          childIdx < frame.before.children.length;
          childIdx++) {
        C ctx = frame.ctx;
        final childBefore = frame.before.children[childIdx];
        final transformData = f(ctx, childBefore.data, childIdx);
        if (transformData != null) {
          ctx = transformData.ctx;
          final childAfter = ChildNode(transformData.data);
          frame.after.children.add(childAfter);
          stack.add(_TransformFrame(childBefore, childAfter, ctx));
        }
      }
    }
    return root;
  }
}

/// PGN child Node.
///
/// This class has a mutable `data` field.
class ChildNode<T> extends Node<T> {
  ChildNode(this.data);

  /// PGN Data.
  T data;
}

/// Used to return result in the callback of [Node.transform].
@immutable
class TransformResult<C, T> {
  const TransformResult(this.ctx, this.data);
  final C ctx;
  final T data;
}

class _TransformFrame<T, U, C> {
  final Node<T> before;
  final Node<U> after;
  final C ctx;

  _TransformFrame(this.before, this.after, this.ctx);
}
