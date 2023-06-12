import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:io' as io;
import 'package:geolocator/geolocator.dart';
import 'package:csv/csv.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

bool  trip = false;
int i = 0;
int j = 0;
List filelist = [];
String currentfile = "test";
String test = "t";
double speedMps = 0.0;
var csvdata = [];
List<double> prslist = [];
List<double> latlist = [];
List<double> longlist = [];
List<double> speedlist = [];
List<LatLng> polylinelist  = [];
var centerlat = 51.509364;
var centerlong = -0.128928;
void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

  var temp = 15.0,
      prs = 90000.0,
      ax = 0.0,
      ay = 0.0,
      az = 0.0,
      dist = 0.0,
      speed = 0.0,
      aanglex = 0.0,
      aangley = 0.0,
      aanglez = 0.0,
      yaw = 0.0,
      pitch = 0.0,
      roll = 0.0,
      upacc = 0.0,
      ascendrate = 0.0,
      dir = 0.0,
      sealevelaltitude = 0.0;
  var minlat = 0.0;
  var minlong = 0.0;
  var maxlat = 0.0;
  var maxlong = 0.0;
  var arrowpath = "assets/arrow_neutral.png";
  List<String> temporarystringlist = [];
  var temporaryvaluelist = [];
  String text = "tudor";
  String buttontext = "Begin trip";
  String date = "0.00,0.00,0.00,0.00,0.00,0.00";
  String stringResponse = '0.00,0.00,0.00,0.00,0.00,0.00';
  List<String> stringlist = ['0', '0', '0', '0', '0', '0'];
  List<double> valuelist = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  Future<void> proccesdata(String path) async
  {
    temporarystringlist = [];
    temporaryvaluelist = [];
    prslist = [];
    speedlist = [];
    latlist = [];
    longlist = [];
    polylinelist = [];
    File file = File(path);
    setState(() {
      csvdata = (file.readAsLinesSync());
    });
    csvdata.forEach((dataset) {
      temporarystringlist = dataset.split(',');
      temporaryvaluelist = temporarystringlist.map(double.parse).toList();
      prslist.add(temporaryvaluelist[1]*0.0075) ;
      speedlist.add((sqrt(((temporaryvaluelist[2] * temporaryvaluelist[2]) + (temporaryvaluelist[3] * temporaryvaluelist[3])))*sqrt(((temporaryvaluelist[2] * temporaryvaluelist[2]) + (temporaryvaluelist[3] * temporaryvaluelist[3]))))/2);
      latlist.add(temporaryvaluelist[6]);
      longlist.add(temporaryvaluelist[7]);
    });
    minlat = latlist.reduce(min);
    maxlat = latlist.reduce(max);
    minlong = longlist.reduce(min);
    maxlong = longlist.reduce(max);
    centerlat = (minlat + maxlat)/2;
    centerlong = (maxlong + minlong)/2;
    for(int i = 0;i<latlist.length;i++)
      {
        polylinelist.add(LatLng(latlist[i], longlist[i]));
      }
    print(polylinelist);
  }
  Future<void> handlepermisions() async
  {
    await Permission.nearbyWifiDevices.request();
    await Permission.audio.request();
    await Permission.storage.request();
    await Permission.location.request();
  }
  Future fetchData() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    if(trip == true) {
        http.Response response;
        response = await http.get(Uri.parse('http://192.168.4.1/data'));
        if (response.statusCode == 200) {
          setState(() {
            stringResponse = response.body;
            stringlist = stringResponse.split(',');
            valuelist = stringlist.map(double.parse).toList();
          });
          temp = valuelist[0];
          prs = valuelist[1];
          ax = valuelist[2];
          ay = valuelist[3];
          az = valuelist[4];
          dist = valuelist[5];
          if(az+9.81 < -0.5)
            {
              arrowpath = "assets/arrow_down.png";
            }
          else if(az+9.81 > 0.5)
            {
              arrowpath = "assets/arrow_up.png";
            }
          else
            {
              arrowpath = "assets/arrow_neutral.png";
            }
          ascendrate = ((az+9.81)*(az+9.81))/2;
          sealevelaltitude = ((pow((1013.25/(prs/100)), (1/5.257))-1)*((temp-10)+273.15))/0.0065 as double;
          if(dist > 150)
            {
              playbeep((sealevelaltitude/290)/2);
            }
          if(dist < 150)
            {
              playbeep(1.00);
            }
          speed = sqrt(((ax * ax) + (ay * ay)));
          speed = (speed * speed) / 2;
          aanglex = (atan(ay / sqrt(ax * ax + az * az)) * 180 / pi);
          aangley = (atan(-1 * ax / sqrt(ay * ay + az * az)) * 180 / pi);
          await createFile();
        }
      }
    if(trip == false)
      {

        _listofFiles();
      }
  }
  Future<void> addtrip() async
  {
    handlepermisions();
    final Directory directory = await getApplicationDocumentsDirectory();
    final path = Directory("${directory.path}/trip");
    if (!(await path.exists())){
      path.create();
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if(result != null)
      {

        PlatformFile selectedfile = result.files.first;
        String? filepath = selectedfile.path;
        if(filepath?.substring(filepath.length-4,filepath.length) == '.csv')
          {
            File addedfile = File(filepath!);
            addedfile.copy("${directory.path}/trip/${selectedfile.name}");
          };
      }
  }
  Future<void> createFile() async {
    if(i == 0)
      {
        date = DateTime.now().toString().substring(0,16);
        i++;
      }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position.toString().substring(10,20));
    print(position.toString().substring(33,43));
    final Directory directory = await getApplicationDocumentsDirectory();
    final path = Directory("${directory.path}/trip");
    if (!(await path.exists())){
      path.create();
    }
    final File file = File('${directory.path}/trip/trip_$date.csv');
    await file.writeAsString('${(stringResponse).toString()},${position.toString().substring(10,20)},${position.toString().substring(33,43)}\n',mode: FileMode.append);
    print('File created at: ${file.path}');
  }
  void _listofFiles() async {
    String dir;
    dir = (await getApplicationDocumentsDirectory()).path;
    setState(() {
      filelist = io.Directory("$dir/trip").listSync();
    });
  }
  Future<void> deletefile(String path) async{
    final f = await File(path);
    f.deleteSync();
  }
  Future<void> playbeep(double volume)
  async {
    final player = AudioPlayer();
    await player.setVolume(volume);
    player.play(AssetSource("beep10.mp3"));
  }
  late Timer timer;
  late Timer timer1;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(milliseconds: 120), (Timer t) => fetchData());
  }
  @override
  void dispose() {
    timer.cancel();
    timer1.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: DefaultTabController(
      length: 3,
      child: Scaffold(

        appBar: AppBar(
          backgroundColor: Colors.lightBlueAccent,
          title: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.phone_android_rounded)),
              Tab(icon: Icon(Icons.table_chart)),
              Tab(icon: Icon(Icons.show_chart)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, ((6*MediaQuery.of(context).padding.top)/2.5), 0, 0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 6,
                        height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 1.3,
                        child: SfLinearGauge(
                          minimum: 100,
                          maximum: 2000,
                          orientation: LinearGaugeOrientation.vertical,
                          barPointers: [
                            LinearBarPointer(value: 200)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: (2 * MediaQuery.of(context).size.width) / 2.5,
                      height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 2.5,
                      child: SfRadialGauge(
                        axes: <RadialAxis>[
                          RadialAxis(
                              minimum: 1,
                              maximum: 300,
                              pointers: <GaugePointer>[
                                RangePointer(
                                  value: ascendrate,
                                )
                              ],
                              annotations: <GaugeAnnotation>[
                                GaugeAnnotation(
                                  widget: Center(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(0, ((6*MediaQuery.of(context).padding.top)/1.8), 0, 0),
                                      child: Column(
                                        children: [
                                          Image.asset(
                                              height: 100,
                                              width: 100,
                                              "$arrowpath"
                                          ),
                                          Text(
                                              "${ascendrate.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: 30
                                            ),
                                          ),

                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width/2,
                      height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 3,
                      child: Transform.rotate(
                        angle: (360-((aanglex+180)*0.01745329252)).abs()+180,
                        child: Image.asset(
                            "assets/glider_top.png",
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width/2,
                      height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 3,
                      child: Transform.rotate(
                        angle: (((aangley+180)*0.01745329252)).abs(),
                        child: Image.asset(
                          "assets/glider_front.png",
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3,
                          height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 3,
                          child: SfLinearGauge(
                            minimum: -10,
                            maximum: 40,
                            orientation: LinearGaugeOrientation.vertical,
                            ranges: [
                              LinearGaugeRange(
                                startValue: -10,
                                endValue: 40,
                              ),
                            ],
                            markerPointers: [
                              LinearShapePointer(
                                value: temp-10,
                              ),
                            ],
                          ),
                        ),
                        Text("Temperature(°C)"),
                      ],
                    ),
                    Column(
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: (2 * MediaQuery.of(context).size.width) / 3,
                              height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 3,
                              child: SfRadialGauge(
                                axes: <RadialAxis>[
                                  RadialAxis(
                                      minimum: 100,
                                      maximum: 1000,
                                      pointers: <GaugePointer>[
                                        RangePointer(
                                          value: prs*0.0075,
                                        )
                                      ],
                                      annotations: <GaugeAnnotation>[
                                        GaugeAnnotation(
                                          widget: Container(
                                              child: Text(
                                                  '${(prs*0.0075).toStringAsFixed(2)} \nmmHg',
                                                  style: TextStyle(
                                                    fontSize: MediaQuery.of(context).size.width * 0.069,
                                                  ))),
                                        )
                                      ]),
                                ],
                              ),
                            ),
                            Center(child: Text(
                                "Altitude(sea level):",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.049,
                                ),
                            )),
                            Center(child: Text(
                                "${sealevelaltitude.toStringAsFixed(2)} m",
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.049,
                              ),
                            )),

                          ],
                        ),
                      ],
                    ),

                  ],
                ),
                SizedBox(
                  width: (2 * MediaQuery.of(context).size.width),
                  height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) /5.6,
                  child: Column(
                    children: [
                      SfLinearGauge(
                        minimum: 0,
                        maximum: 140,
                        markerPointers: [
                          LinearShapePointer(
                            value: speed,
                          ),
                        ],
                      ),
                      Text(
                          "Speed(m/s)",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.040,
                        ),
                      ),
                      SfLinearGauge(
                        minimum: 0,
                        maximum: 9,
                        markerPointers: [
                          LinearShapePointer(
                            value: dist / 100.00,
                          ),
                        ],
                      ),
                      Text("Distance from ground(m)"),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, ((6*MediaQuery.of(context).padding.top)/24), 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width/2.1,
                          height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 8.6,
                          child: ElevatedButton(
                              child: Text(
                                  'Start trip',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width * 0.069
                                      ),
                              ),
                              onPressed: (){
                                handlepermisions();
                                setState(() {
                                  i = 0;
                                  trip = true;
                                });
                              },
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width/2.1,
                          height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) / 8.6,
                          child: ElevatedButton(
                            child: Text(
                              'Stop trip',
                              style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.069
                              ),
                            ),
                            onPressed: (){
                              setState(() {
                                trip = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  "Trips:",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: MediaQuery.of(context).size.width * 0.069
                  )
                ),
                Expanded(
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(0, ((MediaQuery.of(context).padding.top) * 0.25), 0, 0),
                    child: ListView.separated(
                      itemCount: filelist.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height/8,
                            width:MediaQuery.of(context).size.width/1.5,
                            child: ElevatedButton(
                              onPressed: () {
                                currentfile = filelist[index].toString();
                                proccesdata(currentfile.substring(7,84));
                                Navigator.of(context).push(_createRoute());
                              },
                              onLongPress: (){
                                showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) => AlertDialog(
                                    title: const Text("Delete trip"),
                                      content: const Text("Do you want to delte this trip file?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, 'Cancel'),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: ()
                                        {
                                          currentfile = filelist[index].toString();
                                          deletefile(currentfile.substring(7,84));
                                          setState(() {
                                          filelist.removeAt(index);
                                          });
                                          Navigator.pop(context, 'OK');
                                        },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                );
                              },
                              child: Text(
                                  "${filelist[index].toString().substring(72,74)}/${filelist[index].toString().substring(69,71)}/${filelist[index].toString().substring(64,68)}\n${filelist[index].toString().substring(74,80)}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }, separatorBuilder: (BuildContext context, int index) => const Divider(),
                    ),
                  ),
                ),
                ElevatedButton(
                    onPressed: (){
                      addtrip();
                    },
                    child: Text("Add trip"),
                ),
              ],
            )
          ],
        ),
      ),
    ));
  }
}
Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>  Page2(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
class Page2 extends StatefulWidget {
  const Page2({Key? key}) : super(key: key);

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> {
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      actions: <Widget>[
          IconButton(
              onPressed: (){
                Share.shareXFiles([XFile(currentfile.substring(7,84))]);
              },
              icon: Icon(Icons.share),
          ),
        ],
      ),
      body:  Center(
        child: Column(
          children: [
        Padding(
          padding: EdgeInsets.fromLTRB(0, ((6*MediaQuery.of(context).padding.top)/24), 0, 0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: Colors.black38
              ),
            ),
            width: MediaQuery.of(context).size.width*0.72,
            height: MediaQuery.of(context).size.width*0.72,
            child: FlutterMap(
            options: MapOptions(
            center: LatLng(centerlat,centerlong),
      ),
      children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinelist,
                  strokeWidth: 4,
                  color: Colors.blue,
              ),
          ],
        ),
      ],
    ),
          ),
        ),
             Padding(
                padding: EdgeInsets.fromLTRB(0, ((MediaQuery.of(context).padding.top)), 0, 0),
                child: Container(

                    width: MediaQuery.of(context).size.width/1.1,
                    height: MediaQuery.of(context).size.height/5,
                    child: Sparkline(
                      data: speedlist,
                      useCubicSmoothing: true,
                      cubicSmoothingFactor: 0.2,
                      gridLineLabelPrecision: 3,
                      enableGridLines: true,
                    ),
                  ),
              ),
            Text(
              'Speed graph',
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: MediaQuery.of(context).size.width * 0.05
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, ((MediaQuery.of(context).padding.top)), 0, 0),
              child: Container(
                width: MediaQuery.of(context).size.width/1.1,
                height: MediaQuery.of(context).size.height/5,
                child: Sparkline(
                  data: prslist,
                  useCubicSmoothing: true,
                  cubicSmoothingFactor: 0.2,
                  gridLineLabelPrecision: 6,
                  enableGridLines: true,
                ),
              ),
            ),
            Text(
              'Pressure graph',
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: MediaQuery.of(context).size.width * 0.05
              ),
            ),
          ],
        ),
      ),
    );
  }
}
