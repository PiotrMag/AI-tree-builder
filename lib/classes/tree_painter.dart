import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tree_builder/classes/dataframe.dart';

import 'tree_node.dart';
import '../util/pl.dart';

class TreePainter extends CustomPainter {
  final List<TreeNode> tree;
  final Offset pos;
  final int selectedNodeId;

  TreePainter({
    required this.selectedNodeId,
    required this.tree,
    required this.pos,
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

    // rysowanie poszczególnych węzłów
    for (TreeNode node in tree) {
      // wstępne przygotowanie tekstu w węźle

      TextSpan span = TextSpan(
        children: [
          if (node.bestGiniValue != double.infinity) ...{
            TextSpan(
              style: node.topTextStyle,
              text: 'gini: ${node.bestGiniValue}',
            ),
            TextSpan(text: '\n'),
          },
          TextSpan(
            style: node.topTextStyle,
            text:
                '${node.samplesIds.length} ${objectPluralPL(node.samplesIds.length)}',
          ),
        ],
      );

      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      TextSpan span2 = TextSpan(children: [
        if (node.splitArgName.isNotEmpty) ...{
          TextSpan(
            style: node.topTextStyle,
            text: node.splitArgName,
          ),
        },
      ]);

      TextPainter tp2 =
          TextPainter(text: span2, textDirection: TextDirection.ltr);
      tp2.layout();

      double barWidth = 0;
      if (node.barWidth != null) {
        barWidth = node.barWidth!;
      } else {
        barWidth = max(tp.width, tp2.width);
      }

      // po to, żeby węzeł zaaktulaizował swój rozmiar
      node.recalculateSize();
      node.getBoundingRect();

      // przeliczenie rozmiaru węzła
      // Size nodeSize = Size(np.width + node.padding.left + node.padding.right,
      //     np.height + node.padding.top + node.padding.bottom + node.barHeight);
      // if (nodeSize.width < barWidth + node.padding.left + node.padding.right) {
      //   nodeSize = Size(
      //       barWidth + node.padding.left + node.padding.right, nodeSize.height);
      // }
      // if (nodeSize.width < 40) {
      //   nodeSize = Size(40, nodeSize.height);
      // }
      // if (nodeSize.height < 40) {
      //   nodeSize = Size(nodeSize.width, 40);
      // }
      // node.size = nodeSize;

      // rysowanie linii
      if (node.parent != null) {
        Offset lineFirstEnd =
            Offset(node.pos.dx + node.size.width / 2, node.pos.dy) + pos;
        Offset lineSecondEnd = Offset(
                node.parent!.pos.dx + node.parent!.size.width / 2,
                node.parent!.pos.dy + node.parent!.size.height) +
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
              node.size.width, node.size.height),
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
                      node.padding.left +
                      counter / totalCount * barWidth +
                      pos.dx,
                  node.pos.dy +
                      node.padding.top +
                      tp.height +
                      node.innerSpacing +
                      pos.dy,
                  entry.value / totalCount * barWidth,
                  node.barHeight),
              barPaint);
          counter += entry.value;
        }
      }

      // ewentualne wypisanie nazwy atrybutu, względem którego nastąpił podział
      // if (node.splitArgId >= 0) {
      tp.paint(
          canvas,
          Offset(node.pos.dx + node.size.width / 2,
                  node.pos.dy + node.padding.top) +
              pos +
              Offset(-tp.width / 2, 0));
      // }
      tp2.paint(
          canvas,
          Offset(node.pos.dx + node.size.width / 2,
                  node.pos.dy + node.padding.top) +
              pos +
              Offset(
                  -tp2.width / 2,
                  tp.height +
                      node.innerSpacing +
                      node.barHeight +
                      node.innerSpacing));

      // ewentualne rysowanie krawędzi węzła (jeżeli węzł jest obecnie zaznaczony)
      if (node.id == selectedNodeId) {
        canvas.drawRect(
            Rect.fromLTWH(node.pos.dx + pos.dx, node.pos.dy + pos.dy,
                node.size.width, node.size.height),
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
