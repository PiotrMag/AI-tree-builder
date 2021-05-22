import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:tree_builder/classes/dataframe.dart';

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

class _EditorPageState extends State<EditorPage> {
  DataFrame dataFrame = DataFrame();

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

  double sliderValue = 1.0;

  Offset pos = Offset.zero;

  @override
  void dispose() {
    columnNameEditorFocusNode.dispose();
    addRowFormControllers.forEach((element) {
      element.dispose();
    });
    columnNameController.dispose();
    inputTableHorizontalScrollConstroller.dispose();
    inputTableVerticalScrollConstroller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(),
          ),
          MouseRegion(
            cursor: selectedToolNumber == 2
                ? SystemMouseCursors.move
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onPanUpdate: (details) {
                if (selectedToolNumber == 2) {
                  setState(() {
                    pos += details.delta;
                  });
                }
              },
              onDoubleTap: () {
                if (selectedToolNumber == 2) {
                  setState(() {
                    pos = Offset.zero;
                  });
                }
              },
            ),
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
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (dataFrame.getHeaders().isNotEmpty) ...{
                                Flexible(
                                  flex: 1,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(top: 8, left: 8),
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
                                            inputTableVerticalScrollConstroller,
                                        isAlwaysShown: true,
                                        thickness: 10,
                                        child: SingleChildScrollView(
                                          controller:
                                              inputTableVerticalScrollConstroller,
                                          scrollDirection: Axis.vertical,
                                          child: Scrollbar(
                                            controller:
                                                inputTableHorizontalScrollConstroller,
                                            isAlwaysShown: true,
                                            thickness: 10,
                                            child: SingleChildScrollView(
                                              controller:
                                                  inputTableHorizontalScrollConstroller,
                                              scrollDirection: Axis.horizontal,
                                              child: DataTable(
                                                columnSpacing: 12,
                                                headingRowHeight: 48,
                                                columns: [
                                                  ...dataFrame
                                                      .getHeaders()
                                                      .asMap()
                                                      .entries
                                                      .map(
                                                        (entry) => DataColumn(
                                                          label: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 8),
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  entry.value,
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700),
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
                                                                          title:
                                                                              Text('Usuń kolumnę'),
                                                                          content:
                                                                              RichText(
                                                                            text:
                                                                                TextSpan(
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
                                                                  icon: Icon(Icons
                                                                      .remove),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                ],
                                                rows: [
                                                  ...dataFrame.getRows().map(
                                                        (e) => DataRow(
                                                          cells: [
                                                            ...e.map(
                                                              (h) => DataCell(
                                                                Text(
                                                                  h ?? 'null',
                                                                  style: TextStyle(
                                                                      color: h ==
                                                                              null
                                                                          ? Colors.grey[
                                                                              400]
                                                                          : Colors
                                                                              .black),
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
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 12),
                                                child: Text('Dodaj'),
                                              ),
                                            )
                                          ],
                                          content: TextField(
                                            controller: columnNameController,
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
                                    columnNameEditorFocusNode.requestFocus();
                                  },
                                ),
                              ),
                            ],
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
                                                      const EdgeInsets.all(8.0),
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
                                                        addRowFormControllers[i]
                                                            .text;
                                                    if (fieldText.isEmpty) {
                                                      newRow.add(null);
                                                    } else {
                                                      newRow.add(fieldText);
                                                    }
                                                  }
                                                  setState(() {
                                                    dataFrame.addRow(newRow);
                                                    addRowFormControllers
                                                        .forEach((element) {
                                                      element.clear();
                                                    });
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
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
                                                style: ElevatedButton.styleFrom(
                                                    primary: Colors.red),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  //todo: usunięcie zaznaczonych wierszy
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
                      onPressed: () {},
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
                  children: [Text('offset: $pos')],
                ),
              ),
            ),
          ),
        ],
      ),
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
