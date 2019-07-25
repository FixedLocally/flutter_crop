import 'dart:io';

import 'package:crop/crop/zoomable_image.dart';
import 'package:flutter/material.dart';

class CropWidget extends StatefulWidget {
  final File file;

  const CropWidget({Key key, this.file}) : super(key: key);

  @override
  _CropWidgetState createState() => _CropWidgetState();
}

class _CropWidgetState extends State<CropWidget> {
  double _screenScale;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Crop(
      FileImage(widget.file),
      minScale: _screenScale ?? 0,
      maxScale: double.infinity,
      debug: true,
    );
  }
}