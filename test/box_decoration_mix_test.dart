import 'package:animated_box_decoration/src/box_decoration_mix.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

const Color kBlue = Color(0xFF2196F3);
const Color kRed = Color(0xFFF44336);
const LinearGradient kLinear = LinearGradient(
  colors: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
);
const SweepGradient kSweep = SweepGradient(
  colors: <Color>[Color(0xFFFF0000), Color(0xFF00FF00)],
);

/// The recorded calls of [canvas] with the given [name].
List<Invocation> callsNamed(TestRecordingCanvas canvas, Symbol name) =>
    canvas.invocations
        .map((RecordedInvocation r) => r.invocation)
        .where((Invocation i) => i.memberName == name)
        .toList();

/// The paints used by all drawRect/drawRRect/drawCircle calls of [canvas].
List<Paint> shapePaints(TestRecordingCanvas canvas) => canvas.invocations
    .map((RecordedInvocation r) => r.invocation)
    .where((Invocation i) => const <Symbol>{#drawRect, #drawRRect, #drawCircle}
        .contains(i.memberName))
    .map((Invocation i) => i.positionalArguments.last as Paint)
    .toList();

TestRecordingCanvas paintDecoration(
  Decoration decoration, {
  Size size = const Size(100, 50),
  TextDirection textDirection = TextDirection.ltr,
}) {
  final TestRecordingCanvas canvas = TestRecordingCanvas();
  final BoxPainter painter = decoration.createBoxPainter(() {});
  painter.paint(
    canvas,
    Offset.zero,
    ImageConfiguration(size: size, textDirection: textDirection),
  );
  painter.dispose();
  return canvas;
}

void main() {
  group('BoxDecorationMix', () {
    test('padding comes from the border', () {
      expect(const BoxDecorationMix().padding, EdgeInsets.zero);
      expect(
        BoxDecorationMix(border: Border.all(width: 3)).padding,
        const EdgeInsets.all(3),
      );
      expect(
        const BoxDecorationMix(
          border: BorderDirectional(start: BorderSide(width: 5)),
        ).padding,
        const EdgeInsetsDirectional.only(start: 5),
      );
    });

    group('hitTest', () {
      const Size size = Size(100, 50);

      test('rectangle hits everywhere', () {
        const BoxDecorationMix decoration = BoxDecorationMix(color: kBlue);
        expect(decoration.hitTest(size, Offset.zero), isTrue);
        expect(decoration.hitTest(size, const Offset(99.9, 49.9)), isTrue);
        expect(decoration.hitTest(size, const Offset(50, 25)), isTrue);
      });

      test('rounded rectangle misses the corners', () {
        final BoxDecorationMix decoration =
            BoxDecorationMix(borderRadius: BorderRadius.circular(20));
        expect(decoration.hitTest(size, const Offset(1, 1)), isFalse);
        expect(decoration.hitTest(size, const Offset(99, 49)), isFalse);
        expect(decoration.hitTest(size, const Offset(50, 1)), isTrue);
        expect(decoration.hitTest(size, const Offset(50, 25)), isTrue);
      });

      test('directional border radius uses the text direction', () {
        const BoxDecorationMix decoration = BoxDecorationMix(
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
          ),
        );
        expect(
          decoration.hitTest(size, const Offset(1, 1),
              textDirection: TextDirection.ltr),
          isFalse,
        );
        expect(
          decoration.hitTest(size, const Offset(99, 1),
              textDirection: TextDirection.ltr),
          isTrue,
        );
        expect(
          decoration.hitTest(size, const Offset(1, 1),
              textDirection: TextDirection.rtl),
          isTrue,
        );
        expect(
          decoration.hitTest(size, const Offset(99, 1),
              textDirection: TextDirection.rtl),
          isFalse,
        );
      });

      test('circle is inscribed in the shortest side', () {
        const BoxDecorationMix decoration =
            BoxDecorationMix(shape: BoxShape.circle);
        expect(decoration.hitTest(size, const Offset(50, 25)), isTrue);
        expect(decoration.hitTest(size, const Offset(50, 1)), isTrue);
        expect(decoration.hitTest(size, const Offset(74, 25)), isTrue);
        expect(decoration.hitTest(size, const Offset(76, 25)), isFalse);
        expect(decoration.hitTest(size, const Offset(1, 1)), isFalse);
      });
    });

    group('getClipPath', () {
      const Rect rect = Rect.fromLTWH(10, 10, 100, 50);

      test('rectangle', () {
        final Path path =
            const BoxDecorationMix().getClipPath(rect, TextDirection.ltr);
        expect(path.getBounds(), rect);
        expect(path.contains(const Offset(11, 11)), isTrue);
      });

      test('rounded rectangle', () {
        final Path path = BoxDecorationMix(
          borderRadius: BorderRadius.circular(20),
        ).getClipPath(rect, TextDirection.ltr);
        expect(path.getBounds(), rect);
        expect(path.contains(const Offset(11, 11)), isFalse);
        expect(path.contains(const Offset(60, 35)), isTrue);
      });

      test('circle', () {
        final Path path = const BoxDecorationMix(shape: BoxShape.circle)
            .getClipPath(rect, TextDirection.ltr);
        expect(
            path.getBounds(), Rect.fromCircle(center: rect.center, radius: 25));
      });
    });

    test('isComplex when there are shadows', () {
      expect(const BoxDecorationMix().isComplex, isFalse);
      expect(
        const BoxDecorationMix(boxShadow: <BoxShadow>[BoxShadow()]).isComplex,
        isTrue,
      );
    });

    group('equality', () {
      final DecorationImage image1 =
          DecorationImage(image: kRedImage, opacity: 0.5);
      final DecorationImage image2 = DecorationImage(image: kBlueImage);
      BoxDecorationMix create() => BoxDecorationMix(
            color: kBlue,
            image1: image1,
            image2: image2,
            border: Border.all(width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 3)],
            gradient1: kLinear,
            gradient2: kSweep,
            backgroundBlendMode: BlendMode.multiply,
          );

      test('equal fields are equal', () {
        expect(create(), create());
        expect(create().hashCode, create().hashCode);
      });

      test('every field matters', () {
        final BoxDecorationMix base = create();
        final List<BoxDecorationMix> variants = <BoxDecorationMix>[
          base.copyWith(color: kRed),
          base.copyWith(image1: image2),
          base.copyWith(image2: image1),
          base.copyWith(border: Border.all(width: 3)),
          base.copyWith(borderRadius: BorderRadius.circular(5)),
          base.copyWith(boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 4)]),
          base.copyWith(gradient1: kSweep),
          base.copyWith(gradient2: kLinear),
          base.copyWith(backgroundBlendMode: BlendMode.screen),
          base.copyWith(shape: BoxShape.circle),
        ];
        for (final BoxDecorationMix variant in variants) {
          expect(variant, isNot(base));
        }
      });

      test('copyWith without arguments returns an equal decoration', () {
        expect(create().copyWith(), create());
      });

      test('copyWith replaces the given fields', () {
        final BoxDecorationMix copy = create().copyWith(
          color: kRed,
          gradient2: kLinear,
          shape: BoxShape.circle,
        );
        expect(copy.color, kRed);
        expect(copy.gradient1, kLinear);
        expect(copy.gradient2, kLinear);
        expect(copy.shape, BoxShape.circle);
        expect(copy.image1, image1);
        expect(copy.backgroundBlendMode, BlendMode.multiply);
      });
    });

    group('asserts', () {
      test('a circle cannot have a border radius', () {
        expect(
          () => BoxDecorationMix(
            shape: BoxShape.circle,
            borderRadius: BorderRadius.circular(3),
          ).debugAssertIsValid(),
          throwsAssertionError,
        );
        expect(
          const BoxDecorationMix(shape: BoxShape.circle).debugAssertIsValid(),
          isTrue,
        );
      });

      test('backgroundBlendMode needs a color or a gradient', () {
        expect(
          () => BoxDecorationMix(backgroundBlendMode: BlendMode.multiply),
          throwsAssertionError,
        );
        expect(
          () => BoxDecorationMix(
              gradient2: kLinear, backgroundBlendMode: BlendMode.multiply),
          returnsNormally,
        );
      });

      test('a painter for images needs an onChanged callback', () {
        final DecorationImage image = DecorationImage(image: kRedImage);
        expect(const BoxDecorationMix(color: kBlue).createBoxPainter(),
            isA<BoxPainter>());
        expect(() => BoxDecorationMix(image1: image).createBoxPainter(),
            throwsAssertionError);
        expect(() => BoxDecorationMix(image2: image).createBoxPainter(),
            throwsAssertionError);
        expect(
          () =>
              BoxDecorationMix(image1: image, image2: image).createBoxPainter(),
          throwsAssertionError,
        );
        expect(
          BoxDecorationMix(image1: image, image2: image)
              .createBoxPainter(() {}),
          isA<BoxPainter>(),
        );
      });
    });

    group('painting', () {
      test('paints the color exactly once', () {
        final TestRecordingCanvas canvas =
            paintDecoration(const BoxDecorationMix(color: Color(0x80FF0000)));
        final List<Paint> paints = shapePaints(canvas);
        expect(paints, hasLength(1));
        expect(paints.single.color, matchesColor(const Color(0x80FF0000)));
        expect(paints.single.shader, isNull);
      });

      test('paints the color below the two gradients', () {
        final TestRecordingCanvas canvas = paintDecoration(
          const BoxDecorationMix(
            color: Color(0x80FF0000),
            gradient1: kLinear,
            gradient2: kSweep,
          ),
        );
        final List<Paint> paints = shapePaints(canvas);
        expect(paints, hasLength(3));
        expect(paints[0].color, matchesColor(const Color(0x80FF0000)));
        expect(paints[0].shader, isNull);
        // The gradients are not modulated by the (unrelated) color.
        expect(paints[1].shader, isNotNull);
        expect(paints[1].color.a, 1.0);
        expect(paints[2].shader, isNotNull);
        expect(paints[2].color.a, 1.0);
        expect(paints[1].shader, isNot(same(paints[2].shader)));
      });

      test('paints only the gradients that are present', () {
        expect(
            shapePaints(
                paintDecoration(const BoxDecorationMix(gradient1: kLinear))),
            hasLength(1));
        expect(
            shapePaints(
                paintDecoration(const BoxDecorationMix(gradient2: kSweep))),
            hasLength(1));
        expect(shapePaints(paintDecoration(const BoxDecorationMix())), isEmpty);
      });

      test('uses the background blend mode for every background layer', () {
        final TestRecordingCanvas canvas = paintDecoration(
          const BoxDecorationMix(
            color: kRed,
            gradient1: kLinear,
            gradient2: kSweep,
            backgroundBlendMode: BlendMode.multiply,
          ),
        );
        final List<Paint> paints = shapePaints(canvas);
        expect(paints, hasLength(3));
        for (final Paint paint in paints) {
          expect(paint.blendMode, BlendMode.multiply);
        }
      });

      test('paints shadows, then the background, then the border', () {
        final TestRecordingCanvas canvas = paintDecoration(
          BoxDecorationMix(
            color: kRed,
            border: Border.all(width: 2, color: const Color(0xFF000000)),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0xFF00FF00), offset: Offset(3, 4)),
            ],
          ),
        );
        final List<Invocation> calls = canvas.invocations
            .map((RecordedInvocation r) => r.invocation)
            .toList();
        final int shadow = calls.indexWhere((Invocation i) =>
            i.memberName == #drawRect &&
            i.positionalArguments[0] == const Rect.fromLTWH(3, 4, 100, 50));
        final int background = calls.indexWhere((Invocation i) =>
            i.memberName == #drawRect &&
            (i.positionalArguments[1] as Paint).color.toARGB32() ==
                kRed.toARGB32());
        expect(shadow, isNot(-1));
        expect(background, greaterThan(shadow));
        // The border is painted last.
        expect(calls.length, greaterThan(background + 1));
      });

      test('paints rounded rectangles and circles', () {
        expect(
          callsNamed(
            paintDecoration(BoxDecorationMix(
              color: kRed,
              borderRadius: BorderRadius.circular(10),
            )),
            #drawRRect,
          ),
          hasLength(1),
        );
        final List<Invocation> circles = callsNamed(
          paintDecoration(
              const BoxDecorationMix(color: kRed, shape: BoxShape.circle)),
          #drawCircle,
        );
        expect(circles, hasLength(1));
        expect(circles.single.positionalArguments[0], const Offset(50, 25));
        expect(circles.single.positionalArguments[1], 25);
      });

      testWidgets('cross-fades two images', (WidgetTester tester) async {
        await precacheTestImages(tester);
        final Pixels pixels = await renderDecoration(
          tester,
          BoxDecorationMix(
            image1: DecorationImage(
                image: kRedImage, fit: BoxFit.fill, opacity: 0.25),
            image2: DecorationImage(
                image: kBlueImage, fit: BoxFit.fill, opacity: 0.75),
          ),
        );
        expect(pixels.at(30, 30),
            matchesColor(const Color(0xFF4000BF), tolerance: 3));
        expect(tester.takeException(), isNull);
      });

      testWidgets('cross-fades two images that do not cover the box',
          (WidgetTester tester) async {
        await precacheTestImages(tester);
        // The first image covers the box, the second one only its center.
        final Pixels pixels = await renderDecoration(
          tester,
          BoxDecorationMix(
            image1: DecorationImage(
                image: kRedImage, fit: BoxFit.fill, opacity: 0.25),
            image2: DecorationImage(
                image: kBlueImage, fit: BoxFit.none, scale: 0.2, opacity: 0.75),
          ),
        );
        // Center: both images.
        expect(pixels.at(30, 30),
            matchesColor(const Color(0xFF4000BF), tolerance: 3));
        // Corner: only the first image, over white.
        expect(pixels.at(12, 12),
            matchesColor(const Color(0xFFFFBFBF), tolerance: 3));
      });

      testWidgets('paints a single image with its opacity',
          (WidgetTester tester) async {
        await precacheTestImages(tester);
        for (final BoxDecorationMix decoration in <BoxDecorationMix>[
          BoxDecorationMix(
            image1: DecorationImage(
                image: kRedImage, fit: BoxFit.fill, opacity: 0.5),
          ),
          BoxDecorationMix(
            image2: DecorationImage(
                image: kRedImage, fit: BoxFit.fill, opacity: 0.5),
          ),
        ]) {
          final Pixels pixels = await renderDecoration(tester, decoration);
          expect(pixels.at(30, 30),
              matchesColor(const Color(0xFFFF8080), tolerance: 3));
        }
      });

      testWidgets('clips images to the shape', (WidgetTester tester) async {
        await precacheTestImages(tester);
        final Pixels pixels = await renderDecoration(
          tester,
          BoxDecorationMix(
            shape: BoxShape.circle,
            image1: DecorationImage(image: kRedImage, fit: BoxFit.fill),
            image2: DecorationImage(
                image: kBlueImage, fit: BoxFit.fill, opacity: 0.0),
          ),
        );
        expect(pixels.at(30, 30), matchesColor(const Color(0xFFFF0000)));
        // Corner of the box, outside of the circle.
        expect(pixels.at(11, 11), matchesColor(const Color(0xFFFFFFFF)));
      });

      testWidgets('matches BoxDecoration under an opaque border',
          (WidgetTester tester) async {
        // The background must not leak around the anti-aliased corners of an
        // opaque border, exactly like BoxDecoration.
        final BoxBorder border =
            Border.all(width: 4, color: const Color(0xFF000000));
        final BorderRadius radius = BorderRadius.circular(8);
        final Pixels box = await renderDecoration(
          tester,
          BoxDecoration(color: kRed, border: border, borderRadius: radius),
        );
        final Pixels mix = await renderDecoration(
          tester,
          BoxDecorationMix(color: kRed, border: border, borderRadius: radius),
        );
        expect(box.maxDifference(mix), lessThanOrEqualTo(1));
      });
    });
  });
}
