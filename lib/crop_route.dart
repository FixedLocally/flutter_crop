import 'dart:io';

import 'package:crop/crop/crop2.dart';
import 'package:flutter/material.dart';

class CropRoute extends StatelessWidget {
  final File file;

  const CropRoute({Key key, this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop'),
      ),
      body: CropWidget(file: file),
    );
  }
}