import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:tree_builder/classes/dataframe.dart';
import 'package:tree_builder/classes/tree_node.dart';

import 'classes/simple_value.dart';
import 'classes/tree_painter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tree Builder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  @override
  _EditorPageState createState() => _EditorPageState();
}

enum PointerState {
  Up,
  Down,
  Dragging,
}

class _EditorPageState extends State<EditorPage> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  GlobalKey<_TreeViewState> treeViewKey = GlobalKey();

  DataFrame dataFrame = DataFrame();
  List<bool> inputTableCheckedItems = [];

  List<TextEditingController> addRowFormControllers = [];

  TextEditingController columnNameController = TextEditingController();
  FocusNode columnNameEditorFocusNode = FocusNode();

  ScrollController inputTableVerticalScrollConstroller = ScrollController();
  ScrollController inputTableHorizontalScrollConstroller = ScrollController();

  bool showDataInput = false;
  bool showStats = false;
  bool showSettings = false;
  bool showDetails = false;
  bool showSpeedSelector = false;

  bool run = false;

  int selectedToolNumber = 1;

  double sliderValue = 0.25;

  SimpleValue<Offset> pos = SimpleValue(value: Offset.zero);

  Timer? simulationTimer;

  Queue<TreeNode> treeNodeQueue = Queue();
  TreeNode? root;

  List<TreeNode> treeNodes = [];

  SimpleValue<TreeNode> selectedTreeNode = SimpleValue();
  bool isMovingNode = false;

  bool isSnackbarShowing = false;

  bool resetWaiting = false;

  int outputAttrIndex = -1;

  // zmienne do obsługi kliknięć i przeciągania myszką
  PointerState pointerState = PointerState.Up;
  Offset? pointerDownStartPoint;
  static const double dragStartDistance = 5;
  static const double doubleClickThreshlod = 200;
  int lastClickMillis = 0;

  @override
  void dispose() {
    columnNameEditorFocusNode.dispose();
    addRowFormControllers.forEach((element) {
      element.dispose();
    });
    columnNameController.dispose();
    inputTableHorizontalScrollConstroller.dispose();
    inputTableVerticalScrollConstroller.dispose();
    simulationTimer?.cancel();
    super.dispose();
  }

  bool checkIfBuildDone() {
    print(treeNodeQueue.isEmpty);
    if (treeNodeQueue.isEmpty) {
      if (!isSnackbarShowing) {
        isSnackbarShowing = true;
        ScaffoldMessenger.maybeOf(scaffoldKey.currentContext!)
            ?.showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                // padding: EdgeInsets.all(8),
                elevation: 4,
                content: Row(
                  children: [
                    Icon(
                      Icons.task_alt,
                      color: Colors.white,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Budowa zakończona',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
            .closed
            .then((value) => isSnackbarShowing = false);
      }
      setState(() {
        run = false;
        resetWaiting = true;
      });
      return true;
    }
    return false;
  }

  void handleTimer() {
    // wykonywanie właściwego kodu funkcji timerRunner()

    // jeżeli kolejka węzłów do sprawdzenia jest pusta, to symulacja się kończy
    if (checkIfBuildDone()) return;
    makeStep();
    if (checkIfBuildDone()) return;

    // ustawienie powtórzenia timer'a
    simulationTimer?.cancel();
    simulationTimer =
        Timer(Duration(milliseconds: (1000 * sliderValue).toInt()), () {
      handleTimer();
    });
  }

  double gini(List<List<String?>> samples, int attrIndex) {
    List<String?> attrValues = samples.map((e) => e[attrIndex]).toList();
    List<String?> uniqueClasses = attrValues.toSet().toList();

    double output = 1;

    for (String? c in uniqueClasses) {
      int classSamplesCount = attrValues.where((e) => e == c).length;
      output -= pow(classSamplesCount.toDouble() / attrValues.length, 2);
    }

    return output;
  }

  double giniSplit(
      List<List<String?>> samples, int attrIndex, int outputIndex) {
    List<String?> attrValues = samples.map((e) => e[attrIndex]).toList();
    List<String?> uniqueClasses = attrValues.toSet().toList();

    double giniSplitValue = 0;

    for (String? c in uniqueClasses) {
      List<List<String?>> classSamples =
          samples.where((e) => e[attrIndex] == c).toList();
      giniSplitValue += classSamples.length /
          samples.length *
          gini(classSamples, outputIndex);
    }

    return giniSplitValue;
  }

  void makeStep() {
    TreeNode currentNode = treeNodeQueue.removeFirst();

    int bestAttrIndex = -1;
    double bestSplitValue = double.infinity;

    List<MapEntry<int, List<String?>>> samples = dataFrame
        .getRows()
        .asMap()
        .entries
        .where((e) => currentNode.samplesIds.contains(e.key))
        .toList();

    // odnalezienie tego atrybutu, który najlepiej dzieli próbki
    for (int attr in currentNode.availableSplitArgs) {
      // obliczenie GINI
      double giniSplitValue = giniSplit(
          samples.map((e) => e.value).toList(),
          attr,
          (outputAttrIndex < 0
              ? dataFrame.getHeaders().length - 1
              : outputAttrIndex));

      // jeżeli obecny atrybut lepiej dzieli próbki to należy go zapamiętać
      if (giniSplitValue < bestSplitValue) {
        bestAttrIndex = attr;
        bestSplitValue = giniSplitValue;
      }
    }

    currentNode.splitArgId = bestAttrIndex;
    if (bestAttrIndex >= 0) {
      List<String?> attrValues =
          samples.map((e) => e.value[bestAttrIndex]).toList();
      List<String?> uniqueClasses = attrValues.toSet().toList();

      // zmienna pomocnicza, potrzebna do ustalania położenia nowych
      // węzłów na ekranie
      int counter = 0;

      for (String? c in uniqueClasses) {
        // utworzenie nowego węzła i uzupełnienie danych o nim
        TreeNode newNode = TreeNode();
        newNode.availableSplitArgs =
            List<int>.from(currentNode.availableSplitArgs);
        newNode.availableSplitArgs.remove(bestAttrIndex);
        newNode.parent = currentNode;
        newNode.pos = Offset(
            -100 +
                200 / (uniqueClasses.length - 1) * counter +
                currentNode.pos.dx,
            currentNode.pos.dy + 100);
        newNode.value = c ?? 'null';
        newNode.samplesIds = samples
            .where((e) => e.value[bestAttrIndex] == c)
            .map((e) => e.key)
            .toList();

        // utworzenie listy próbek, które należą do klasy [c]
        List<List<String?>> classSamples = samples
            .where((e) => e.value[bestAttrIndex] == c)
            .map((e) => e.value)
            .toList();

        // jeżeli gini index dla danej klasy != 0, to znaczy, że nie powstał liść
        // i należy ten nowy węzeł dodać do kolejki do podziału
        if (gini(
                classSamples,
                (outputAttrIndex < 0
                    ? dataFrame.getHeaders().length - 1
                    : outputAttrIndex)) !=
            0) {
          treeNodeQueue.addLast(newNode);
        }

        // dodanie nowego węzła jako dziecka obecnego węzła [currentNode]
        currentNode.children.add(newNode);

        //
        treeNodes.add(newNode);

        //
        counter += 1;
      }
    }

    setState(() {});
  }

  void onSimulationButtonTap(bool newValue) {
    if (simulationTimer?.isActive ?? false) {
      simulationTimer?.cancel();
    }
    if (newValue == true) {
      // jeżeli nie ma jeszcze skonstruowanego drzewa, to
      // należy utworzyć korzeń
      if (root == null) {
        treeNodeQueue.clear(); // wyczyszczenie kolejki dla pewności
        root = TreeNode();
        root!.availableSplitArgs =
            List<int>.generate(dataFrame.getHeaders().length, (index) => index);
        root!.availableSplitArgs.remove((outputAttrIndex < 0
            ? dataFrame.getHeaders().length - 1
            : outputAttrIndex));
        root!.samplesIds =
            List<int>.generate(dataFrame.getRows().length, (index) => index);
        root!.pos = Offset(MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2);
        treeNodeQueue.addLast(root!);
        treeNodes.add(root!);
        simulationTimer =
            Timer(Duration(milliseconds: (1000 * sliderValue).toInt()), () {
          handleTimer();
        });
      } else {
        handleTimer();
      }
    }
  }

  void onColumnNameSubmit() {
    if (columnNameController.text.isNotEmpty) {
      setState(() {
        dataFrame.addColumn(columnNameController.text);
        columnNameController.clear();
        addRowFormControllers.add(TextEditingController());
      });
    }
  }

  List<TreeNode> nodeToTree(TreeNode? node) {
    if (root == null) {
      return [];
    }

    List<TreeNode> tree = [];
    Queue<TreeNode> queue = Queue();

    queue.add(node!);

    while (queue.isNotEmpty) {
      TreeNode currentNode = queue.removeFirst();
      tree.add(currentNode);
      for (TreeNode c in currentNode.children) {
        queue.addLast(c);
      }
    }

    return tree;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      key: scaffoldKey,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: TreeView(
                key: treeViewKey,
                treeNodes: treeNodes,
                pos: pos,
                selectedTreeNode: selectedTreeNode),
          ),
          // Center(
          //   child: AnimatedContainer(
          //     width: width,
          //     height: height,
          //     color: color,
          //     duration: Duration(milliseconds: 150),
          //   ),
          // ),
          MouseRegion(
            cursor: selectedToolNumber == 2
                ? SystemMouseCursors.move
                : SystemMouseCursors.basic,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                if (pointerState == PointerState.Up) {
                  pointerState = PointerState.Down;
                  pointerDownStartPoint = event.localPosition;
                }
              },
              onPointerMove: (event) {
                if (pointerState == PointerState.Down &&
                    pointerDownStartPoint != null) {
                  print(
                      'dist ${(event.localPosition - pointerDownStartPoint!).distance}');
                  if ((event.localPosition - pointerDownStartPoint!).distance >=
                      dragStartDistance) {
                    pointerState = PointerState.Dragging;
                    if (selectedTreeNode.value?.getBoundingRect().contains(
                            event.localPosition - (pos.value ?? Offset.zero)) ??
                        false) {
                      isMovingNode = true;
                    } else {
                      isMovingNode = false;
                    }
                  }
                }

                if (pointerState == PointerState.Dragging) {
                  if (selectedToolNumber == 1) {
                    if (selectedTreeNode.value != null && isMovingNode) {
                      treeViewKey.currentState?.setState(() {
                        selectedTreeNode.value?.pos += event.delta;
                      });
                    }
                  } else if (selectedToolNumber == 2) {
                    treeViewKey.currentState?.setState(() {
                      if (pos.value != null) {
                        pos.value = event.delta + pos.value!;
                      }
                    });
                  }
                }
              },
              onPointerUp: (event) {
                if (pointerState == PointerState.Down) {
                  if (DateTime.now().millisecondsSinceEpoch - lastClickMillis >=
                      doubleClickThreshlod) {
                    // pojednycze kliknięcie
                    if (selectedToolNumber == 1) {
                      treeViewKey.currentState?.setState(() {
                        print('Tap');
                        Offset tapPos = event.localPosition;
                        // sprawdzenie, czy któryś z węzłów został kliknięty
                        TreeNode? clickedNode;
                        for (TreeNode node in treeNodes.reversed) {
                          if (node
                              .getBoundingRect()
                              .contains(tapPos - (pos.value ?? Offset.zero))) {
                            clickedNode = node;
                            print(clickedNode);
                            break;
                          }
                        }

                        if (clickedNode != null) {
                          treeNodes.remove(clickedNode);
                          treeNodes.add(clickedNode);
                        }

                        selectedTreeNode.value = clickedNode;
                      });
                    }
                  } else {
                    // podwójne kliknięcie
                    print('DoubleTAP');
                    if (selectedToolNumber == 2) {
                      treeViewKey.currentState?.setState(() {
                        pos.value = Offset.zero;
                      });
                    }
                  }
                  lastClickMillis = DateTime.now().millisecondsSinceEpoch;
                }

                pointerState = PointerState.Up;
              },
            ),

            // GestureDetector(
            //   onPanStart: (details) {
            //     if (selectedTreeNode.value?.getBoundingRect().contains(
            //             details.localPosition - (pos.value ?? Offset.zero)) ??
            //         false) {
            //       isMovingNode = true;
            //     } else {
            //       isMovingNode = false;
            //     }
            //   },
            //   onPanUpdate: (details) {
            //     if (selectedToolNumber == 1) {
            //       if (selectedTreeNode.value != null && isMovingNode) {
            //         treeViewKey.currentState?.setState(() {
            //           selectedTreeNode.value?.pos += details.delta;
            //         });
            //       }
            //     } else if (selectedToolNumber == 2) {
            //       treeViewKey.currentState?.setState(() {
            //         if (pos.value != null) {
            //           pos.value = details.delta + pos.value!;
            //         }
            //       });
            //     }
            //   },
            //   onDoubleTap: () {
            //     if (selectedToolNumber == 2) {
            //       treeViewKey.currentState?.setState(() {
            //         pos.value = Offset.zero;
            //       });
            //     }
            //   },
            //   onTapDown: (details) {
            //     if (selectedToolNumber == 1) {
            //       treeViewKey.currentState?.setState(() {
            //         print('Tap');
            //         Offset tapPos = details.localPosition;
            //         // sprawdzenie, czy któryś z węzłów został kliknięty
            //         TreeNode? clickedNode;
            //         for (TreeNode node in treeNodes.reversed) {
            //           if (node
            //               .getBoundingRect()
            //               .contains(tapPos - (pos.value ?? Offset.zero))) {
            //             clickedNode = node;
            //             print(clickedNode);
            //             break;
            //           }
            //         }

            //         if (clickedNode != null) {
            //           treeNodes.remove(clickedNode);
            //           treeNodes.add(clickedNode);
            //         }

            //         selectedTreeNode.value = clickedNode;
            //       });
            //     }
            //   },
            // ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 250),
            curve: Curves.ease,
            bottom: showDataInput ? 0 : -size.height - 70,
            left: 0,
            right: 0,
            child: Container(
              height: size.height - 70,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 2,
                    color: Colors.black.withAlpha(100),
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Wprowadź dane',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  Flexible(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              flex: 1,
                              child: Row(
                                // mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dataFrame.getHeaders().isNotEmpty) ...{
                                    Flexible(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8, left: 8),
                                        child: Container(
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey[200]!),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(4),
                                            ),
                                          ),
                                          child: Scrollbar(
                                            controller:
                                                inputTableHorizontalScrollConstroller,
                                            isAlwaysShown: true,
                                            notificationPredicate:
                                                (notification) =>
                                                    notification.depth == 1,
                                            thickness: 10,
                                            child: Scrollbar(
                                              controller:
                                                  inputTableVerticalScrollConstroller,
                                              isAlwaysShown: true,
                                              notificationPredicate:
                                                  (notification) =>
                                                      notification.depth == 0,
                                              thickness: 10,
                                              child: SingleChildScrollView(
                                                controller:
                                                    inputTableVerticalScrollConstroller,
                                                scrollDirection: Axis.vertical,
                                                child: SingleChildScrollView(
                                                  controller:
                                                      inputTableHorizontalScrollConstroller,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: DataTable(
                                                    showCheckboxColumn: true,
                                                    columnSpacing: 12,
                                                    headingRowHeight: 48,
                                                    columns: [
                                                      ...dataFrame
                                                          .getHeaders()
                                                          .asMap()
                                                          .entries
                                                          .map(
                                                            (entry) =>
                                                                DataColumn(
                                                              label: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        left:
                                                                            8),
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      entry
                                                                          .value,
                                                                      style: TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.w700),
                                                                    ),
                                                                    IconButton(
                                                                      onPressed:
                                                                          () {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return AlertDialog(
                                                                              title: Text('Usuń kolumnę'),
                                                                              content: RichText(
                                                                                text: TextSpan(
                                                                                  children: [
                                                                                    TextSpan(text: 'Czy na pewno usunąć kolumnę '),
                                                                                    TextSpan(
                                                                                      text: '${entry.value}',
                                                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    TextSpan(text: '?'),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () => Navigator.of(context).pop(),
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.all(8.0),
                                                                                    child: Text('Anuluj'),
                                                                                  ),
                                                                                ),
                                                                                ElevatedButton(
                                                                                  style: ElevatedButton.styleFrom(
                                                                                    primary: Colors.red,
                                                                                  ),
                                                                                  onPressed: () {
                                                                                    Navigator.of(context).pop();
                                                                                    setState(() {
                                                                                      dataFrame.removeColumn(entry.key);
                                                                                      if (dataFrame.getHeaders().isEmpty) {
                                                                                        inputTableCheckedItems.clear();
                                                                                      }
                                                                                      addRowFormControllers.removeAt(entry.key);
                                                                                    });
                                                                                  },
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.all(8.0),
                                                                                    child: Text('Usuń'),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      color: Colors
                                                                          .grey,
                                                                      icon: Icon(
                                                                          Icons
                                                                              .remove),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                    ],
                                                    rows: [
                                                      ...dataFrame
                                                          .getRows()
                                                          .asMap()
                                                          .entries
                                                          .map(
                                                            (e) => DataRow(
                                                              selected:
                                                                  inputTableCheckedItems[
                                                                      e.key],
                                                              onSelectChanged:
                                                                  (value) {
                                                                print(
                                                                    'sel: ${e.key}, val: ${value}');
                                                                setState(() {
                                                                  inputTableCheckedItems[
                                                                          e.key] =
                                                                      value ??
                                                                          false;
                                                                });
                                                              },
                                                              cells: [
                                                                ...e.value.map(
                                                                  (h) =>
                                                                      DataCell(
                                                                    Text(
                                                                      h ??
                                                                          'null',
                                                                      style: TextStyle(
                                                                          color: h == null
                                                                              ? Colors.grey[400]
                                                                              : Colors.black),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  },
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButtonWithTooltip(
                                      icon: Icons.add_box_rounded,
                                      tooltipText: 'Dodaj kolumnę',
                                      iconColor: Colors.white,
                                      backgroundColor: Colors.blue,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              actions: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    onColumnNameSubmit();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 12),
                                                    child: Text('Dodaj'),
                                                  ),
                                                )
                                              ],
                                              content: TextField(
                                                controller:
                                                    columnNameController,
                                                focusNode:
                                                    columnNameEditorFocusNode,
                                                onSubmitted: (value) {
                                                  onColumnNameSubmit();
                                                  columnNameEditorFocusNode
                                                      .requestFocus();
                                                  SchedulerBinding.instance
                                                      ?.addPostFrameCallback(
                                                          (timeStamp) {
                                                    setState(() {
                                                      inputTableHorizontalScrollConstroller
                                                          .animateTo(
                                                        inputTableHorizontalScrollConstroller
                                                            .position
                                                            .maxScrollExtent,
                                                        duration: Duration(
                                                            milliseconds: 250),
                                                        curve: Curves.ease,
                                                      );
                                                    });
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                    hintText: 'Nazwa kolumny'),
                                              ),
                                              title: Text('Dodaj kolumnę'),
                                            );
                                          },
                                        );

                                        columnNameEditorFocusNode.unfocus();
                                        columnNameEditorFocusNode
                                            .requestFocus();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (dataFrame.getHeaders().isNotEmpty) ...{
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: IconButtonWithTooltip(
                                      icon: Icons.playlist_add,
                                      tooltipText: 'Dodaj wiersz',
                                      iconColor: Colors.white,
                                      backgroundColor: Colors.blue,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Dodaj wiersz'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text('Anuluj'),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    int headersCount = dataFrame
                                                        .getHeaders()
                                                        .length;
                                                    List<String?> newRow = [];
                                                    for (int i = 0;
                                                        i < headersCount;
                                                        i++) {
                                                      String fieldText =
                                                          addRowFormControllers[
                                                                  i]
                                                              .text;
                                                      if (fieldText.isEmpty) {
                                                        newRow.add(null);
                                                      } else {
                                                        newRow.add(fieldText);
                                                      }
                                                    }
                                                    setState(() {
                                                      inputTableCheckedItems
                                                          .add(false);
                                                      dataFrame.addRow(newRow);
                                                      addRowFormControllers
                                                          .forEach((element) {
                                                        element.clear();
                                                      });
                                                    });
                                                    addRowFormControllers
                                                        .forEach((element) {
                                                      element.clear();
                                                    });
                                                    SchedulerBinding.instance
                                                        ?.addPostFrameCallback(
                                                            (timeStamp) {
                                                      inputTableVerticalScrollConstroller
                                                          .animateTo(
                                                              inputTableVerticalScrollConstroller
                                                                  .position
                                                                  .maxScrollExtent,
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      250),
                                                              curve:
                                                                  Curves.ease);
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text('Dodaj'),
                                                  ),
                                                ),
                                              ],
                                              content: SingleChildScrollView(
                                                scrollDirection: Axis.vertical,
                                                child: Column(
                                                  children: [
                                                    ...dataFrame
                                                        .getHeaders()
                                                        .asMap()
                                                        .entries
                                                        .map(
                                                          (e) => TextField(
                                                            controller:
                                                                addRowFormControllers[
                                                                    e.key],
                                                            decoration:
                                                                InputDecoration(
                                                                    hintText:
                                                                        '${e.value}'),
                                                          ),
                                                        ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, right: 8, bottom: 8),
                                    child: IconButtonWithTooltip(
                                      icon: Icons.delete,
                                      tooltipText: 'Usuń zaznaczone',
                                      iconColor: Colors.white,
                                      backgroundColor: Colors.red,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Czy na pewno?'),
                                              content: Text(
                                                  'Spowoduje to usunięcie zaznaczonych wierszy'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Text('Anuluj'),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          primary: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      for (var i =
                                                              inputTableCheckedItems
                                                                      .length -
                                                                  1;
                                                          i >= 0;
                                                          i--) {
                                                        if (inputTableCheckedItems[
                                                                i] ==
                                                            true) {
                                                          print('rem $i');
                                                          dataFrame
                                                              .removeRow(i);
                                                        }
                                                      }
                                                      inputTableCheckedItems
                                                          .removeWhere(
                                                              (element) =>
                                                                  element ==
                                                                  true);
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Text('Ok'),
                                                  ),
                                                )
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            }
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 250),
            curve: Curves.ease,
            top: 70,
            bottom: 0,
            right: showStats ? 0 : -350,
            child: Container(
              width: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 2,
                    color: Colors.black.withAlpha(50),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'Statystyki drzewa',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (showSpeedSelector) ...{
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 70),
                child: TopToolDock(
                  roundTop: true,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 38),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Container(
                          width: 420,
                          child: Row(
                            children: [
                              Text(
                                sliderValue.toStringAsFixed(2) + 's',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Flexible(
                                flex: 1,
                                child: Slider(
                                  value: sliderValue,
                                  label: sliderValue.toStringAsFixed(2) + 's',
                                  divisions: 10,
                                  onChanged: (value) {
                                    setState(() {
                                      sliderValue = value;
                                    });
                                  },
                                  min: 0,
                                  max: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          },
          Align(
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TopToolDock(
                  children: [
                    Tooltip(
                      message: 'Wybierz węzeł',
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedToolNumber = 1;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: selectedToolNumber == 1
                              ? Colors.orange
                              : Colors.white,
                          minimumSize: Size(50, 50),
                        ),
                        child: Image.asset(
                          'images/cursor-default.png',
                          width: 22,
                          color: selectedToolNumber == 1
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButtonWithTooltip(
                      icon: Icons.open_with_rounded,
                      tooltipText: 'Przesuń widok',
                      iconColor:
                          selectedToolNumber == 2 ? Colors.white : Colors.black,
                      backgroundColor: selectedToolNumber == 2
                          ? Colors.orange
                          : Colors.white,
                      onPressed: () {
                        setState(() {
                          selectedToolNumber = 2;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(width: 12),
                TopToolDock(
                  children: [
                    IconButtonWithTooltip(
                      icon: Icons.assignment,
                      tooltipText: 'Dane wejściowe',
                      iconColor: showDataInput ? Colors.white : Colors.black,
                      backgroundColor:
                          showDataInput ? Colors.blue : Colors.white,
                      onPressed: () {
                        setState(() {
                          showDataInput = !showDataInput;
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    IconButtonWithTooltip(
                      icon: Icons.analytics,
                      tooltipText: 'Statystyki drzewa',
                      iconColor: showStats ? Colors.white : Colors.black,
                      backgroundColor: showStats ? Colors.blue : Colors.white,
                      onPressed: () {
                        setState(() {
                          showStats = !showStats;
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    IconButtonWithTooltip(
                      icon: Icons.settings,
                      tooltipText: 'Ustawienia aplikacji',
                      iconColor: showSettings ? Colors.white : Colors.black,
                      backgroundColor:
                          showSettings ? Colors.blue : Colors.white,
                      onPressed: () {
                        setState(() {
                          showSettings = !showSettings;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(width: 12),
                TopToolDock(
                  children: [
                    IconButtonWithTooltip(
                      icon:
                          run ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      tooltipText:
                          run ? 'Zatrzymaj budowę' : 'Zacznij / wznów budowę',
                      iconColor: Colors.white,
                      backgroundColor: run ? Colors.red : Colors.green,
                      onPressed: () {
                        setState(() {
                          run = !run;
                          onSimulationButtonTap(run);
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    IconButtonWithTooltip(
                      icon: Icons.speed,
                      tooltipText: 'Szybkość budowy',
                      iconColor:
                          showSpeedSelector ? Colors.white : Colors.black,
                      backgroundColor:
                          showSpeedSelector ? Colors.blue : Colors.white,
                      onPressed: () {
                        setState(() {
                          showSpeedSelector = !showSpeedSelector;
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    IconButtonWithTooltip(
                      icon: Icons.replay_rounded,
                      tooltipText: 'Wyczyść budowę drzewa',
                      iconColor: resetWaiting ? Colors.white : Colors.black,
                      backgroundColor:
                          resetWaiting ? Colors.blue : Colors.white,
                      onPressed: () {
                        setState(() {
                          treeNodes.clear();
                          root = null;
                          resetWaiting = false;
                          selectedTreeNode.value = null;
                        });
                      },
                    ),
                    // ConstrainedBox(
                    //   constraints: BoxConstraints(maxWidth: 250, maxHeight: 40),
                    //   child: Slider(
                    //     value: 0.5,
                    //     onChanged: (value) {},
                    //     min: 0,
                    //     max: 2,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('offset: ${pos.value}')],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TreeView extends StatefulWidget {
  const TreeView({
    Key? key,
    required this.treeNodes,
    required this.pos,
    required this.selectedTreeNode,
  }) : super(key: key);

  final List<TreeNode> treeNodes;
  final SimpleValue<Offset> pos;
  final SimpleValue<TreeNode>? selectedTreeNode;

  @override
  _TreeViewState createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: TreePainter(
          tree: widget.treeNodes,
          pos: widget.pos.value ?? Offset.zero,
          selectedNodeId: widget.selectedTreeNode?.value?.id ?? -1),
    );
  }
}

class RegisteredTextField extends StatefulWidget {
  @override
  RegisteredTextFieldState createState() => RegisteredTextFieldState();
}

class RegisteredTextFieldState extends State<RegisteredTextField> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TopToolDock extends StatelessWidget {
  final List<Widget> children;
  final bool roundTop;

  const TopToolDock({Key? key, required this.children, this.roundTop = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            color: Colors.black.withAlpha(50),
            offset: Offset(0, 1),
          )
        ],
        borderRadius: BorderRadius.only(
          topLeft: roundTop ? Radius.circular(8) : Radius.circular(0),
          topRight: roundTop ? Radius.circular(8) : Radius.circular(0),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class IconButtonWithTooltip extends StatelessWidget {
  final String tooltipText;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final Function()? onPressed;

  const IconButtonWithTooltip({
    Key? key,
    required this.icon,
    this.tooltipText = '',
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var coreWidget = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: backgroundColor,
        minimumSize: Size(50, 50),
      ),
      child: Icon(
        icon,
        color: iconColor,
      ),
    );

    if (tooltipText.isNotEmpty) {
      return Tooltip(
        message: tooltipText,
        child: coreWidget,
      );
    }

    return coreWidget;
  }
}
