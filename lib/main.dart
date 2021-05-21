import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  bool showStats = false;
  bool showSettings = false;
  bool showDetails = false;
  bool showSpeedSelector = false;

  bool run = false;

  int selectedToolNumber = 1;

  double sliderValue = 1.0;

  Offset pos = Offset.zero;

  @override
  Widget build(BuildContext context) {
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
              // onPanUpdate: (details) {
              //   setState(() {
              //     pos += details.delta;
              //   });
              // },
              // child: CustomPaint(),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 250),
            curve: Curves.ease,
            top: 0,
            bottom: 0,
            left: showDetails ? 0 : -350,
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
                      'Szczegóły węzła',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 250),
            curve: Curves.ease,
            top: 0,
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
                      tooltipText: 'Szczegóły o węźle',
                      iconColor: showDetails ? Colors.white : Colors.black,
                      backgroundColor: showDetails ? Colors.blue : Colors.white,
                      onPressed: () {
                        setState(() {
                          showDetails = !showDetails;
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
