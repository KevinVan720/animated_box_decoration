// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'blend_decoration_image.dart';

/// An immutable description of how to paint a box that is in the middle of a
/// cross-fade between two [BoxDecoration]s.
///
/// This is what `SmoothDecorationTween` produces when two [BoxDecoration]s
/// cannot simply be interpolated, e.g. because one of them has an image or
/// because they have gradients of different types.
///
/// Like a [BoxDecoration], the box has a [border], a body, and may cast a
/// [boxShadow], and its [shape] is either a circle or a rectangle (whose
/// corners are rounded by [borderRadius]).
///
/// The body of the box is painted in layers. The bottom-most layer is the
/// [color], which fills the box. Above that are [gradient1] and then
/// [gradient2], which also fill the box. Finally there are the images: if
/// both [image1] and [image2] are given, they are cross-faded (i.e. added on
/// top of each other, each with its own opacity), otherwise the one that is
/// given is painted.
///
/// The [border] paints over the body; the [boxShadow], naturally, paints below
/// it.
///
/// See also:
///
///  * [BoxDecoration], which this decoration is modeled after.
class BoxDecorationMix extends Decoration {
  /// Creates a decoration that paints two cross-faded box backgrounds.
  ///
  /// * If [color] is null, this decoration does not paint a background color.
  /// * If [image1] or [image2] is null, this decoration does not paint that
  ///   image.
  /// * If [border] is null, this decoration does not paint a border.
  /// * If [borderRadius] is null, this decoration uses more efficient background
  ///   painting commands. The [borderRadius] argument must be null if [shape] is
  ///   [BoxShape.circle].
  /// * If [boxShadow] is null, this decoration does not paint a shadow.
  /// * If [gradient1] or [gradient2] is null, this decoration does not paint
  ///   that gradient.
  /// * If [backgroundBlendMode] is null, this decoration paints with
  ///   [BlendMode.srcOver].
  const BoxDecorationMix({
    this.color,
    this.image1,
    this.image2,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient1,
    this.gradient2,
    this.backgroundBlendMode,
    this.shape = BoxShape.rectangle,
  }) : assert(
          backgroundBlendMode == null ||
              color != null ||
              gradient1 != null ||
              gradient2 != null,
          "backgroundBlendMode applies to BoxDecoration's background color or "
          'gradient, but no color or gradient was provided.',
        );

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  BoxDecorationMix copyWith({
    Color? color,
    DecorationImage? image1,
    DecorationImage? image2,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient1,
    Gradient? gradient2,
    BlendMode? backgroundBlendMode,
    BoxShape? shape,
  }) {
    return BoxDecorationMix(
      color: color ?? this.color,
      image1: image1 ?? this.image1,
      image2: image2 ?? this.image2,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      gradient1: gradient1 ?? this.gradient1,
      gradient2: gradient2 ?? this.gradient2,
      backgroundBlendMode: backgroundBlendMode ?? this.backgroundBlendMode,
      shape: shape ?? this.shape,
    );
  }

  @override
  bool debugAssertIsValid() {
    assert(
      shape != BoxShape.circle || borderRadius == null,
      'A circle cannot have a border radius. Remove either the shape or the borderRadius argument.',
    );
    return super.debugAssertIsValid();
  }

  /// The color to fill in the background of the box.
  ///
  /// The color is filled into the [shape] of the box (e.g., either a rectangle,
  /// potentially with a [borderRadius], or a circle).
  ///
  /// The [color] is drawn under the gradients and the images.
  final Color? color;

  /// The image to paint above the background [color] and gradients.
  ///
  /// If [image2] is also given, the two images are cross-faded.
  ///
  /// If [shape] is [BoxShape.circle] then the image is clipped to the circle's
  /// boundary; if [borderRadius] is non-null then the image is clipped to the
  /// given radii.
  final DecorationImage? image1;

  /// The image to paint above the background [color] and gradients.
  ///
  /// If [image1] is also given, the two images are cross-faded.
  ///
  /// If [shape] is [BoxShape.circle] then the image is clipped to the circle's
  /// boundary; if [borderRadius] is non-null then the image is clipped to the
  /// given radii.
  final DecorationImage? image2;

