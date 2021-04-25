import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<int> _points = [];
  List<List<int>> framesList = [];

  Timer _timer;
  int startI = 1;

  void _increment () {
    if(_timer == null) {
      _timer = Timer.periodic(Duration(milliseconds: 20), onTimeout);
    }
    else {
      _timer.cancel();
      _timer = null;
    }
    setState(() {
      this._timer = _timer;
    });
  }

  void onTimeout (Timer timer) {
    _points = framesList[startI];
    startI ++;
    if(startI >= framesList.length) startI = 0;
    setState(() {
      this.startI = startI;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('init');

    rootBundle.load("lib/assets/20201009162557").then((ByteData value) {

      const length_frame = 3600;
      int frames = value.lengthInBytes ~/ (length_frame * 2);
      List<List<int>> list = new List(frames);

      for (int frame = 0; frame < frames; frame++) {

        List<int> slist = new List(length_frame);
        for (int i = 0; i < length_frame; i++) {
          int num = value.getUint16(frame * length_frame * 2 + i * 2, Endian.little);
          slist[i] = num;
        }
        list[frame] = slist;
      }

      setState(() {
        framesList = list;
        _points = list[1743];
      });
      print('读取数据 end ${list.length}');


    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: CustomPaint(
          size: Size(300, 300),
          painter: PressurePainter(_points),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _increment,
        tooltip: 'Increment',
        child: _timer == null ? Icon(Icons.play_arrow) : Icon(Icons.stop),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


class PressurePainter extends CustomPainter {

  final List<int> _list;

  PressurePainter(this._list);

  @override
  void paint(Canvas canvas, Size size) {

    final _pointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 5.0
      ..color = Colors.black;

    // 放大比例
    final scaleX = size.width / 60;
    final scaleY = size.height / 60;

    canvas.scale(scaleX, scaleY);
    canvas.drawRect(Rect.fromLTWH(0, 0, 60, 60), _pointPaint);

    for(int i = 0; i < _list.length; i++) {
      final offsetX = i % 60;
      final offsetY = i ~/ 60;
      int item = toColorValue(_list[i]*3).toInt();

      Color color = toColor(item);
      _pointPaint.color = color;
      canvas.drawRect(Rect.fromLTWH(offsetX.toDouble(), offsetY.toDouble(), 1, 1), _pointPaint);

    }

    // 按中心旋转画布
    // double xAngle = Math.pi;
    // double r = Math.sqrt(Math.pow(size.width, 2) + Math.pow(size.height, 2));
    // double startAngle = Math.atan(size.height / size.width);
    // double x0 = r * Math.cos(startAngle);
    // double y0 = r * Math.sin(startAngle);
    // Math.Point p0 = Math.Point(x0, y0);
    // double realAngle = xAngle + startAngle;
    // Math.Point px = Math.Point(r * Math.cos(realAngle), r * Math.sin(realAngle));
    // canvas.translate((p0.x - px.x) / 2, (p0.y - px.y) / 2);
    // canvas.rotate(xAngle);


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }

  // 压力值转颜色数据

  double toColorValue (int value) {
    return ( value / 4096 ) * 255;
  }

  Color toColor(int value) {

    if(value > 255) value = 255;

    if(value < 30) {
      return Color.fromARGB(255, 0, 0, 0);
    }
    else if(value < 51) {
      return Color.fromARGB(255, 0, 0, value * 5);
    }
    else if(value <= 102) {
      value -= 51;
      return Color.fromARGB(255, 0, value * 5, 255 - value * 5);
    }
    else if(value <= 153) {
      value -= 102;
      return Color.fromARGB(255, value * 5, 255, 0);
    }
    else if(value <= 204) {
      return Color(0xfff44c02);
    }
    else {
      return Color(0xfffc1701);
    }
  }


}