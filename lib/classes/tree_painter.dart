import 'package:flutter/cupertino.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'tree_node.dart';

class TreePainter extends CustomPainter {
  final List<TreeNode> tree;
  final Offset pos;
  final int selectedNodeId;

  TreePainter(
      {required this.selectedNodeId, required this.tree, required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    // ustawienie obszaru rysowania
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // utworzenie farby do rysowania
    Paint squarePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    Paint leafPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    Paint selectedPaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.bevel
      ..strokeWidth = 5;

    Paint linePaint = Paint()..color = Colors.grey[700]!;

    // rysowanie poszczególnych węzłów
    for (TreeNode node in tree) {
      if (node.parent != null) {
        canvas.drawLine(
            Offset(node.pos.dx + 25, node.pos.dy) + pos,
            Offset(node.parent!.pos.dx + 25, node.parent!.pos.dy + 50) + pos,
            linePaint);
      }
      canvas.drawRect(
          Rect.fromLTWH(node.pos.dx + pos.dx, node.pos.dy + pos.dy, 50, 50),
          // squarePaint);
          (node.children.length <= 0 ? leafPaint : squarePaint));
      if (node.id == selectedNodeId) {
        canvas.drawRect(
            Rect.fromLTWH(node.pos.dx + pos.dx, node.pos.dy + pos.dy, 50, 50),
            selectedPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return ListEquality().equals(this.tree, (oldDelegate as TreePainter).tree);
  }
}
