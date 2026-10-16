import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'box_decoration_mix.dart';

/// An interpolation between two [Decoration]s that animates smoothly between
/// any two [BoxDecoration]s.
///
/// Unlike [DecorationTween], this tween smoothly animates between a color and
/// a gradient, between gradients of different types, and from, to or between
/// images. Borders, border radii and shadows are interpolated like
/// [BoxDecoration.lerp] does, and the [BoxDecoration.shape] switches half way
/// through the animation.
///
/// Other kinds of decorations are interpolated with [Decoration.lerp], like
/// [DecorationTween] does.
///
/// See also:
///
///  * `SmoothAnimatedContainer`, which uses this tween to animate its
///    decorations.
class SmoothDecorationTween extends DecorationTween {
  /// Creates a decoration tween.
  ///
  /// The [begin] and [end] properties may be null. If only one of them is null,
  /// the other one is scaled from or to nothing; if both are null, [lerp]
  /// returns an empty [BoxDecoration].
  SmoothDecorationTween({super.begin, super.end});

  /// Returns the decoration this tween has at the given animation clock value.
  @override
  Decoration lerp(double t) {
    final Decoration? begin = this.begin;
    final Decoration? end = this.end;
    if (begin is BoxDecoration && end is BoxDecoration) {
      return lerpBoxDecoration(begin, end, t) ?? const BoxDecoration();
    }
    if (begin != null &&
        end != null &&
        !identical(begin, end) &&
        t != 0.0 &&
        t != 1.0 &&
        (_isIntermediate(begin) || _isIntermediate(end))) {
      // This happens when an animation (e.g. of a SmoothAnimatedContainer) is
      // interrupted while it shows an intermediate decoration of this tween:
      // the new animation starts from that decoration. Decoration.lerp cannot
      // interpolate it (it would show `begin` unchanged for half of the
      // animation, and then fade `end` in from nothing), so cross-fade the two
      // decorations instead.
      return _DecorationCrossFade(begin, end, t);
    }
    return Decoration.lerp(begin, end, t) ?? const BoxDecoration();
  }

  /// Whether [decoration] is one of the intermediate decorations that only
  /// this tween produces.
  static bool _isIntermediate(Decoration decoration) =>
      decoration is BoxDecorationMix || decoration is _DecorationCrossFade;

  /// Whether [a] and [b] are gradients of the same built-in type, which can be
  /// interpolated with [Gradient.lerp].
  static bool _isSameGradient(Gradient a, Gradient b) {
    return (a is LinearGradient && b is LinearGradient) ||
        (a is RadialGradient && b is RadialGradient) ||
        (a is SweepGradient && b is SweepGradient);
  }

  /// Whether [lerpGradient] can interpolate between [a] and [b].
  static bool _canLerpGradients(Gradient? a, Gradient? b) {
    if (a != null && b != null) {
      return _isSameGradient(a, b);
    }
    final Gradient? gradient = a ?? b;
    return gradient == null ||
        gradient is LinearGradient ||
        gradient is RadialGradient ||
        gradient is SweepGradient;
  }

  /// The gradient of [decoration] as it is painted: a [BoxDecoration] paints
  /// its gradient with the opacity of its color, if it has one.
  static Gradient? _paintedGradient(BoxDecoration decoration) {
    final Gradient? gradient = decoration.gradient;
    final Color? color = decoration.color;
    if (gradient == null || color == null || color.a == 1.0) {
      return gradient;
    }
    return gradient.scale(color.a);
  }

