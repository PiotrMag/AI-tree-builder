import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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
  List<int> samplesIds = [];

  // lista przechowująca referencje do węzłów potomnych
  List<TreeNode> children = [];

  // zmienna mówiąca o tym, po jakim argumencie
  // w danym węźle dzielone są próbki
  //
  // -1 oznacza, że dany węzeł nie dzieli próbek
  // czyli jest węzłem - liściem
  int splitArgId = -1;

  // zmienna przechowująca opis jaka wartość argumentu
  // z węzła nadrzędnego prowadzi do danego węzła
  //
  // '' oznacza, że dany węzeł nie ma przypisanej
  // wartości podziału, czyli musi to być węzeł - wierzchołek
  String value = '';

  // położenie węzła na stronie (potrzebne do rysowania węzła)
  Offset pos = Offset.zero;

  // zmienna pomocnicza przechowująca rozmiar danego węzła
  Offset? size = Offset.zero;

  Rect getBoundingRect() {
    return Rect.fromLTWH(pos.dx, pos.dy, size?.dx ?? 0, size?.dy ?? 0);
  }

  TreeNode() {
    _id = _idCounter;
    _idCounter += 1;
  }
}
