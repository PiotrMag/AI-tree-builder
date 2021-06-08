import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tree_builder/classes/dataframe.dart';

import 'tree_node.dart';

class TreePainter extends CustomPainter {
  final List<TreeNode> tree;
  final Offset pos;
  final int selectedNodeId;
  final EdgeInsets padding;
  final DataFrame dataFrame;
  final double? samplesBarWidth;
  final double samplesBarHeight;

  TreePainter({
    required this.selectedNodeId,
    required this.tree,
    required this.pos,
    required this.padding,
    required this.dataFrame,
    required this.samplesBarWidth,
    required this.samplesBarHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ustawienie obszaru rysowania
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // utworzenie farby do rysowania
    Paint parentPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

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

    TextStyle nodeTextStyle = TextStyle(
      color: Colors.white,
      backgroundColor: Colors.transparent,
    );

    TextStyle lineTextStyle = TextStyle(
      color: Colors.grey[800],
      backgroundColor: Colors.white,
    );

    List<String> dataFrameHeaders = dataFrame.getHeaders();

    // rysowanie poszczególnych węzłów
    for (TreeNode node in tree) {
      // wstępne przygotowanie tekstu w węźle
      TextSpan span = TextSpan(
        children: [
          if (node.splitArgId > -1) ...{
            TextSpan(
              style: nodeTextStyle,
              text:
                  node.splitArgId >= 0 ? dataFrameHeaders[node.splitArgId] : '',
            ),
            TextSpan(text: '\n'),
          },
          TextSpan(
            style: nodeTextStyle,
            text: '${node.samplesIds.length} obiektów',
          ),
        ],
      );
      TextPainter np = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      np.layout();

      double barWidth = 0;
      if (samplesBarWidth != null) {
        barWidth = samplesBarWidth!;
      } else {
        barWidth = np.width + padding.left + padding.right;
      }

      // przeliczenie rozmiaru węzła
      Offset nodeSize = Offset(np.width + padding.left + padding.right,
          np.height + padding.top + padding.bottom + samplesBarHeight);
      if (nodeSize.dx < barWidth + padding.left + padding.right) {
        nodeSize = Offset(barWidth + padding.left + padding.right, nodeSize.dy);
      }
      if (nodeSize.dx < 40) {
        nodeSize = Offset(40, nodeSize.dy);
      }
      if (nodeSize.dy < 40) {
        nodeSize = Offset(nodeSize.dx, 40);
      }
      node.size = nodeSize;

      if (node.parent != null) {
        // rysowanie linii
        Offset lineFirstEnd =
            Offset(node.pos.dx + (node.size?.dx ?? 0) / 2, node.pos.dy) + pos;
        Offset lineSecondEnd = Offset(
                node.parent!.pos.dx + (node.parent!.size?.dx ?? 0) / 2,
                node.parent!.pos.dy + (node.parent!.size?.dy ?? 0)) +
            pos;
        canvas.drawLine(lineFirstEnd, lineSecondEnd, linePaint);
        // rysowanie oznaczeń na liniach
        Offset lineMiddle = (lineFirstEnd + lineSecondEnd) / 2;
        TextSpan span =
            TextSpan(style: lineTextStyle, text: node.value.toString());
        TextPainter tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, lineMiddle - Offset(tp.width / 2, tp.height / 2));
      }

      // rysowanie tła węzła
      canvas.drawRect(
          Rect.fromLTWH(node.pos.dx + pos.dx, node.pos.dy + pos.dy,
              node.size?.dx ?? 10, node.size?.dy ?? 10),
          // squarePaint);
          (node.children.length <= 0 ? leafPaint : parentPaint));

      // wyrysowanie wykresu z podziałem próbek względem atrybutu decyzyjnego
      int totalCount = 0;
      int counter = 0;
      node.samplesDecisionCount?.forEach((key, value) => totalCount += value);
      if (node.samplesDecisionCount != null) {
        for (var entry in node.samplesDecisionCount!.entries) {
          Paint barPaint = Paint()
            ..color = Color.fromARGB(255, entry.key.hashCode,
                entry.key.hashCode, entry.key.hashCode);

          canvas.drawRect(
              Rect.fromLTWH(
                  node.pos.dx +
                      padding.left +
                      counter / totalCount * barWidth +
                      pos.dx,
                  node.pos.dy + padding.top + np.height + 5 + pos.dy,
                  entry.value / totalCount * barWidth,
                  samplesBarHeight),
              barPaint);
          counter += entry.value;
        }
      }

      // ewentualne wypisanie nazwy atrybutu, względem którego nastąpił podział
      // if (node.splitArgId >= 0) {
      np.paint(
          canvas,
          Offset(node.pos.dx + (node.size?.dx ?? 0) / 2,
                  node.pos.dy + padding.top) +
              pos -
              Offset(np.width / 2, 0));
      // }

      // ewentualne rysowanie krawędzi węzła (jeżeli węzł jest obecnie zaznaczony)
      if (node.id == selectedNodeId) {
        canvas.drawRect(
            Rect.fromLTWH(node.pos.dx + pos.dx, node.pos.dy + pos.dy,
                node.size?.dx ?? 10, node.size?.dy ?? 10),
            selectedPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    oldDelegate = oldDelegate as TreePainter;
    // return !ListEquality().equals(this.tree, oldDelegate.tree) ||
    //     pos.dx != oldDelegate.pos.dx ||
    //     pos.dy != oldDelegate.pos.dy;
    return true;
  }
}
