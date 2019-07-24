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
  Offset _topLeft = Offset(0, 0);
  double _scale = 1;
  double _screenScale;

  Offset _scaleStartOffset;
  double _scaleStartScale;
  Offset _scaleStartTopLeft;

  RenderBox _myRenderBox;

  Image _imageWidget;
  Size _imageSize;
  Size _viewSize;

  @override
  void initState() {
    super.initState();
    _imageWidget = new Image.file(
      widget.file,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ZoomableImage(
      FileImage(widget.file),
      minScale: _screenScale ?? 0,
      maxScale: double.infinity,
    );
  }

  void afterFirstLayout(BuildContext context) {
    if (_screenScale != null) {
      return;
    }
    _imageWidget.image
        .resolve(new ImageConfiguration())
        .addListener((ImageInfo info, bool _) {
          print('img width=${info.image.width}');
          print('img height=${info.image.height}');
          print('view size=${context.size}');
          if (context.size.height == 0 || context.size.width == 0) {
            setState(() {
              // draw again
            });
            return;
          }
          double hScale = context.size.height / info.image.height;
          double wScale = context.size.width / info.image.width;
          _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
          _viewSize = context.size;
          setState(() {
            if (hScale > wScale) {
              _screenScale = wScale;
            } else {
              _screenScale = hScale;
            }
          });
          print('screen scale=$_screenScale');
        }
    );
  }

  Rect getVisibleRect() {
    double left = -_topLeft.dx / _screenScale / _scale;
    double top = -_topLeft.dy / _screenScale / _scale;
    double right = (_viewSize.width - _topLeft.dx) / _screenScale / _scale;
    double bottom = (_viewSize.height - _topLeft.dy) / _screenScale / _scale;
    return Rect.fromLTRB(left, top, right, bottom);
  }
}