  /// Linearly interpolates between two [BoxDecoration]s.
  ///
  /// If [a] and [b] only differ in their colors, borders, border radii,
  /// shadows, shape, and gradients of the same type (or a gradient and a
  /// color), the result is a [BoxDecoration]. Otherwise (e.g. when either one
  /// has an image, or they have gradients of different types), the result is a
  /// decoration that cross-fades the two.
  ///
  /// If both are null, returns null. If only one is null, the other one is
  /// scaled, like [BoxDecoration.lerp] does.
  Decoration? lerpBoxDecoration(BoxDecoration? a, BoxDecoration? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    if (a == null) {
      return b!.scale(t);
    }
    if (b == null) {
      return a.scale(1.0 - t);
    }
    if (t == 0.0) {
      return a;
    }
    if (t == 1.0) {
      return b;
    }
    if (a == b) {
      return a;
    }

    final BoxShape shape = t < 0.5 ? a.shape : b.shape;
    // A circle cannot have a border radius (BoxDecoration asserts that), and
    // would not paint it anyway.
    final BorderRadiusGeometry? borderRadius = shape == BoxShape.circle
        ? null
        : BorderRadiusGeometry.lerp(a.borderRadius, b.borderRadius, t);
    final BoxBorder? border = BoxBorder.lerp(a.border, b.border, t);
    final List<BoxShadow>? boxShadow =
        _lerpBoxShadows(a.boxShadow, b.boxShadow, t);
    final BlendMode? backgroundBlendMode =
        t < 0.5 ? a.backgroundBlendMode : b.backgroundBlendMode;
    final Gradient? aGradient = _paintedGradient(a);
    final Gradient? bGradient = _paintedGradient(b);

    // If there is an image in either a or b, or if their gradients cannot be
    // interpolated, cross-fade them.
    if (a.image != null ||
        b.image != null ||
        !_canLerpGradients(aGradient, bGradient)) {
      final DecorationImage? aImage = a.image;
      final DecorationImage? bImage = b.image;
      return BoxDecorationMix(
        // A BoxDecoration with a gradient only uses the opacity of its color,
        // which is taken into account by _paintedGradient.
        color: Color.lerp(
          aGradient == null ? a.color : null,
          bGradient == null ? b.color : null,
          t,
        ),
        image1: aImage == null
            ? null
            : _withOpacity(aImage, ui.lerpDouble(aImage.opacity, 0, t)!),
        image2: bImage == null
            ? null
            : _withOpacity(bImage, ui.lerpDouble(0, bImage.opacity, t)!),
        border: border,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        gradient1: aGradient?.scale(1 - t),
        gradient2: bGradient?.scale(t),
        backgroundBlendMode: backgroundBlendMode,
        shape: shape,
      );
    }

    if (aGradient != null || bGradient != null) {
      return BoxDecoration(
        border: border,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        gradient: lerpGradient(
            t,
            aGradient,
            bGradient,
            a.color ?? const Color(0x00FFFFFF),
            b.color ?? const Color(0x00FFFFFF)),
        backgroundBlendMode: backgroundBlendMode,
        shape: shape,
      );
    }

    return BoxDecoration(
      color: Color.lerp(a.color, b.color, t),
      border: border,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      backgroundBlendMode: backgroundBlendMode,
      shape: shape,
    );
  }

  /// Linearly interpolates between two gradients, or between a gradient and a
  /// color.
  ///
  /// If one of the gradients is null, it is replaced by a gradient of the same
  /// type and geometry as the other one, whose colors are all `beginColor` (if
  /// `beginGradient` is null) or `endColor` (if `endGradient` is null). Only
  /// [LinearGradient], [RadialGradient] and [SweepGradient] are supported in
  /// that case; for other gradients, null is returned.
  ///
  /// If both gradients are null, returns null.
  Gradient? lerpGradient(double t, Gradient? beginGradient,
      Gradient? endGradient, Color beginColor, Color endColor) {
    if (beginGradient != null && endGradient != null) {
      return Gradient.lerp(beginGradient, endGradient, t);
    }
    if (endGradient != null) {
      return switch (endGradient) {
        LinearGradient() => LinearGradient.lerp(
            _solidLinearGradient(endGradient, beginColor), endGradient, t),
        RadialGradient() => RadialGradient.lerp(
            _solidRadialGradient(endGradient, beginColor), endGradient, t),
        SweepGradient() => SweepGradient.lerp(
            _solidSweepGradient(endGradient, beginColor), endGradient, t),
        _ => null,
      };
    }
    if (beginGradient != null) {
      return switch (beginGradient) {
        LinearGradient() => LinearGradient.lerp(
            beginGradient, _solidLinearGradient(beginGradient, endColor), t),
        RadialGradient() => RadialGradient.lerp(
            beginGradient, _solidRadialGradient(beginGradient, endColor), t),
        SweepGradient() => SweepGradient.lerp(
            beginGradient, _solidSweepGradient(beginGradient, endColor), t),
        _ => null,
      };
    }
    return null;
  }

