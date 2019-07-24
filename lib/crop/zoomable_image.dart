import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


class ZoomableImage extends StatefulWidget {
  final ImageProvider image;
  final double maxScale;
  final double minScale;
  final GestureTapCallback onTap;
  final Color backgroundColor;
  final Widget placeholder;

  ZoomableImage(
      this.image, {
        Key key,
        @deprecated double scale,

        /// Maximum ratio to blow up image pixels. A value of 2.0 means that the
        /// a single device pixel will be rendered as up to 4 logical pixels.
        this.maxScale = 2.0,
        this.minScale = 0.0,
        this.onTap,
        this.backgroundColor = Colors.black,

        /// Placeholder widget to be used while [image] is being resolved.
        this.placeholder,
      }) : super(key: key);

  @override
  ZoomableImageState createState() => new ZoomableImageState();
}

// See /flutter/examples/layers/widgets/gestures.dart
class ZoomableImageState extends State<ZoomableImage> {
  ImageStream _imageStream;
  ui.Image _image;
  Size _imageSize;

  Offset _startingFocalPoint;

  Offset _previousOffset;
  Offset _offset; // where the top left corner of the image is drawn

  double _previousScale;
  double _scale; // multiplier applied to scale the full image

  Orientation _previousOrientation;

  Size _canvasSize;
  Size _viewSize;
  double _minScale;

  Rect _cropArea;

  @override
  void initState() {
    super.initState();
    _minScale = widget.minScale;
  }

  void _centerAndScaleImage() {
    _imageSize = new Size(
      _image.width.toDouble(),
      _image.height.toDouble(),
    );

    _scale = math.min(
      _canvasSize.width / _imageSize.width,
      _canvasSize.height / _imageSize.height,
    );
    Size fitted = new Size(
      _imageSize.width * _scale,
      _imageSize.height * _scale,
    );

    Offset delta = _canvasSize - fitted;
    _offset = delta / 2.0; // Centers the image

    print(_scale);
  }

  // ignore: unused_element
  Function() _handleDoubleTap(BuildContext ctx) {
    // we will make a bettwer handler later
    return () {
      double newScale = _scale * 2;
      if (newScale > widget.maxScale) {
        _centerAndScaleImage();
        setState(() {});
        return;
      }

      // We want to zoom in on the center of the screen.
      // Since we're zooming by a factor of 2, we want the new offset to be twice
      // as far from the center in both width and height than it is now.
      Offset center = ctx.size.center(Offset.zero);
      Offset newOffset = _offset - (center - _offset);

      setState(() {
        _scale = newScale;
        _offset = newOffset;
      });
    };
  }

