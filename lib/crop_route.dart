import 'dart:io';

import 'package:crop/crop/crop.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CropRoute extends StatelessWidget {
  final File file;
  GlobalKey<CropState> _key = GlobalKey();

  CropRoute({Key key, this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              print(_key.currentState.cropRect);
            },
          ),
        ],
      ),
      body: Crop(
        FileImage(file),
        key: _key,
        minScale: 0,
        maxScale: double.infinity,
        debug: true,
      ),
    );
  }
}