  /// A gradient with the geometry of [gradient], filled with [color].
  static LinearGradient _solidLinearGradient(
      LinearGradient gradient, Color color) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      transform: gradient.transform,
      tileMode: gradient.tileMode,
      stops: gradient.stops,
      colors: List<Color>.filled(gradient.colors.length, color),
    );
  }

  /// A gradient with the geometry of [gradient], filled with [color].
  static RadialGradient _solidRadialGradient(
      RadialGradient gradient, Color color) {
    return RadialGradient(
      center: gradient.center,
      radius: gradient.radius,
      focal: gradient.focal,
      focalRadius: gradient.focalRadius,
      transform: gradient.transform,
      tileMode: gradient.tileMode,
      stops: gradient.stops,
      colors: List<Color>.filled(gradient.colors.length, color),
    );
  }

  /// A gradient with the geometry of [gradient], filled with [color].
  static SweepGradient _solidSweepGradient(
      SweepGradient gradient, Color color) {
    return SweepGradient(
      center: gradient.center,
      startAngle: gradient.startAngle,
      endAngle: gradient.endAngle,
      transform: gradient.transform,
      tileMode: gradient.tileMode,
      stops: gradient.stops,
      colors: List<Color>.filled(gradient.colors.length, color),
    );
  }

  /// A copy of [image] with the given [opacity].
  static DecorationImage _withOpacity(DecorationImage image, double opacity) {
    return DecorationImage(
      image: image.image,
      onError: image.onError,
      colorFilter: image.colorFilter,
      fit: image.fit,
      alignment: image.alignment,
      centerSlice: image.centerSlice,
      repeat: image.repeat,
      matchTextDirection: image.matchTextDirection,
      scale: image.scale,
      opacity: opacity,
      filterQuality: image.filterQuality,
      invertColors: image.invertColors,
      isAntiAlias: image.isAntiAlias,
    );
  }

  /// Like [BoxShadow.lerpList], but also supports a `t` outside of the range
  /// 0.0 to 1.0 (as produced by curves like [Curves.elasticOut]), for which
  /// [BoxShadow.lerpList] can produce a negative blur radius, which is not
  /// allowed.
  static List<BoxShadow>? _lerpBoxShadows(
      List<BoxShadow>? a, List<BoxShadow>? b, double t) {
    if (t >= 0.0 && t <= 1.0) {
      return BoxShadow.lerpList(a, b, t);
    }
    if (identical(a, b)) {
      return a;
    }
    a ??= const <BoxShadow>[];
    b ??= const <BoxShadow>[];
    final int commonLength = math.min(a.length, b.length);
    return <BoxShadow>[
      for (int i = 0; i < commonLength; i += 1)
        BoxShadow(
          color: Color.lerp(a[i].color, b[i].color, t)!,
          offset: Offset.lerp(a[i].offset, b[i].offset, t)!,
          blurRadius: math.max(
              0.0, ui.lerpDouble(a[i].blurRadius, b[i].blurRadius, t)!),
          spreadRadius: ui.lerpDouble(a[i].spreadRadius, b[i].spreadRadius, t)!,
          blurStyle: a[i].blurStyle == BlurStyle.normal
              ? b[i].blurStyle
              : a[i].blurStyle,
        ),
      for (int i = commonLength; i < a.length; i += 1)
        _scaleBoxShadow(a[i], 1.0 - t),
      for (int i = commonLength; i < b.length; i += 1) _scaleBoxShadow(b[i], t),
    ];
  }

  /// Like [BoxShadow.scale], but never produces a negative blur radius.
  static BoxShadow _scaleBoxShadow(BoxShadow shadow, double factor) {
    return BoxShadow(
      color: shadow.color,
      offset: shadow.offset * factor,
      blurRadius: math.max(0.0, shadow.blurRadius * factor),
      spreadRadius: shadow.spreadRadius * factor,
      blurStyle: shadow.blurStyle,
    );
  }
}

/// A decoration that cross-fades from decoration [a] to decoration [b].
///
/// [SmoothDecorationTween] uses it to animate from one of its intermediate
/// decorations, which happens when an animation is interrupted.
@immutable
class _DecorationCrossFade extends Decoration {
  const _DecorationCrossFade(this.a, this.b, this.t);

  final Decoration a;
  final Decoration b;
  final double t;

  @override
  EdgeInsetsGeometry get padding =>
      EdgeInsetsGeometry.lerp(a.padding, b.padding, clampDouble(t, 0.0, 1.0))!;

  @override
  bool get isComplex => a.isComplex || b.isComplex;

  @override
  bool debugAssertIsValid() =>
      a.debugAssertIsValid() &&
      b.debugAssertIsValid() &&
      super.debugAssertIsValid();

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      (t < 0.5 ? a : b).getClipPath(rect, textDirection);

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      (t < 0.5 ? a : b).hitTest(size, position, textDirection: textDirection);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    BoxPainter create(Decoration decoration) => onChanged == null
        ? decoration.createBoxPainter()
        : decoration.createBoxPainter(onChanged);
    return _DecorationCrossFadePainter(
      create(a),
      create(b),
      clampDouble(t, 0.0, 1.0),
      onChanged,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _DecorationCrossFade &&
        other.a == a &&
        other.b == b &&
        other.t == t;
  }

  @override
  int get hashCode => Object.hash(a, b, t);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>('a', a));
    properties.add(DiagnosticsProperty<Decoration>('b', b));
    properties.add(DoubleProperty('t', t));
  }
}

class _DecorationCrossFadePainter extends BoxPainter {
  _DecorationCrossFadePainter(this._a, this._b, this._t, super.onChanged);

  final BoxPainter _a;
  final BoxPainter _b;
  final double _t;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    // Paint both decorations into a layer, with opacities that add up to 1, and
    // add the second one to the first one. This way, two opaque decorations
    // result in an opaque cross-fade.
    canvas.saveLayer(null, Paint());
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, 1.0 - _t));
    _a.paint(canvas, offset, configuration);
    canvas.restore();
    canvas.saveLayer(
      null,
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, _t)
        ..blendMode = BlendMode.plus,
    );
    _b.paint(canvas, offset, configuration);
    canvas.restore();
    canvas.restore();
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }
}
