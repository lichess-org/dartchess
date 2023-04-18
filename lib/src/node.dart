import 'package:meta/meta.dart';

/// Root node containing a list of child nodes.
class Node<T> {
  final List<ChildNode<T>> children = [];

  /// Adds a child to this node.
  void addChild(ChildNode<T> node) => children.add(node);

  /// Prepends a child to this node.
  void prependChild(ChildNode<T> node) => children.insert(0, node);

  /// An iterable of all nodes on the mainline.
  Iterable<T> get mainline sync* {
    Node<T> node = this;
    while (node.children.isNotEmpty) {
      final child = node.children.first;
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

/// Generic child node.
///
/// This class has a mutable `data` field.
class ChildNode<T> extends Node<T> {
  ChildNode(this.data);

  /// Node data.
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
