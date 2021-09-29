import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EdgeDetection {
  static const MethodChannel _channel = const MethodChannel('edge_detection');

  static Future<ScanResult> get detectEdge async {
    final data = await _channel.invokeMethod('edge_detect');
    if (data == null ||
        data['cropped_image_path'] == null ||
        data['original_image_path'] == null ||
        data['quadrilateral_top_left'] == null ||
        data['quadrilateral_top_right'] == null ||
        data['quadrilateral_bottom_right'] == null ||
        data['quadrilateral_bottom_left'] == null) return null;
    debugPrint(data.toString());
    ScanResult result = ScanResult()
      ..croppedImagePath = data['cropped_image_path']
      ..originalImagePath = data['original_image_path']
      ..quadrilateral = (Quadrilateral()
        ..topLeft = Point<double>(
          data['quadrilateral_top_left'][0],
          data['quadrilateral_top_left'][1],
        )
        ..topRight = Point<double>(
          data['quadrilateral_top_right'][0],
          data['quadrilateral_top_right'][1],
        )
        ..bottomRight = Point<double>(
          data['quadrilateral_bottom_right'][0],
          data['quadrilateral_bottom_right'][1],
        )
        ..bottomLeft = Point<double>(
          data['quadrilateral_bottom_left'][0],
          data['quadrilateral_bottom_left'][1],
        ));

    return result;
  }
}

class ScanResult {
  String croppedImagePath;
  String originalImagePath;
  Quadrilateral quadrilateral;
}

class Quadrilateral {
  Point<double> topLeft;
  Point<double> topRight;
  Point<double> bottomRight;
  Point<double> bottomLeft;
}
