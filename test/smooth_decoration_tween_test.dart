import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:animated_box_decoration/animated_box_decoration.dart';
import 'package:animated_box_decoration/src/box_decoration_mix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

const Color kBlue = Color(0xFF2196F3);
const Color kRed = Color(0xFFF44336);
const Color kTranslucentGreen = Color(0x804CAF50);

const LinearGradient kLinear3 = LinearGradient(
  colors: <Color>[Color(0xFF000000), Color(0xFF04619F), Color(0xFF358F74)],
  stops: <double>[0.1, 0.5, 0.9],
);
const LinearGradient kLinear4 = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    Color(0xFFF6EA41),
    Color(0xFFEEBD89),
    Color(0xFFD13ABD),
    Color(0xFFAEBAF8),
  ],
);
const RadialGradient kRadial = RadialGradient(
  center: Alignment(0.2, -0.3),
  radius: 0.8,
  colors: <Color>[Color(0xFFFFEB3B), Color(0xFF9C27B0)],
);
const RadialGradient kRadial3 = RadialGradient(
  colors: <Color>[Color(0xFF00BCD4), Color(0xFFE91E63), Color(0xFF3F51B5)],
  stops: <double>[0.0, 0.4, 1.0],
);
const SweepGradient kSweep = SweepGradient(
  center: Alignment(0.13, 0.1),
  startAngle: 0.5,
  endAngle: 6.0,
  colors: <Color>[
    Color(0xFFF6EA41),
    Color(0xFFD13ABD),
    Color(0xFFB60F46),
    Color(0xFFF6EA41),
  ],
);
const SweepGradient kSweep2 = SweepGradient(
  colors: <Color>[Color(0xFF8BC34A), Color(0xFF795548)],
);

/// A [Gradient] that is not one of the three built-in types.
class TestGradient extends Gradient {
  const TestGradient({required super.colors});

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) =>
      ui.Gradient.linear(rect.topLeft, rect.bottomRight, colors);

  @override
  TestGradient scale(double factor) => TestGradient(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, factor)!)
            .toList(),
      );

  @override
  TestGradient withOpacity(double opacity) => TestGradient(
        colors: colors
            .map<Color>((Color color) => color.withValues(alpha: opacity))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is TestGradient && listEquals<Color>(other.colors, colors);

  @override
  int get hashCode => Object.hashAll(colors);
}

final DecorationImage kRedDecorationImage =
    DecorationImage(image: kRedImage, fit: BoxFit.fill);
final DecorationImage kBlueDecorationImage =
    DecorationImage(image: kBlueImage, fit: BoxFit.fill, opacity: 0.6);

const BoxDecoration kBlueBox = BoxDecoration(color: kBlue);
const BoxDecoration kRedBox = BoxDecoration(color: kRed);
const BoxDecoration kTranslucentBox = BoxDecoration(color: kTranslucentGreen);
const BoxDecoration kLinearBox = BoxDecoration(gradient: kLinear3);
const BoxDecoration kLinear4Box = BoxDecoration(gradient: kLinear4);
const BoxDecoration kRadialBox = BoxDecoration(gradient: kRadial);
const BoxDecoration kRadial3Box = BoxDecoration(gradient: kRadial3);
const BoxDecoration kSweepBox = BoxDecoration(gradient: kSweep);
const BoxDecoration kSweep2Box = BoxDecoration(gradient: kSweep2);
final BoxDecoration kRedImageBox = BoxDecoration(image: kRedDecorationImage);
final BoxDecoration kBlueImageBox = BoxDecoration(
  image: kBlueDecorationImage,
  color: kTranslucentGreen,
);
final BoxDecoration kBorderedBox = BoxDecoration(
  color: kRed,
  border: Border.all(color: const Color(0xFF000000), width: 4),
  borderRadius: BorderRadius.circular(8),
  boxShadow: const <BoxShadow>[
    BoxShadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(2, 2)),
  ],
);
final BoxDecoration kShadowedLinearBox = BoxDecoration(
  gradient: kLinear4,
  border: Border.all(color: const Color(0xFF3F51B5), width: 2),
  borderRadius: BorderRadius.circular(12),
  boxShadow: const <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 2),
    BoxShadow(color: Color(0x20FF0000), spreadRadius: 3, offset: Offset(1, 1)),
  ],
);
const BoxDecoration kCircleBox = BoxDecoration(
  color: kBlue,
  shape: BoxShape.circle,
);