  void _handleScaleStart(ScaleStartDetails d) {
//    print("starting scale at ${d.focalPoint} from $_offset $_scale");
    _startingFocalPoint = d.focalPoint;
    _previousOffset = _offset;
    _previousScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails d) {
    double newScale = _previousScale * d.scale;
    if (newScale > widget.maxScale) {
      newScale = widget.maxScale;
    }
    if (newScale < _minScale) {
      newScale = _minScale;
    }

    // Ensure that item under the focal point stays in the same place despite zooming
    final Offset normalizedOffset =
        (_startingFocalPoint - _previousOffset) / _previousScale;
    Offset newOffset = d.focalPoint - normalizedOffset * newScale;
    double minX = _viewSize.width - _image.width * _scale;
    double minY = _viewSize.height - _image.height * _scale;
    double maxX = 0;
    double maxY = 0;
    if (0 < minX) {
      maxX = minX = minX / 2;
    }
    if (0 < minY) {
      maxY = minY = minY / 2;
    }
    double clampedX = newOffset.dx.clamp(minX, maxX);
    double clampedY = newOffset.dy.clamp(minY, maxY);
    newOffset = Offset(clampedX, clampedY);
    setState(() {
      _scale = newScale;
      _offset = newOffset;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    print('visible rect=$visibleRect');
    print('crop rect=${getCropRect()}');
  }

  @override
  Widget build(BuildContext ctx) {
    if (_image != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          afterImageReady(context));
    }
    Widget paintWidget() {
      return new CustomPaint(
        child: new Container(color: widget.backgroundColor),
        foregroundPainter: new _ZoomableImagePainter(
          image: _image,
          offset: _offset,
          scale: _scale,
        ),
      );
    }

    if (_image == null) {
      return widget.placeholder ?? Center(child: CircularProgressIndicator());
    }

    return new LayoutBuilder(builder: (ctx, constraints) {
      Orientation orientation = MediaQuery.of(ctx).orientation;
      if (orientation != _previousOrientation) {
        _previousOrientation = orientation;
        _canvasSize = constraints.biggest;
        _centerAndScaleImage();
      }

      return Stack(
        children: <Widget>[
          new GestureDetector(
            child: paintWidget(),
            onTap: widget.onTap,
//          onDoubleTap: _handleDoubleTap(ctx),
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
          ),
          Positioned( // top block
            left: 0,
            top: 0,
            right: 0,
            child: Container(
              height: _cropArea?.top ?? 0,
              decoration: BoxDecoration(
                color: Colors.black54,
              ),
            ),
          ),
          Positioned( // left block
            left: 0,
            top: topMargin,
            child: Container(
              height: _cropArea?.height ?? 0,
              width: leftMargin,
              decoration: BoxDecoration(
                color: Colors.black54,
              ),
            ),
          ),
          Positioned( // right block
            right: 0,
            top: topMargin,
            child: Container(
              height: _cropArea?.height ?? 0,
              width: rightMargin,
              decoration: BoxDecoration(
                color: Colors.black54,
              ),
            ),
          ),
          Positioned( // bottom block
            left: 0,
            bottom: 0,
            right: 0,
            child: Container(
              height: bottomMargin,
              decoration: BoxDecoration(
                color: Colors.black54,
              ),
            ),
          ),
          Positioned( // top bar
            left: leftMargin,
            right: rightMargin,
            top: (topMargin - 16).clamp(0.0, double.infinity),
            child: GestureDetector(
              onVerticalDragUpdate: (DragUpdateDetails details) {
                double dy = details.delta.dy;
                if (_cropArea.height - dy < 40 || _cropArea.top + dy < 16) {
                  return;
                }
                setState(() {
                  _cropArea = Rect.fromLTRB(_cropArea.left, _cropArea.top + dy, _cropArea.right, _cropArea.bottom);
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 16,
                    width: _cropArea?.width ?? 0,
                    color: Colors.transparent,
                  ),
                  Container(
                    height: 3,
                    width: _cropArea?.width ?? 0,
                    color: Colors.white70,
                  ),
                  Container(
                    height: 16,
                    width: _cropArea?.width ?? 0,
                    color: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Positioned( // bottom bar
            left: leftMargin,
            right: rightMargin,
            bottom: (bottomMargin - 16).clamp(0.0, double.infinity),
            child: GestureDetector(
              onVerticalDragUpdate: (DragUpdateDetails details) {
                double dy = details.delta.dy;
                if (_cropArea.height + dy < 40 || _cropArea.bottom + dy > _viewSize.height - 16) {
                  return;
                }
                setState(() {
                  _cropArea = Rect.fromLTRB(_cropArea.left, _cropArea.top, _cropArea.right, _cropArea.bottom + dy);
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 16,
                    width: _cropArea?.width ?? 0,
                    color: Colors.transparent,
                  ),
                  Container(
                    height: 3,
                    width: _cropArea?.width ?? 0,
                    color: Colors.white70,
                  ),
                  Container(
                    height: 16,
                    width: _cropArea?.width ?? 0,
                    color: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Positioned( // left bar
            left: (leftMargin - 16).clamp(0.0, double.infinity),
            top: topMargin,
            bottom: bottomMargin,
            child: GestureDetector(
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                double dx = details.delta.dx;
                if (_cropArea.width - dx < 40 || _cropArea.left + dx < 16) {
                  return;
                }
                setState(() {
                  _cropArea = Rect.fromLTRB(_cropArea.left + dx, _cropArea.top, _cropArea.right, _cropArea.bottom);
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: _cropArea?.height ?? 0,
                    width: 16,
                    color: Colors.transparent,
                  ),
                  Container(
                    height: _cropArea?.height ?? 0,
                    width: 3,
                    color: Colors.white70,
                  ),
                  Container(
                    height: _cropArea?.height ?? 0,
                    width: 16,
                    color: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Positioned( // right bar
            right: (rightMargin - 16).clamp(0.0, double.infinity),
            top: topMargin,
            bottom: bottomMargin,
            child: GestureDetector(
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                double dx = details.delta.dx;
                if (_cropArea.width + dx < 40 || _cropArea.right + dx > _viewSize.width - 16) {
                  return;
                }
                setState(() {
                  _cropArea = Rect.fromLTRB(_cropArea.left, _cropArea.top, _cropArea.right + dx, _cropArea.bottom);
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: _cropArea?.height ?? 0,
                    width: 16,
                    color: Colors.transparent,
                  ),
                  Container(
                    height: _cropArea?.height ?? 0,
                    width: 3,
                    color: Colors.white70,
                  ),
                  Container(
                    height: _cropArea?.height ?? 0,
                    width: 16,
                    color: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  double get topMargin => _cropArea?.top ?? 0;
  double get leftMargin => _cropArea?.left ?? 0;
  double get rightMargin => _viewSize != null && _cropArea != null ? (_viewSize.width - _cropArea?.right) : 0;
  double get bottomMargin => _viewSize != null && _cropArea != null ? (_viewSize.height - _cropArea?.bottom) : 0;

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    _imageStream = widget.image.resolve(createLocalImageConfiguration(context));
    _imageStream.addListener(_handleImageLoaded);
  }

  void _handleImageLoaded(ImageInfo info, bool synchronousCall) {
    print("image loaded: $info");
    setState(() {
      _image = info.image;
    });
  }

  void afterImageReady(BuildContext context) {
    if (_viewSize != null) {
      return;
    }
    print('img width=${_image.width}');
    print('img height=${_image.height}');
    print('view size=${context.size}');
    if (context.size.height == 0 || context.size.width == 0) {
      setState(() {
        // draw again
      });
      return;
    }
    _viewSize = context.size;
    double hScale = context.size.height / _image.height;
    double wScale = context.size.width / _image.width;
    double screenScale;
    if (hScale > wScale) {
      screenScale = wScale;
    } else {
      screenScale = hScale;
    }
    if (screenScale > _minScale) {
      _minScale = screenScale * 0.8;
    }

    // initial crop area
    double minX = _viewSize.width - _image.width * _scale;
    double minY = _viewSize.height - _image.height * _scale;
    double maxX = 0;
    double maxY = 0;
    if (0 < minX) {
      maxX = minX = minX / 2;
    }
    if (0 < minY) {
      maxY = minY = minY / 2;
    }
    setState(() {
      _cropArea = Rect.fromLTRB(0.1 * _viewSize.width, 0.1 * _viewSize.height, 0.9 * _viewSize.width, 0.9 * _viewSize.height);
    });
  }

  Rect get visibleRect {
    double left = -_offset.dx / _scale;
    double top = -_offset.dy / _scale;
    double right = (_viewSize.width - _offset.dx) / _scale;
    double bottom = (_viewSize.height - _offset.dy) / _scale;
    left = left.clamp(0.0, _image.width.toDouble());
    top = top.clamp(0.0, _image.height.toDouble());
    right = right.clamp(0.0, _image.width.toDouble());
    bottom = bottom.clamp(0.0, _image.height.toDouble());
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect getCropRect() {
    double left = (_cropArea.left - _offset.dx) / _scale;
    double top = (_cropArea.top - _offset.dy) / _scale;
    double right = (_cropArea.right - _offset.dx) / _scale;
    double bottom = (_cropArea.bottom - _offset.dy) / _scale;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  void dispose() {
    _imageStream.removeListener(_handleImageLoaded);
    super.dispose();
  }
}

class _ZoomableImagePainter extends CustomPainter {
  const _ZoomableImagePainter({this.image, this.offset, this.scale});

  final ui.Image image;
  final Offset offset;
  final double scale;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Size imageSize = new Size(image.width.toDouble(), image.height.toDouble());
    Size targetSize = imageSize * scale;

    paintImage(
      canvas: canvas,
      rect: offset & targetSize,
      image: image,
      fit: BoxFit.fill,
    );
  }

  @override
  bool shouldRepaint(_ZoomableImagePainter old) {
    return old.image != image || old.offset != offset || old.scale != scale;
  }
}
