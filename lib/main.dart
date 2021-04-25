import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as Math;

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
      print('start ${DateTime.now()}');
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
    if(startI >= framesList.length) {
      startI = 0;
      // print('start ${DateTime.now()}');
    }
    if(startI % 50 == 0) {
      // print('start ${DateTime.now()}');
    }
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
          size: Size(298, 298),
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
    final int scaleX = size.width ~/ 60;
    final int scaleY = size.height ~/ 60;
    final int scaleWidth = scaleX * 60;
    final int scaleHeight = scaleY * 60;

    List<List<int>> slist = new List((60) * scaleY);

    // 遍历行处理数据
    int sy = 0;
    int sx = 0;
    if(_list.length <= 0) return ;

    // 横向插值
    for(int y = 0; y < 60 - 1; y++) {
      sx = 0;
      sy = y * scaleY.toInt();
      List<int> rows = new List(scaleWidth);

      for(int x = 0; x < 60 - 1; x++) {
        int index = y * 60 + x;
        rows[sx] = _list[index.toInt()];
        sx++;

        int p0 = _list[index.toInt()];
        int p1 = _list[index.toInt() + 1];
        for(int x0 = 1; x0 < scaleX.toInt(); x0 ++) {

          double w = x0 / scaleX;
          double p = ( 1 - w) * p0   + w * p1;
          rows[sx] = p.toInt();
          sx++;

        }
      }
      slist[sy] = rows;
    }

    // 纵向插值
    for(int y = 1; y < scaleHeight - scaleY; y++) {
      sy = ((y ~/ scaleY) + 1) * scaleY;
      if(slist[y] == null && slist[sy] != null) {
        List<int> rows = new List(scaleWidth);
        for(int x = 0; x < scaleWidth - scaleX; x++) {

          int p0 = slist[y - 1][x];
          int p1 = slist[sy][x];

          double w = 1 / scaleY;
          double p = (( 1 - w) * p0   + w * p1).toDouble();
          rows[x] = p.toInt();
        }
        slist[y] = rows;
      }
    }

    // canvas.translate(size.width / 2, size.height /2);
    // canvas.rotate(Math.pi * 2);
    // canvas.translate(-size.width / 2, -size.height /2);

    // 以左下为中心 向上翻转画布
    canvas.translate(0, size.height);
    canvas.scale(1, -1);

    canvas.scale(size.width / scaleWidth, size.height / scaleHeight);  // 设置画布放大
    canvas.drawRect(Rect.fromLTWH(0, 0, scaleWidth + 0.0, scaleHeight + 0.0), _pointPaint);

    // int offsetY = (size.height - scaleHeight) ~/ 2; // 横坐标偏差
    // int offsetX = (size.width - scaleWidth) ~/ 2; // 纵坐标偏差
    // canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _pointPaint);

    for(int y = 0; y < scaleHeight - scaleY; y++) {
      for(int x = 0; x < scaleWidth - scaleX; x++) {
        if(slist[y] != null && slist[y][x] != null) {
          int num = (slist[y][x] * 3).toInt();
          double item = toColorValue(num);
          Color color = toColor(item.toInt());
          _pointPaint.color = color;
          canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), _pointPaint);
          // canvas.drawRect(Rect.fromLTWH(x.toDouble() + offsetX, y.toDouble() + offsetY, 1, 1), _pointPaint); //用于坐标偏差
        }
      }
    }


    // 翻回来 按时不需要
    // canvas.translate(0, size.height);
    // canvas.scale(1, -1);

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