  /// A border to draw above the background [color], gradients, and images.
  ///
  /// Follows the [shape] and [borderRadius].
  ///
  /// Use [Border] objects to describe borders that do not depend on the reading
  /// direction.
  ///
  /// Use [BoxBorder] objects to describe borders that should flip their left
  /// and right edges based on whether the text is being read left-to-right or
  /// right-to-left.
  final BoxBorder? border;

  /// If non-null, the corners of this box are rounded by this [BorderRadius].
  ///
  /// Applies only to boxes with rectangular shapes; must be null if [shape] is
  /// [BoxShape.circle].
  final BorderRadiusGeometry? borderRadius;

  /// A list of shadows cast by this box behind the box.
  ///
  /// The shadow follows the [shape] of the box.
  final List<BoxShadow>? boxShadow;

  /// A gradient to paint above the background [color].
  final Gradient? gradient1;

  /// A gradient to paint above the background [color] and [gradient1].
  final Gradient? gradient2;

  /// The blend mode applied to the [color] and gradients of the box.
  ///
  /// If no [backgroundBlendMode] is provided then the default painting blend
  /// mode is used.
  ///
  /// If no [color] or gradient is provided then the blend mode has no impact.
  final BlendMode? backgroundBlendMode;

  /// The shape to fill the background [color], gradients, and images into and
  /// to cast as the [boxShadow].
  ///
  /// If this is [BoxShape.circle] then [borderRadius] must be null.
  final BoxShape shape;

  @override
  EdgeInsetsGeometry get padding => border?.dimensions ?? EdgeInsets.zero;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) {
    switch (shape) {
      case BoxShape.circle:
        final Offset center = rect.center;
        final double radius = rect.shortestSide / 2.0;
        final Rect square = Rect.fromCircle(center: center, radius: radius);
        return Path()..addOval(square);
      case BoxShape.rectangle:
        if (borderRadius != null) {
          return Path()
            ..addRRect(borderRadius!.resolve(textDirection).toRRect(rect));
        }
        return Path()..addRect(rect);
    }
  }

  @override
  bool get isComplex => boxShadow != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BoxDecorationMix &&
        other.color == color &&
        other.image1 == image1 &&
        other.image2 == image2 &&
        other.border == border &&
        other.borderRadius == borderRadius &&
        listEquals<BoxShadow>(other.boxShadow, boxShadow) &&
        other.gradient1 == gradient1 &&
        other.gradient2 == gradient2 &&
        other.backgroundBlendMode == backgroundBlendMode &&
        other.shape == shape;
  }

  @override
  int get hashCode => Object.hash(
        color,
        image1,
        image2,
        border,
        borderRadius,
        boxShadow == null ? null : Object.hashAll(boxShadow!),
        gradient1,
        gradient2,
        backgroundBlendMode,
        shape,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace
      ..emptyBodyDescription = '<no decorations specified>';

    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<DecorationImage>('image1', image1,
        defaultValue: null));
    properties.add(DiagnosticsProperty<DecorationImage>('image2', image2,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<BoxBorder>('border', border, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderRadiusGeometry>(
        'borderRadius', borderRadius,
        defaultValue: null));
    properties.add(IterableProperty<BoxShadow>('boxShadow', boxShadow,
        defaultValue: null, style: DiagnosticsTreeStyle.whitespace));
    properties.add(DiagnosticsProperty<Gradient>('gradient1', gradient1,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Gradient>('gradient2', gradient2,
        defaultValue: null));
    properties.add(EnumProperty<BlendMode>(
        'backgroundBlendMode', backgroundBlendMode,
        defaultValue: null));
    properties.add(EnumProperty<BoxShape>('shape', shape,
        defaultValue: BoxShape.rectangle));
  }

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) {
    assert((Offset.zero & size).contains(position));
    switch (shape) {
      case BoxShape.rectangle:
        if (borderRadius != null) {
          final RRect bounds =
              borderRadius!.resolve(textDirection).toRRect(Offset.zero & size);
          return bounds.contains(position);
        }
        return true;
      case BoxShape.circle:
        // Circles are inscribed into our smallest dimension.
        final Offset center = size.center(Offset.zero);
        final double distance = (position - center).distance;
        return distance <= math.min(size.width, size.height) / 2.0;
    }
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    assert(onChanged != null || (image1 == null && image2 == null));
    return _BoxDecorationMixPainter(this, onChanged);
  }
}