Decoration lerpAt(Decoration? begin, Decoration? end, double t) =>
    SmoothDecorationTween(begin: begin, end: end).lerp(t);

void main() {
  group('SmoothDecorationTween', () {
    test('is a DecorationTween', () {
      final SmoothDecorationTween tween =
          SmoothDecorationTween(begin: kBlueBox, end: kRedBox);
      expect(tween, isA<DecorationTween>());
      expect(tween.begin, same(kBlueBox));
      expect(tween.end, same(kRedBox));
    });

    test('returns the exact begin and end at t = 0 and t = 1', () {
      final List<BoxDecoration> decorations = <BoxDecoration>[
        kBlueBox,
        kLinearBox,
        kSweepBox,
        kRedImageBox,
        kBorderedBox,
        kCircleBox,
      ];
      for (final BoxDecoration a in decorations) {
        for (final BoxDecoration b in decorations) {
          final SmoothDecorationTween tween =
              SmoothDecorationTween(begin: a, end: b);
          expect(tween.lerp(0.0), same(a));
          expect(tween.lerp(1.0), same(b));
          expect(tween.transform(0.0), same(a));
          expect(tween.transform(1.0), same(b));
        }
      }
    });

    test('returns begin when begin and end are equal', () {
      const BoxDecoration a = BoxDecoration(color: kBlue);
      // Not const, so that it is equal to `a` but not identical.
      final BoxDecoration b = BoxDecoration(color: kBlue);
      expect(lerpAt(a, b, 0.5), same(a));
    });

    group('color to color', () {
      test('interpolates the color', () {
        final Decoration result = lerpAt(kBlueBox, kRedBox, 0.5);
        expect(result, isA<BoxDecoration>());
        result as BoxDecoration;
        expect(result.color, Color.lerp(kBlue, kRed, 0.5));
        expect(result.gradient, isNull);
        expect(result.image, isNull);
      });

      test('interpolates from and to no color', () {
        final BoxDecoration result =
            lerpAt(const BoxDecoration(), kRedBox, 0.25) as BoxDecoration;
        expect(result.color, Color.lerp(null, kRed, 0.25));
      });
    });

    group('color and gradient', () {
      test('color to linear gradient lerps every stop from the color', () {
        final BoxDecoration result =
            lerpAt(kBlueBox, kLinearBox, 0.5) as BoxDecoration;
        expect(result.color, isNull);
        expect(result.image, isNull);
        final LinearGradient gradient = result.gradient! as LinearGradient;
        expect(gradient.colors, hasLength(3));
        for (int i = 0; i < 3; i++) {
          expect(gradient.colors[i],
              matchesColor(Color.lerp(kBlue, kLinear3.colors[i], 0.5)!));
        }
        expect(gradient.stops, kLinear3.stops);
        expect(gradient.begin, kLinear3.begin);
        expect(gradient.end, kLinear3.end);
      });

      test('linear gradient to color lerps every stop to the color', () {
        final BoxDecoration result =
            lerpAt(kLinearBox, kRedBox, 0.25) as BoxDecoration;
        final LinearGradient gradient = result.gradient! as LinearGradient;
        for (int i = 0; i < 3; i++) {
          expect(gradient.colors[i],
              matchesColor(Color.lerp(kLinear3.colors[i], kRed, 0.25)!));
        }
      });

      test('no color to gradient starts from transparent white', () {
        final BoxDecoration result = lerpAt(const BoxDecoration(),
            const BoxDecoration(gradient: kSweep), 0.5) as BoxDecoration;
        final SweepGradient gradient = result.gradient! as SweepGradient;
        expect(gradient.center, kSweep.center);
        expect(gradient.startAngle, kSweep.startAngle);
        expect(gradient.endAngle, kSweep.endAngle);
        for (int i = 0; i < kSweep.colors.length; i++) {
          expect(
            gradient.colors[i],
            matchesColor(
                Color.lerp(const Color(0x00FFFFFF), kSweep.colors[i], 0.5)!),
          );
        }
      });

      test('color to radial gradient keeps the radial geometry', () {
        final BoxDecoration result =
            lerpAt(kBlueBox, kRadialBox, 0.5) as BoxDecoration;
        final RadialGradient gradient = result.gradient! as RadialGradient;
        expect(gradient.center, kRadial.center);
        expect(gradient.radius, kRadial.radius);
        for (int i = 0; i < kRadial.colors.length; i++) {
          expect(gradient.colors[i],
              matchesColor(Color.lerp(kBlue, kRadial.colors[i], 0.5)!));
        }
      });
    });

    group('gradient to gradient of the same type', () {
      test('linear gradients with different lengths', () {
        final BoxDecoration result =
            lerpAt(kLinearBox, kLinear4Box, 0.5) as BoxDecoration;
        expect(result.gradient, LinearGradient.lerp(kLinear3, kLinear4, 0.5));
      });

      test('radial gradients with different lengths', () {
        final BoxDecoration result =
            lerpAt(kRadialBox, kRadial3Box, 0.3) as BoxDecoration;
        expect(result.gradient, RadialGradient.lerp(kRadial, kRadial3, 0.3));
      });

      test('sweep gradients', () {
        final BoxDecoration result =
            lerpAt(kSweepBox, kSweep2Box, 0.7) as BoxDecoration;
        expect(result.gradient, SweepGradient.lerp(kSweep, kSweep2, 0.7));
      });
    });

    group('gradient to gradient of a different type', () {
      for (final (String name, BoxDecoration a, BoxDecoration b)
          in <(String, BoxDecoration, BoxDecoration)>[
        ('linear to sweep', kLinearBox, kSweepBox),
        ('sweep to radial', kSweepBox, kRadialBox),
        ('radial to linear', kRadial3Box, kLinear4Box),
      ]) {
        test('$name cross-fades the two gradients', () {
          final Decoration result = lerpAt(a, b, 0.25);
          expect(result, isA<BoxDecorationMix>());
          result as BoxDecorationMix;
          expect(result.gradient1, a.gradient!.scale(0.75));
          expect(result.gradient2, b.gradient!.scale(0.25));
          expect(result.image1, isNull);
          expect(result.image2, isNull);
          expect(result.color, isNull);
        });
      }
    });

    group('images', () {
      test('color to image fades the image in', () {
        final BoxDecorationMix result =
            lerpAt(kBlueBox, kRedImageBox, 0.25) as BoxDecorationMix;
        expect(result.color, Color.lerp(kBlue, null, 0.25));
        expect(result.image1, isNull);
        final DecorationImage image = result.image2!;
        expect(image.image, kRedImage);
        expect(image.fit, BoxFit.fill);
        expect(image.opacity, 0.25);
      });

      test('image to color fades the image out', () {
        final BoxDecorationMix result =
            lerpAt(kBlueImageBox, kRedBox, 0.25) as BoxDecorationMix;
        expect(result.color, Color.lerp(kTranslucentGreen, kRed, 0.25));
        expect(result.image2, isNull);
        final DecorationImage image = result.image1!;
        expect(image.image, kBlueImage);
        expect(image.opacity, lerpDouble(0.6, 0, 0.25));
      });

      test('image to image fades the first image out and the second one in',
          () {
        final BoxDecorationMix result =
            lerpAt(kBlueImageBox, kRedImageBox, 0.4) as BoxDecorationMix;
        expect(result.image1!.image, kBlueImage);
        // (Before 0.0.8, the first image kept its opacity and the second one
        // was painted on top of it. BoxDecorationMix now adds the two images
        // instead, which looks the same for opaque images, but also works for
        // images that are translucent or do not cover the box.)
        expect(result.image1!.opacity, closeTo(lerpDouble(0.6, 0, 0.4)!, 1e-9));
        expect(result.image2!.image, kRedImage);
        expect(result.image2!.opacity, closeTo(0.4, 1e-9));
      });

      test('copies every DecorationImage property', () {
        void onError(Object error, StackTrace? stackTrace) {}
        DecorationImage withImage(ImageProvider image) => DecorationImage(
              image: image,
              onError: onError,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF00FF00), BlendMode.multiply),
              fit: BoxFit.cover,
              alignment: Alignment.topRight,
              centerSlice: const Rect.fromLTRB(1, 1, 1, 1),
              repeat: ImageRepeat.repeatX,
              matchTextDirection: true,
              scale: 2.0,
              opacity: 0.8,
              filterQuality: FilterQuality.high,
              invertColors: true,
              isAntiAlias: true,
            );
        final DecorationImage source = withImage(kRedImage);
        final BoxDecorationMix result = lerpAt(
          BoxDecoration(image: source),
          BoxDecoration(image: withImage(kBlueImage)),
          0.5,
        ) as BoxDecorationMix;
        for (final DecorationImage image in <DecorationImage>[
          result.image1!,
          result.image2!,
        ]) {
          expect(image.onError, onError);
          expect(image.colorFilter, source.colorFilter);
          expect(image.fit, source.fit);
          expect(image.alignment, source.alignment);
          expect(image.centerSlice, source.centerSlice);
          expect(image.repeat, source.repeat);
          expect(image.matchTextDirection, source.matchTextDirection);
          expect(image.scale, source.scale);
          expect(image.filterQuality, source.filterQuality);
          expect(image.invertColors, source.invertColors);
          expect(image.isAntiAlias, source.isAntiAlias);
        }
        expect(result.image1!.image, kRedImage);
        expect(result.image1!.opacity, closeTo(0.4, 1e-9));
        expect(result.image2!.image, kBlueImage);
        expect(result.image2!.opacity, closeTo(0.4, 1e-9));
      });

      test('gradient to image fades the gradient out', () {
        final BoxDecorationMix result =
            lerpAt(kLinearBox, kRedImageBox, 0.5) as BoxDecorationMix;
        expect(result.gradient1, kLinear3.scale(0.5));
        expect(result.gradient2, isNull);
        expect(result.image2!.opacity, 0.5);
      });
    });

    group('borders, radii and shadows', () {
      test('are interpolated without images or gradients', () {
        final BoxDecoration result =
            lerpAt(kBlueBox, kBorderedBox, 0.5) as BoxDecoration;
        expect(result.border, BoxBorder.lerp(null, kBorderedBox.border, 0.5));
        expect(result.borderRadius,
            BorderRadius.lerp(null, BorderRadius.circular(8), 0.5));
        expect(result.boxShadow,
            BoxShadow.lerpList(null, kBorderedBox.boxShadow, 0.5));
      });

      test('are interpolated with gradients', () {
        final BoxDecoration result =
            lerpAt(kBorderedBox, kShadowedLinearBox, 0.5) as BoxDecoration;
        expect(
            result.border,
            BoxBorder.lerp(
                kBorderedBox.border, kShadowedLinearBox.border, 0.5));
        expect(
            result.borderRadius,
            BorderRadius.lerp(
                BorderRadius.circular(8), BorderRadius.circular(12), 0.5));
        expect(result.boxShadow, hasLength(2));
        expect(
          result.boxShadow,
          BoxShadow.lerpList(
              kBorderedBox.boxShadow, kShadowedLinearBox.boxShadow, 0.5),
        );
      });

      test('are interpolated with images', () {
        final BoxDecorationMix result =
            lerpAt(kShadowedLinearBox, kRedImageBox, 0.25) as BoxDecorationMix;
        expect(result.border,
            BoxBorder.lerp(kShadowedLinearBox.border, null, 0.25));
        expect(result.borderRadius,
            BorderRadius.lerp(BorderRadius.circular(12), null, 0.25));
        expect(result.boxShadow,
            BoxShadow.lerpList(kShadowedLinearBox.boxShadow, null, 0.25));
      });
    });

    group('shape', () {
      test('switches half way', () {
        expect((lerpAt(kCircleBox, kRedBox, 0.4) as BoxDecoration).shape,
            BoxShape.circle);
        expect((lerpAt(kCircleBox, kRedBox, 0.6) as BoxDecoration).shape,
            BoxShape.rectangle);
        expect(
            (lerpAt(kCircleBox, kRedImageBox, 0.4) as BoxDecorationMix).shape,
            BoxShape.circle);
        expect(
            (lerpAt(kCircleBox, kRedImageBox, 0.6) as BoxDecorationMix).shape,
            BoxShape.rectangle);
      });

      test('never produces a circle with a border radius', () {
        for (final BoxDecoration target in <BoxDecoration>[
          kBorderedBox,
          kShadowedLinearBox,
          kBorderedBox.copyWith(image: kRedDecorationImage),
        ]) {
          for (final double t in <double>[0.1, 0.4, 0.6, 0.9]) {
            for (final Decoration result in <Decoration>[
              lerpAt(kCircleBox, target, t),
              lerpAt(target, kCircleBox, t),
            ]) {
              expect(result.debugAssertIsValid(), isTrue);
              final BorderRadiusGeometry? radius = switch (result) {
                BoxDecoration() => result.borderRadius,
                BoxDecorationMix() => result.borderRadius,
                _ => throw StateError('unexpected $result'),
              };
              final BoxShape shape = switch (result) {
                BoxDecoration() => result.shape,
                BoxDecorationMix() => result.shape,
                _ => throw StateError('unexpected $result'),
              };
              if (shape == BoxShape.circle) {
                expect(radius, isNull);
              } else {
                expect(radius, isNotNull);
              }
            }
          }
        }
      });
    });

    group('background blend mode', () {
      const BoxDecoration multiplyBlue =
          BoxDecoration(color: kBlue, backgroundBlendMode: BlendMode.multiply);
      const BoxDecoration multiplyRed =
          BoxDecoration(color: kRed, backgroundBlendMode: BlendMode.multiply);

      test('is kept when both sides use the same blend mode', () {
        final BoxDecoration result =
            lerpAt(multiplyBlue, multiplyRed, 0.5) as BoxDecoration;
        expect(result.backgroundBlendMode, BlendMode.multiply);
      });

      test('switches half way otherwise', () {
        expect(
          (lerpAt(multiplyBlue, kLinearBox, 0.4) as BoxDecoration)
              .backgroundBlendMode,
          BlendMode.multiply,
        );
        expect(
          (lerpAt(multiplyBlue, kLinearBox, 0.6) as BoxDecoration)
              .backgroundBlendMode,
          isNull,
        );
        expect(
          (lerpAt(kRedImageBox, multiplyRed, 0.6) as BoxDecorationMix)
              .backgroundBlendMode,
          BlendMode.multiply,
        );
      });
    });

    test('custom gradient types are cross-faded', () {
      const BoxDecoration custom = BoxDecoration(
        gradient: TestGradient(colors: <Color>[kBlue, kRed]),
      );
      for (final (Decoration a, Decoration b) in <(Decoration, Decoration)>[
        (kBlueBox, custom),
        (custom, kRedBox),
        (custom, kLinearBox),
        (const BoxDecoration(), custom),
      ]) {
        final Decoration result = lerpAt(a, b, 0.5);
        // The custom gradient must not just disappear half way.
        final Gradient? g1 = result is BoxDecorationMix
            ? result.gradient1
            : (result as BoxDecoration).gradient;
        final Gradient? g2 =
            result is BoxDecorationMix ? result.gradient2 : null;
        expect(<Gradient?>[g1, g2].whereType<TestGradient>(), isNotEmpty,
            reason: '$a -> $b');
      }
    });

    group('null and non-box decorations', () {
      test('null begin scales the end', () {
        expect(lerpAt(null, kRedBox, 0.25), kRedBox.scale(0.25));
      });

      test('null end scales the begin', () {
        expect(lerpAt(kRedBox, null, 0.25), kRedBox.scale(0.75));
      });

      test('both null gives an empty BoxDecoration', () {
        expect(lerpAt(null, null, 0.5), const BoxDecoration());
      });

      test('lerpBoxDecoration handles nulls', () {
        final SmoothDecorationTween tween = SmoothDecorationTween();
        expect(tween.lerpBoxDecoration(null, null, 0.5), isNull);
        expect(tween.lerpBoxDecoration(null, kRedBox, 0.5), kRedBox.scale(0.5));
        expect(tween.lerpBoxDecoration(kRedBox, null, 0.5), kRedBox.scale(0.5));
      });

      test('ShapeDecoration is interpolated by Decoration.lerp', () {
        const ShapeDecoration shape = ShapeDecoration(
          color: kRed,
          shape: CircleBorder(),
        );
        expect(lerpAt(kBlueBox, shape, 0.5),
            Decoration.lerp(kBlueBox, shape, 0.5));
        expect(lerpAt(shape, kBlueBox, 0.5),
            Decoration.lerp(shape, kBlueBox, 0.5));
      });
    });

    group('lerpGradient', () {
      final SmoothDecorationTween tween = SmoothDecorationTween();

      test('returns null for two null gradients', () {
        expect(tween.lerpGradient(0.5, null, null, kBlue, kRed), isNull);
      });

      test('uses the colors for the missing gradient', () {
        final LinearGradient from = tween.lerpGradient(
            0.0, null, kLinear3, kBlue, kRed)! as LinearGradient;
        expect(from.colors, <Color>[kBlue, kBlue, kBlue]);
        final LinearGradient to = tween.lerpGradient(
            1.0, kLinear3, null, kBlue, kRed)! as LinearGradient;
        expect(to.colors, <Color>[kRed, kRed, kRed]);
      });

      test('lerps two gradients with Gradient.lerp', () {
        expect(tween.lerpGradient(0.5, kSweep, kSweep2, kBlue, kRed),
            Gradient.lerp(kSweep, kSweep2, 0.5));
      });
    });

    group('t outside of 0..1 (e.g. elastic curves)', () {
      test('does not throw', () {
        for (final double t in <double>[-0.3, 1.3]) {
          for (final (BoxDecoration a, BoxDecoration b)
              in <(BoxDecoration, BoxDecoration)>[
            (kBlueBox, kRedBox),
            (kBlueBox, kLinearBox),
            (kLinearBox, kSweepBox),
            (kRedImageBox, kBlueImageBox),
            (kCircleBox, kBorderedBox),
          ]) {
            expect(() => lerpAt(a, b, t), returnsNormally);
          }
        }
      });
    });
  });

  group('SmoothDecorationTween painting', () {
    // Pairs that should animate continuously: painting the tween at t = 0 and
    // t = 1 must look (almost) the same as painting it at t = 0.001 and
    // t = 0.999.
    final List<(String, Decoration, Decoration)> pairs =
        <(String, Decoration, Decoration)>[
      ('color -> color', kBlueBox, kRedBox),
      ('translucent color -> image', kTranslucentBox, kRedImageBox),
      ('color -> image', kBlueBox, kRedImageBox),
      ('image -> color', kRedImageBox, kBlueBox),
      ('image -> image', kRedImageBox, kBlueImageBox),
      ('image -> image (reverse)', kBlueImageBox, kRedImageBox),
      ('color -> linear', kBlueBox, kLinearBox),
      ('linear -> sweep', kLinearBox, kSweepBox),
      ('radial -> linear', kRadialBox, kLinear4Box),
      ('linear -> image', kLinearBox, kRedImageBox),
      ('image -> linear', kRedImageBox, kLinearBox),
      ('image + translucent color -> sweep', kBlueImageBox, kSweepBox),
      ('sweep -> image + translucent color', kSweepBox, kBlueImageBox),
      // (Shadows are kept to the same count: BoxShadow.lerpList pops new
      // shadows in at their full color, which is Flutter's behavior.)
      (
        'bordered -> shadowed linear',
        kBorderedBox,
        kShadowedLinearBox.copyWith(
          boxShadow: kShadowedLinearBox.boxShadow!.sublist(0, 1),
        ),
      ),
      ('bordered -> image', kBorderedBox, kRedImageBox),
      ('shadowed linear -> sweep', kShadowedLinearBox, kSweepBox),
      ('circle -> image', kCircleBox, kBlueImageBox),
      (
        'translucent color with gradient -> image',
        const BoxDecoration(color: kTranslucentGreen, gradient: kLinear4),
        kRedImageBox,
      ),
      (
        'translucent color with gradient -> gradient',
        const BoxDecoration(color: kTranslucentGreen, gradient: kLinear4),
        kLinearBox,
      ),
      (
        'translucent color with gradient -> sweep',
        const BoxDecoration(color: kTranslucentGreen, gradient: kLinear4),
        kSweepBox,
      ),
      (
        'custom gradient -> color',
        const BoxDecoration(
          gradient: TestGradient(colors: <Color>[kBlue, kTranslucentGreen]),
        ),
        kRedBox,
      ),
      (
        'blend mode color -> image',
        const BoxDecoration(
            color: kRed, backgroundBlendMode: BlendMode.difference),
        kBlueImageBox,
      ),
      (
        'blend mode color -> blend mode color',
        const BoxDecoration(
            color: kRed, backgroundBlendMode: BlendMode.difference),
        const BoxDecoration(
            color: kBlue, backgroundBlendMode: BlendMode.difference),
      ),
    ];

    for (final (String name, Decoration a, Decoration b) in pairs) {
      testWidgets('$name is continuous at both ends',
          (WidgetTester tester) async {
        await precacheTestImages(tester);
        final SmoothDecorationTween tween =
            SmoothDecorationTween(begin: a, end: b);
        final Pixels begin = await renderDecoration(tester, tween.transform(0));
        final Pixels afterBegin =
            await renderDecoration(tester, tween.transform(0.001));
        final Pixels middle =
            await renderDecoration(tester, tween.transform(0.5));
        final Pixels beforeEnd =
            await renderDecoration(tester, tween.transform(0.999));
        final Pixels end = await renderDecoration(tester, tween.transform(1));
        expect(begin, looksLike(afterBegin), reason: 'jump at the start');
        expect(end, looksLike(beforeEnd), reason: 'jump at the end');
        // Sanity check: something actually changes.
        expect(begin.maxDifference(end), greaterThan(10));
        expect(middle.width, begin.width);
        expect(tester.takeException(), isNull);
      });
    }

    group('from an intermediate decoration (interrupted animation)', () {
      final Decoration mix = lerpAt(kBorderedBox, kRedImageBox, 0.5);

      test('returns the exact begin and end at t = 0 and t = 1', () {
        expect(mix, isA<BoxDecorationMix>());
        final SmoothDecorationTween tween =
            SmoothDecorationTween(begin: mix, end: kCircleBox);
        expect(tween.transform(0), same(mix));
        expect(tween.transform(1), same(kCircleBox));
      });

      test('interpolates the padding', () {
        expect(mix.padding, const EdgeInsets.all(2));
        expect(
            lerpAt(mix, kCircleBox, 0.25).padding, const EdgeInsets.all(1.5));
        expect(
            lerpAt(kCircleBox, mix, 0.25).padding, const EdgeInsets.all(0.5));
      });

      test('hit tests and clips like the closest decoration', () {
        const Size size = Size(40, 40);
        const Offset corner = Offset(0.5, 0.5);
        final Decoration early = lerpAt(mix, kCircleBox, 0.25);
        final Decoration late = lerpAt(mix, kCircleBox, 0.75);
        expect(early.hitTest(size, corner), mix.hitTest(size, corner));
        expect(late.hitTest(size, corner), isFalse);
        expect(late.hitTest(size, const Offset(20, 20)), isTrue);
        const Rect rect = Rect.fromLTWH(0, 0, 40, 40);
        expect(late.getClipPath(rect, TextDirection.ltr).getBounds(), rect);
        expect(late.debugAssertIsValid(), isTrue);
        expect(late.isComplex, isTrue);
        expect(
            lerpAt(kBlueBox, lerpAt(kBlueBox, kRedImageBox, 0.5), 0.5)
                .isComplex,
            isFalse);
      });

      test('is equal for equal arguments', () {
        expect(lerpAt(mix, kCircleBox, 0.25), lerpAt(mix, kCircleBox, 0.25));
        expect(lerpAt(mix, kCircleBox, 0.25).hashCode,
            lerpAt(mix, kCircleBox, 0.25).hashCode);
        expect(
            lerpAt(mix, kCircleBox, 0.25), isNot(lerpAt(mix, kCircleBox, 0.5)));
      });

      for (final (String name, Decoration end) in <(String, Decoration)>[
        ('color', kCircleBox),
        ('image', kBlueImageBox),
        ('gradient', kSweepBox),
        ('an intermediate decoration', lerpAt(kSweepBox, kBlueImageBox, 0.3)),
      ]) {
        testWidgets('paints continuously to $name',
            (WidgetTester tester) async {
          await precacheTestImages(tester);
          final SmoothDecorationTween tween =
              SmoothDecorationTween(begin: mix, end: end);
          expect(
            await renderDecoration(tester, tween.transform(0.001)),
            looksLike(await renderDecoration(tester, mix)),
          );
          expect(
            await renderDecoration(tester, tween.transform(0.999)),
            looksLike(await renderDecoration(tester, end)),
          );
          expect(
            await renderDecoration(tester, tween.transform(0.5)),
            isNot(looksLike(await renderDecoration(tester, end))),
          );
          expect(tester.takeException(), isNull);
        });
      }
    });

    testWidgets('image to image paints the expected colors',
        (WidgetTester tester) async {
      await precacheTestImages(tester);
      final BoxDecoration blue = BoxDecoration(
          image: DecorationImage(image: kBlueImage, fit: BoxFit.fill));
      final SmoothDecorationTween tween =
          SmoothDecorationTween(begin: kRedImageBox, end: blue);
      final Pixels pixels =
          await renderDecoration(tester, tween.transform(0.5));
      // The first image stays opaque, the second one fades in on top of it.
      expect(pixels.at(30, 30),
          matchesColor(const Color(0xFF800080), tolerance: 3));
      // Outside of the decoration.
      expect(pixels.at(2, 2), matchesColor(const Color(0xFFFFFFFF)));
    });

    testWidgets('color to image paints the expected colors',
        (WidgetTester tester) async {
      await precacheTestImages(tester);
      final SmoothDecorationTween tween = SmoothDecorationTween(
        begin: const BoxDecoration(color: Color(0xFF0000FF)),
        end: kRedImageBox,
      );
      final Pixels pixels =
          await renderDecoration(tester, tween.transform(0.5));
      // Blue at 50% over white, then red at 50% on top.
      expect(pixels.at(30, 30),
          matchesColor(const Color(0xFFBF4080), tolerance: 3));
    });
  });
}
