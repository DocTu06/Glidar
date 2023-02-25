import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_obj/flutter_3d_obj.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
void main() => runApp(MaterialApp(
  home: home(),
));

class home extends StatefulWidget {
  const home() : super();

  @override
  _homeState createState() => _homeState();
}

class _homeState extends State<home> {
  String stringResponse = 'test';
  List<String> stringlist = ['0','0','0','0','0','0','0','0','0','0'];
  List <double> valuelist = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
  var temp,prs,ax,ay,az,gx,gy,gz,dist,speed,yaw,pitch,roll,aanglex,aangley,ganglex,gangley,ganglez,aoleu;
  static AudioCache player = new AudioCache();
  AudioPlayer audioPlayer = AudioPlayer();
  Future fetchData() async {
    http.Response response;
    response = await http.get(Uri.parse('http://192.168.4.1/data'));
    if (response.statusCode == 200) {
      setState(() {
        stringResponse = response.body;
        stringlist = stringResponse.split(',');
        valuelist = stringlist.map(double.parse).toList();
        temp = valuelist[0];//*C
        prs = valuelist[1]*0.0075006156130264; //convert from pascals to mmHg
        ax = valuelist[2];//mm/s^2
        ay = valuelist[3];//mm/s^2
        az = valuelist[4];//mm/s^2
        gx = valuelist[5];//rad/s
        gy = valuelist[6];//rad/s
        gz = valuelist[7];//rad/s
        if(valuelist[8] < 60000)
          {
            dist = valuelist[8];//cm
          }
        if(dist < 150)
          {
            player.play("beep.mp3");
          }
        speed = sqrt(((ax*ax)+(az*az)));
        speed = (speed*speed)/2;
        aanglex = (atan(ay / sqrt(ax*ax + az*az)) * 180 / pi);
        aangley = (atan(-1 * ax / sqrt(ay*ay + az*az)) * 180 / pi);
        ganglex = ganglex + gx*120;
        gangley = gangley + gy*120;
        ganglez = ganglez + gz*120;
        roll = 0.96*ganglex + 0.04*aanglex;
        pitch = 0.96*gangley + 0.04*aangley;
        yaw = ganglez;

      });
    }
    else
      {
        aoleu = 1;
      }
  }
  Timer timer;
  Timer timer1;
  @override
  void initState() {
    super.initState();
    timer =
        Timer.periodic(Duration(milliseconds: 120), (Timer t) => fetchData());
  }
  @override
  void dispose() {
    timer?.cancel();
    timer1?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Glidar',
      home: new Scaffold(
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
                  angleX: roll * -1,
                  angleY: yaw,
                  angleZ: pitch * -1,
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
                          value: temp,
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
      ),
    );
  }
}