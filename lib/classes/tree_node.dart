import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:tree_builder/util/pl.dart';

class TreeNode {
  static int _idCounter = 0;

  late int _id;
  get id {
    return _id;
  }

  TreeNode? parent;

  // lista przechowująca identyfikatory argumentów dostępnych do
  // wykorzystania do "splittowania" w danym węźle
  List<int> availableSplitArgs = [];

  // listaw przechowująca identyfikatory próbek branych pod uwagę
  // w danym węźle
  List<int> _samplesIds = [];
  List<int> get samplesIds {
    return _samplesIds;
  }

  set samplesIds(List<int> value) {
    _samplesIds = value;
    recalculateSize();
  }

  // lista przechowująca referencje do węzłów potomnych
  List<TreeNode> children = [];

  // zmienna mówiąca o tym, po jakim argumencie
  // w danym węźle dzielone są próbki
  //
  // -1 oznacza, że dany węzeł nie dzieli próbek
  // czyli jest węzłem - liściem
  int _splitArgId = -1;
  int get splitArgId {
    return _splitArgId;
  }

  set splitArgId(int value) {
    _splitArgId = value;
    recalculateSize();
  }

  String _splitArgName = '';
  String get splitArgName {
    return _splitArgName;
  }

  set splitArgName(String value) {
    _splitArgName = value;
    recalculateSize();
  }

  // zmienna przechowująca opis jaka wartość argumentu
  // z węzła nadrzędnego prowadzi do danego węzła
  //
  // '' oznacza, że dany węzeł nie ma przypisanej
  // wartości podziału, czyli musi to być węzeł - wierzchołek
  String value = '';

  // położenie węzła na stronie (potrzebne do rysowania węzła)
  Offset pos = Offset.zero;

  // zmienne pomocnicze do poprawnego animowania położenia węzła
  Offset startPos = Offset.zero;
  Offset endPos = Offset.zero;

  // zmienna pomocnicza przechowująca rozmiar danego węzła
  Size size = Size.zero;

  // zmienna pomocnicza przechowująca ilość poszczególnych wartości
  // atrybutu decyzyjnego (po to, żeby później można było wyświetlić
  // wykres poziomy na węźle)
  Map<String, int>? samplesDecisionCount;

  // zmienna pomocnicza przechowująca informację o tym
  // jaką szerokość będzie potrzebowało poddrzewo zaczynające
  // się od danego węzła
  double neededWidth = 0;

  // style tekstu wyświetlanego w środku węzła
  TextStyle topTextStyle = TextStyle(
    color: Colors.white,
    backgroundColor: Colors.transparent,
  );

  // szerokość wykresu wyświetlanego w węźle
  double? _barWidth;

  double? get barWidth {
    return _barWidth;
  }

  set barWidth(double? value) {
    _barWidth = value;
    recalculateSize();
  }

  // wysokość wykresu wyświetlanego w węźle
  double _barHeight = 10;

  double get barHeight {
    return _barHeight;
  }

  set barHeight(double value) {
    _barHeight = value;
    recalculateSize();
  }

  // wewnętrzny padding węzła
  EdgeInsets _padding = EdgeInsets.fromLTRB(8, 8, 8, 8);
  EdgeInsets get padding {
    return _padding;
  }

  set padding(EdgeInsets value) {
    _padding = value;
    recalculateSize();
  }

  // wewnętrzny odstęp pomiędzy poszczególnymi komponentami
  // wewnętrznymi węzła
  double _innerSpacing = 5;
  double get innerSpacing {
    return _innerSpacing;
  }

  set innerSpacing(double value) {
    _innerSpacing = max(value, 0);
    recalculateSize();
  }

  void recalculateSize() {
    print('recalc');
    TextSpan span = TextSpan(
      children: [
        if (splitArgName.isNotEmpty) ...{
          TextSpan(
            style: topTextStyle,
            text: splitArgName,
          ),
          TextSpan(text: '\n'),
        },
        TextSpan(
          style: topTextStyle,
          text: '${samplesIds.length} ${objectPluralPL(samplesIds.length)}',
        ),
      ],
    );

    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    Size newSize = Size.zero;
    double newHeight =
        padding.top + padding.bottom + tp.height + innerSpacing + barHeight;
    double newWidth =
        padding.left + padding.right + max(tp.width, barWidth ?? 0);
    newSize = Size(newWidth, newHeight);
    size = newSize;
  }

  Rect getBoundingRect() {
    return Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
  }

  TreeNode({Offset startingPos = Offset.zero}) {
    pos = startingPos;
    startPos = startingPos;
    endPos = startingPos;
    _id = _idCounter;
    _idCounter += 1;
  }
}
