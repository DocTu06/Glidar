import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_3d_obj/flutter_3d_obj.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key, required this.title});

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
  int _counter = 0;
  static AudioCache player = new AudioCache();
  AudioPlayer audioPlayer = AudioPlayer();
  late var data;
  var ddata;
  var slist = ["0","0","0","0","0","0"];
  var flist = [0.0,0.0,0.0,0.0,0.0,0.0];
  var temp,prs,ax,ay,az,dist,aanglex,aangley,speed;
  _write(String text) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/date.txt');
    await file.writeAsString(text);
  }
  void connect_bluetooth() async {
    // Some simplest connection :F

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress("24:D7:EB:11:C6:9E");
      print('Connected to the device');
      connection.input!.listen((Uint8List data) {
        setState(() {
          ddata = ascii.decode(data);
          slist = ddata.split(",");
          if(slist != null)
            {
              flist = slist.map(double.parse).toList();
              temp = flist[0];
              prs = flist[1];
              ax = flist[2];
              ay = flist[3];
              az = flist[4];
              if(flist[5] < 60000)
              {

                dist = flist[5];
                if(dist < 200)
                {
                  player.play("beep.mp3");
                }
              }
              speed = sqrt(((ax*ax)+(az*az)));
              speed = (speed*speed)/2;
              aanglex = (atan(ay / sqrt(ax*ax + az*az)) * 180 / pi);
              aangley = (atan(-1 * ax / sqrt(ay*ay + az*az)) * 180 / pi);
            }
          print(flist);
          _write(ddata);
          connection.output.add(data); // Sending data

          if (ascii.decode(data).contains('!')) {
            connection.finish(); // Closing connection
            print('Disconnecting by local host');
          }
        });

      }).onDone(() {
        print('Disconnected by remote request');
      });
    } catch (exception) {
      print('Cannot connect, exception occured');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    connect_bluetooth();
    return Scaffold(
      appBar: new AppBar(
        title: Center(child: const Text("Glidar")),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: new Center(
              child: new Object3D(
                size: const Size(290.0, 290.0),
                path: "assets/file.obj",
                asset: true,
                angleX: -1.0 * aanglex,
                angleY: 0,
                angleZ: -1.0 * aangley,
              ),
            ),
          ),
          Container(
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 180,
                  child: SfLinearGauge(
                    minimum: -10, maximum: 50,
                    orientation: LinearGaugeOrientation.vertical,
                    ranges: [
                      LinearGaugeRange(
                        startValue: -10,
                        endValue: 50,
                      ),
                    ],
                    markerPointers: [
                      LinearShapePointer(
                        value: temp-7,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                          minimum: 100, maximum: 1000,
                          pointers: <GaugePointer>[
                            RangePointer(value: prs,)],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(widget: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(child:
                              Text('  ${prs.toStringAsFixed(1)} \n mmHg',style: TextStyle(fontSize: 20,))),
                            ),
                            )]
                      ),
                    ],

                  ),
                ),
              ],
            ),
          ),
          Text("       Temperature(°C)                         Pressure"),
          Padding(
            padding: const EdgeInsets.fromLTRB(35.0,23,35,0),
            child: SfLinearGauge(
              minimum: 0, maximum: 140,
              markerPointers: [
                LinearShapePointer(
                  value: speed,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center, // Align however you like (i.e .centerRight, centerLeft)
            child: Text("Speed(m/s)"),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(35.0,23,35,0),
            child: SfLinearGauge(
              minimum: 0, maximum: 9,
              markerPointers: [
                LinearShapePointer(
                  value: dist/100,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center, // Align however you like (i.e .centerRight, centerLeft)
            child: Text("Distance(m)"),
          ),
        ],
      ),
    );
  }
}