/// An object that paints a [BoxDecorationMix] into a canvas.
class _BoxDecorationMixPainter extends BoxPainter {
  _BoxDecorationMixPainter(this._decoration, super.onChanged);

  final BoxDecorationMix _decoration;

  Paint? _cachedColorPaint;
  Paint _getColorPaint() {
    return _cachedColorPaint ??= _createBackgroundPaint()
      ..color = _decoration.color!;
  }

  final _GradientPaintCache _gradientPaint1 = _GradientPaintCache();
  final _GradientPaintCache _gradientPaint2 = _GradientPaintCache();

  Paint _createBackgroundPaint() {
    final Paint paint = Paint();
    if (_decoration.backgroundBlendMode != null) {
      paint.blendMode = _decoration.backgroundBlendMode!;
    }
    return paint;
  }

  void _paintBox(
      Canvas canvas, Rect rect, Paint paint, TextDirection? textDirection) {
    switch (_decoration.shape) {
      case BoxShape.circle:
        assert(
          _decoration.borderRadius == null,
          'A circle cannot have a border radius. Remove either the shape or the borderRadius argument.',
        );
        final Offset center = rect.center;
        final double radius = rect.shortestSide / 2.0;
        canvas.drawCircle(center, radius, paint);
      case BoxShape.rectangle:
        if (_decoration.borderRadius == null ||
            _decoration.borderRadius == BorderRadius.zero) {
          canvas.drawRect(rect, paint);
        } else {
          canvas.drawRRect(
              _decoration.borderRadius!.resolve(textDirection).toRRect(rect),
              paint);
        }
    }
  }

