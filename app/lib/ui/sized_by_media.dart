import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A photo (or album, or video) with lines above/below it that take exactly
/// the photo's width: words start at the left and the time sits at the
/// right edge, and a short caption never makes the bubble wider than the
/// photo (검수 2026-11-28; a plain Column grew to the whole bubble width).
///
/// [children] stack top to bottom. The child at [media] is laid out first
/// with the incoming constraints; every other child then gets exactly that
/// width. A line wider than the photo wraps inside it.
class SizedByMedia extends MultiChildRenderObjectWidget {
  const SizedByMedia({super.key, required this.media, required super.children});

  final int media;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizedByMedia(media);

  @override
  void updateRenderObject(BuildContext context, _RenderSizedByMedia renderObject) => renderObject.media = media;
}

/// Narrower than this = no real photo to size by.
const double _minMedia = 48;

class _SizedByMediaData extends ContainerBoxParentData<RenderBox> {}

class _RenderSizedByMedia extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _SizedByMediaData>, RenderBoxContainerDefaultsMixin<RenderBox, _SizedByMediaData> {
  _RenderSizedByMedia(this._media);

  int _media;
  set media(int v) {
    if (v == _media) return;
    _media = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SizedByMediaData) child.parentData = _SizedByMediaData();
  }

  List<RenderBox> get _kids {
    final out = <RenderBox>[];
    var c = firstChild;
    while (c != null) {
      out.add(c);
      c = childAfter(c);
    }
    return out;
  }

  RenderBox? get _sizer {
    final k = _kids;
    return _media >= 0 && _media < k.length ? k[_media] : null;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _sizer?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) => _sizer?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) => _kids.fold(0.0, (a, c) => a + c.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) => _kids.fold(0.0, (a, c) => a + c.getMaxIntrinsicHeight(width));

  Size _run(BoxConstraints constraints, {required bool dry}) {
    final k = _kids;
    final sizer = _sizer;
    if (sizer == null) return constraints.smallest;
    final loose = constraints.loosen();
    final s = dry ? sizer.getDryLayout(loose) : (sizer..layout(loose, parentUsesSize: true)).size;
    // No photo to measure (not loaded, failed, or hidden): the lines keep
    // their own width instead of wrapping one letter per line.
    var w = s.width;
    if (w < _minMedia) {
      for (final c in k) {
        if (!identical(c, sizer)) w = math.max(w, c.getMaxIntrinsicWidth(double.infinity));
      }
      w = math.min(w, loose.maxWidth);
    }
    final others = BoxConstraints.tightFor(width: w);
    var y = 0.0;
    for (final c in k) {
      final h = identical(c, sizer) ? s.height : (dry ? c.getDryLayout(others).height : (c..layout(others, parentUsesSize: true)).size.height);
      if (!dry) (c.parentData! as _SizedByMediaData).offset = Offset(0, y);
      y += h;
    }
    return constraints.constrain(Size(w, y));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _run(constraints, dry: true);

  @override
  void performLayout() => size = _run(constraints, dry: false);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
