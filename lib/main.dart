import 'package:flutter/material.dart';
import 'package:flutter_3d_obj/flutter_3d_obj.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_thermometer/label.dart';
import 'package:flutter_thermometer/scale.dart';
import 'package:flutter_thermometer/setpoint.dart';
import 'package:flutter_thermometer/thermometer.dart';
import 'package:flutter_thermometer/thermometer_paint.dart';
import 'package:flutter_thermometer/thermometer_widget.dart';
void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter 3D Demo',
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text("Flutter 3D"),
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
                ),
              ),
            ),
            Container(
              child: Row(
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                          child: SfRadialGauge()
                      ),
                  SizedBox(
                    width: 180,
                    height: 180,
                      child: SfRadialGauge()
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}