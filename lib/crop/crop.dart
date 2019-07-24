import 'dart:io';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => afterFirstLayout(context));
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          onScaleStart: (ScaleStartDetails details) {
            _myRenderBox = context.findRenderObject();
            _scaleStartOffset = _myRenderBox.globalToLocal(details.focalPoint);
            _scaleStartScale = _scale;
            _scaleStartTopLeft = Offset(_topLeft.dx, _topLeft.dy);
          },
          onScaleUpdate: (ScaleUpdateDetails details) {
            Offset relativeFocalPoint = _myRenderBox.globalToLocal(details.focalPoint);
            double accumulatedScale = _scaleStartScale * details.scale;
            if (accumulatedScale < 1) {
              _scaleStartScale /= accumulatedScale;
              accumulatedScale = 1;
            }
            Offset offset = relativeFocalPoint - _scaleStartOffset;
            Offset topLeft = Offset(_scaleStartTopLeft.dx, _scaleStartTopLeft.dy);
            Offset zoomOffset = relativeFocalPoint - _scaleStartTopLeft;
            zoomOffset *= -(details.scale - 1);
            topLeft += offset;
            topLeft += zoomOffset;
            // clamping
            Offset clampingOffset;
            double clampLeft = 0;
            double clampTop = 0;
            double maxX = _imageSize.width * accumulatedScale * _screenScale - _viewSize.width;
            double maxY = _imageSize.height * accumulatedScale * _screenScale - _viewSize.height;
            if (topLeft.dx > 0) {
              clampLeft = -topLeft.dx;
            }
            if (topLeft.dx < -maxX) {
              clampLeft = -maxX - topLeft.dx;
            }
            if (topLeft.dy > 0) {
              clampTop = -topLeft.dy;
            }
            if (topLeft.dy < -maxY) {
              clampTop = -maxY - topLeft.dy;
            }
            clampingOffset = Offset(clampLeft, clampTop);
            topLeft += clampingOffset;
            _scaleStartTopLeft += clampingOffset;
            setState(() {
              _scale = accumulatedScale;
              _topLeft = topLeft;
            });
          },
          onScaleEnd: (ScaleEndDetails details) {
            _scaleStartOffset = null;
            _scaleStartScale = null;
            print(_scale * _screenScale);
            print(getVisibleRect());
          },
          child: AspectRatio(
            aspectRatio: constraints.maxWidth / constraints.maxHeight,
            child: Transform(
              transform: Matrix4.diagonal3Values(_scale, _scale, _scale)
                ..setTranslationRaw(_topLeft.dx, _topLeft.dy, 0),
              child: Image.file(
                widget.file,
              ),
            ),
          ),
        );
      },
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
          if (hScale < wScale) {
            _screenScale = wScale;
          } else {
            _screenScale = hScale;
          }
          print(_screenScale);
          _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
          _viewSize = context.size;
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