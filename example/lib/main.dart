import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:edge_detection/edge_detection.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ScanResult? _data;
  String? _croppedImagePath = 'Unknown';
  String? _originalImagePath = 'Unknown';
  List<Point<double>> _quadrilateral = [];

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scan() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      var data = await EdgeDetection.detectEdge;
      if (data == null) return;
      _data = data;
      _croppedImagePath = _data!.croppedImagePath;
      _originalImagePath = _data!.originalImagePath;
      _quadrilateral = [
        _data!.quadrilateral.topLeft,
        _data!.quadrilateral.topRight,
        _data!.quadrilateral.bottomRight,
        _data!.quadrilateral.bottomLeft,
      ];

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      if (!mounted) return;

      setState(() {});
    } on PlatformException {
      _croppedImagePath = 'Failed to get cropped image path.';
    }
  }

  Future<void> adjust() async {
    try {
      var data = await EdgeDetection.adjustCropping(_data!);
      if (data == null) return;
      _data = data;
      _croppedImagePath = _data!.croppedImagePath;
      _originalImagePath = _data!.originalImagePath;
      _quadrilateral = [
        _data!.quadrilateral.topLeft,
        _data!.quadrilateral.topRight,
        _data!.quadrilateral.bottomRight,
        _data!.quadrilateral.bottomLeft,
      ];

      if (!mounted) return;

      setState(() {});
    } on PlatformException {
      _croppedImagePath = 'Failed to get cropped image path.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cropped image path:'),
              Text(_croppedImagePath!),
              Container(height: 8),
              Text('Original image path:'),
              Text(_originalImagePath!),
              Container(height: 8),
              Text('Quadrilateral:'),
              Text(_quadrilateral.toString()),
              Container(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: scan,
                    child: Text("Scan"),
                  ),
                ],
              ),
              _data != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: adjust,
                          child: Text("Adjust"),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