  void _paintShadows(Canvas canvas, Rect rect, TextDirection? textDirection) {
    if (_decoration.boxShadow == null) {
      return;
    }
    for (final BoxShadow boxShadow in _decoration.boxShadow!) {
      final Paint paint = boxShadow.toPaint();
      final Rect bounds =
          rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius);
      assert(() {
        if (debugDisableShadows && boxShadow.blurStyle == BlurStyle.outer) {
          canvas.save();
          canvas.clipRect(bounds);
        }
        return true;
      }());
      _paintBox(canvas, bounds, paint, textDirection);
      assert(() {
        if (debugDisableShadows && boxShadow.blurStyle == BlurStyle.outer) {
          canvas.restore();
        }
        return true;
      }());
    }
  }

  void _paintBackground(
      Canvas canvas, Rect rect, TextDirection? textDirection) {
    final Gradient? gradient1 = _decoration.gradient1;
    final Gradient? gradient2 = _decoration.gradient2;
    if (_decoration.color == null && gradient1 == null && gradient2 == null) {
      return;
    }
    // When border is filled, the rect is reduced to avoid anti-aliasing
    // rounding error leaking the background color around the clipped shape.
    final Rect adjustedRect =
        _adjustedRectOnOutlinedBorder(rect, textDirection);
    if (_decoration.color != null) {
      _paintBox(canvas, adjustedRect, _getColorPaint(), textDirection);
    }
    if (gradient1 != null) {
      final Paint paint = _gradientPaint1.get(
          gradient1, rect, textDirection, _createBackgroundPaint);
      _paintBox(canvas, adjustedRect, paint, textDirection);
    }
    if (gradient2 != null) {
      final Paint paint = _gradientPaint2.get(
          gradient2, rect, textDirection, _createBackgroundPaint);
      _paintBox(canvas, adjustedRect, paint, textDirection);
    }
  }

  double _calculateAdjustedSide(BorderSide side) {
    if (side.color.a == 1.0 && side.style == BorderStyle.solid) {
      return side.strokeInset;
    }
    return 0;
  }

  Rect _adjustedRectOnOutlinedBorder(Rect rect, TextDirection? textDirection) {
    final BoxBorder? border = _decoration.border;
    if (border == null) {
      return rect;
    }

    if (border is Border) {
      final EdgeInsets insets = EdgeInsets.fromLTRB(
            _calculateAdjustedSide(border.left),
            _calculateAdjustedSide(border.top),
            _calculateAdjustedSide(border.right),
            _calculateAdjustedSide(border.bottom),
          ) /
          2;

      return Rect.fromLTRB(
        rect.left + insets.left,
        rect.top + insets.top,
        rect.right - insets.right,
        rect.bottom - insets.bottom,
      );
    } else if (border is BorderDirectional && textDirection != null) {
      final BorderSide leftSide =
          textDirection == TextDirection.rtl ? border.end : border.start;
      final BorderSide rightSide =
          textDirection == TextDirection.rtl ? border.start : border.end;

      final EdgeInsets insets = EdgeInsets.fromLTRB(
            _calculateAdjustedSide(leftSide),
            _calculateAdjustedSide(border.top),
            _calculateAdjustedSide(rightSide),
            _calculateAdjustedSide(border.bottom),
          ) /
          2;

      return Rect.fromLTRB(
        rect.left + insets.left,
        rect.top + insets.top,
        rect.right - insets.right,
        rect.bottom - insets.bottom,
      );
    }
    return rect;
  }

  Path? _imageClipPath(Rect rect, TextDirection? textDirection) {
    switch (_decoration.shape) {
      case BoxShape.circle:
        assert(
          _decoration.borderRadius == null,
          'A circle cannot have a border radius. Remove either the shape or the borderRadius argument.',
        );
        final Offset center = rect.center;
        final double radius = rect.shortestSide / 2.0;
        final Rect square = Rect.fromCircle(center: center, radius: radius);
        return Path()..addOval(square);
      case BoxShape.rectangle:
        if (_decoration.borderRadius != null) {
          return Path()
            ..addRRect(
                _decoration.borderRadius!.resolve(textDirection).toRRect(rect));
        }
        return null;
    }
  }

  DecorationImagePainter? _imagePainter1;
  BlendDecorationImagePainter? _imagePainter2;

  void _paintBackgroundImages(
      Canvas canvas, Rect rect, ImageConfiguration configuration) {
    final DecorationImage? image1 = _decoration.image1;
    final DecorationImage? image2 = _decoration.image2;
    if (image1 == null && image2 == null) {
      return;
    }
    final Path? clipPath = _imageClipPath(rect, configuration.textDirection);
    // Two images are cross-faded: they are painted into their own layer, and
    // the second one is added to the first one. This way, two opaque images
    // with opacities that add up to 1 result in an opaque box.
    final bool crossFade = image1 != null && image2 != null;
    if (crossFade) {
      canvas.saveLayer(rect, Paint());
    }
    if (image1 != null) {
      _imagePainter1 ??= image1.createPainter(onChanged!);
      _imagePainter1!.paint(canvas, rect, clipPath, configuration);
    }
    if (image2 != null) {
      _imagePainter2 ??= BlendDecorationImagePainter(image2, onChanged!);
      _imagePainter2!.paint(canvas, rect, clipPath, configuration,
          crossFade ? BlendMode.plus : BlendMode.srcOver);
    }
    if (crossFade) {
      canvas.restore();
    }
  }

  @override
  void dispose() {
    _imagePainter1?.dispose();
    _imagePainter2?.dispose();
    super.dispose();
  }

  /// Paint the box decoration into the given location on the given canvas.
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size!;
    final TextDirection? textDirection = configuration.textDirection;
    _paintShadows(canvas, rect, textDirection);
    _paintBackground(canvas, rect, textDirection);
    _paintBackgroundImages(canvas, rect, configuration);
    _decoration.border?.paint(
      canvas,
      rect,
      shape: _decoration.shape,
      borderRadius: _decoration.borderRadius?.resolve(textDirection),
      textDirection: configuration.textDirection,
    );
  }

  @override
  String toString() {
    return 'BoxPainter for $_decoration';
  }
}

/// Caches the [Paint] for a gradient, which depends on the rect it fills.
class _GradientPaintCache {
  Paint? _paint;
  Rect? _rect;
  TextDirection? _textDirection;

  Paint get(Gradient gradient, Rect rect, TextDirection? textDirection,
      Paint Function() createPaint) {
    if (_paint == null || _rect != rect || _textDirection != textDirection) {
      _paint = createPaint()
        ..shader = gradient.createShader(rect, textDirection: textDirection);
      _rect = rect;
      _textDirection = textDirection;
    }
    return _paint!;
  }
}
