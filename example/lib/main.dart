import 'package:flutter/material.dart';
import 'package:animated_box_decoration/animated_box_decoration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool toggleStyle = true;

  Decoration _colorDeco1 = BoxDecoration(color: Colors.blue);
  Decoration _colorDeco2 = BoxDecoration(color: Colors.red);

  Decoration _linearGradientDeco1 = BoxDecoration(
      gradient: LinearGradient(colors: [
    Colors.black87,
    Color(0xFF04619f),
    Color(0xFF358f74),
    Color(0xFF923cb5),
    Colors.black87,
  ], stops: [
    0.1,
    0.3,
    0.45,
    0.8,
    0.98
  ]));
  Decoration _linearGradientDeco2 = BoxDecoration(
      gradient: LinearGradient(colors: [
    Color(0xFFF6EA41),
    Color(0xFFEEBD89),
    Color(0xFFD13ABD),
    Color(0xFFAEBAF8),
  ]));
  Decoration _sweepGradientDeco1 = BoxDecoration(
      gradient: SweepGradient(
          center: Alignment(0.13, 0.1),
          startAngle: 0.5,
          endAngle: 6.3,
          colors: [
        Color(0xFFF6EA41),
        Color(0xFFEEBD89),
        Color(0xFFD13ABD),
        Color(0xFFB60F46),
        Color(0xFFF6EA41),
      ],
          stops: [
        0.01,
        0.2,
        0.7,
        0.8,
        0.98
      ]));

  Decoration _sweepGradientDeco2 = BoxDecoration(
      gradient: SweepGradient(
          center: Alignment(0.03, -0.17),
          startAngle: 0.1,
          endAngle: 5.3,
          colors: [
        Colors.black87,
        Color(0xFF04619f),
        Color(0xFF358f74),
        Color(0xFF923cb5),
        Colors.black87,
      ],
          stops: [
        0.1,
        0.3,
        0.45,
        0.8,
        0.98
      ]));

  Decoration _imageDeco1 = BoxDecoration(
      image: DecorationImage(
          opacity: 0.5,
          fit: BoxFit.fill,
          image: NetworkImage(
              "https://images.unsplash.com/photo-1647504370987-85729e29ab93?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1374&q=80")));

  Decoration _imageDeco2 = BoxDecoration(
      image: DecorationImage(
          fit: BoxFit.fill,
          image: NetworkImage(
              "https://images.unsplash.com/photo-1640622841908-3a691b7b7ac9?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1776&q=80")));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: DefaultTextStyle(
          style: TextStyle(fontSize: 20, height: 2),
          textAlign: TextAlign.center,
          child: ListView(
            children: <Widget>[
              Text("Left: AnimatedContainer, right: SmoothAnimatedContainer"),
              Text("Animate between two colors"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration: toggleStyle ? _colorDeco1 : _colorDeco2,
                  ),
                  SmoothAnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration: toggleStyle ? _colorDeco1 : _colorDeco2,
                  )
                ],
              ),
              Text("Animate between a color and a linear gradient"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration:
                        toggleStyle ? _colorDeco1 : _linearGradientDeco1,
                  ),
                  SmoothAnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration:
                        toggleStyle ? _colorDeco1 : _linearGradientDeco1,
                  )
                ],
              ),
              Text("Animate between two linear gradient"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration: toggleStyle
                        ? _linearGradientDeco1
                        : _linearGradientDeco2,
                  ),
                  SmoothAnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration: toggleStyle
                        ? _linearGradientDeco1
                        : _linearGradientDeco2,
                  )
                ],
              ),
              Text("Animate between a linear gradient and a sweep gradient"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration: toggleStyle
                        ? _linearGradientDeco1
                        : _sweepGradientDeco1,
                  ),
                  SmoothAnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration: toggleStyle
                        ? _linearGradientDeco1
                        : _sweepGradientDeco1,
                  )
                ],
              ),
              Text("Animate between a linear gradient and a image"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration:
                        toggleStyle ? _linearGradientDeco1 : _imageDeco1,
                  ),
                  SmoothAnimatedContainer(
                    width: 200,
                    height: 200,
                    duration: Duration(seconds: 1),
                    decoration:
                        toggleStyle ? _linearGradientDeco1 : _imageDeco1,
                  )
                ],
              ),
              Text("Animate between two image"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedContainer(
                    width: 400,
                    height: 400,
                    duration: Duration(seconds: 5),
                    decoration: toggleStyle ? _imageDeco1 : _imageDeco2,
                  ),
                  SmoothAnimatedContainer(
                    width: 400,
                    height: 400,
                    duration: Duration(seconds: 5),
                    decoration: toggleStyle ? _imageDeco1 : _imageDeco2,
                  )
                ],
              ),
              SizedBox(
                height: 200,
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            toggleStyle = !toggleStyle;
          });
        },
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
