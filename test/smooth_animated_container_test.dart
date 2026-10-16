import 'package:animated_box_decoration/animated_box_decoration.dart';
import 'package:animated_box_decoration/src/box_decoration_mix.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

const Duration kDuration = Duration(milliseconds: 200);
const Color kBlue = Color(0xFF0000FF);
const Color kRed = Color(0xFFFF0000);

const BoxDecoration kBlueBox = BoxDecoration(color: kBlue);
const BoxDecoration kRedBox = BoxDecoration(color: kRed);
const BoxDecoration kLinearBox = BoxDecoration(
  gradient: LinearGradient(colors: <Color>[Color(0xFF000000), kBlue]),
);
const BoxDecoration kSweepBox = BoxDecoration(
  gradient: SweepGradient(colors: <Color>[kRed, Color(0xFF00FF00), kRed]),
);
final BoxDecoration kRedImageBox = BoxDecoration(
  image: DecorationImage(image: kRedImage, fit: BoxFit.fill),
);
final BoxDecoration kBlueImageBox = BoxDecoration(
  image: DecorationImage(image: kBlueImage, fit: BoxFit.fill),
);

/// The decoration currently painted by the (first) [SmoothAnimatedContainer].
Decoration? paintedDecoration(WidgetTester tester,
    {DecorationPosition position = DecorationPosition.background}) {
  final Iterable<RenderDecoratedBox> boxes = tester
      .renderObjectList<RenderDecoratedBox>(find.descendant(
        of: find.byType(SmoothAnimatedContainer),
        matching: find.byType(DecoratedBox),
      ))
      .where((RenderDecoratedBox box) => box.position == position);
  return boxes.isEmpty ? null : boxes.first.decoration;
}

Widget wrap(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    );

void main() {
  group('SmoothAnimatedContainer', () {
    testWidgets('builds a Container with the given properties',
        (WidgetTester tester) async {
      final Matrix4 transform = Matrix4.rotationZ(0.1);
      await tester.pumpWidget(wrap(
        SmoothAnimatedContainer(
          duration: kDuration,
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.all(3),
          decoration: kBlueBox,
          foregroundDecoration: kRedBox,
          width: 50,
          height: 40,
          margin: const EdgeInsets.all(5),
          transform: transform,
          transformAlignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          child: const SizedBox(width: 10, height: 10),
        ),
      ));
      final Container container = tester.widget(find.byType(Container));
      expect(container.alignment, Alignment.bottomRight);
      expect(container.padding, const EdgeInsets.all(3));
      expect(container.decoration, kBlueBox);
      expect(container.foregroundDecoration, kRedBox);
      expect(container.constraints,
          const BoxConstraints.tightFor(width: 50, height: 40));
      expect(container.margin, const EdgeInsets.all(5));
      expect(container.transform, transform);
      expect(container.transformAlignment, Alignment.center);
      expect(container.clipBehavior, Clip.hardEdge);
      expect(tester.getSize(find.byType(SmoothAnimatedContainer)),
          const Size(60, 50));
    });

    testWidgets('color is a shorthand for a BoxDecoration',
        (WidgetTester tester) async {
      final SmoothAnimatedContainer widget =
          SmoothAnimatedContainer(duration: kDuration, color: kRed);
      expect(widget.decoration, kRedBox);
      expect(
        () => SmoothAnimatedContainer(
            duration: kDuration, color: kRed, decoration: kBlueBox),
        throwsAssertionError,
      );
    });

    testWidgets('width and height tighten the constraints',
        (WidgetTester tester) async {
      final SmoothAnimatedContainer widget = SmoothAnimatedContainer(
        duration: kDuration,
        width: 10,
        constraints: const BoxConstraints(maxHeight: 20),
      );
      expect(widget.constraints,
          const BoxConstraints(minWidth: 10, maxWidth: 10, maxHeight: 20));
    });

    testWidgets('exposes its properties for diagnostics',
        (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      SmoothAnimatedContainer(
        duration: kDuration,
        decoration: kBlueBox,
        clipBehavior: Clip.antiAlias,
      ).debugFillProperties(builder);
      final Map<String, Object?> properties = <String, Object?>{
        for (final DiagnosticsNode node in builder.properties)
          node.name ?? '': node.value,
      };
      expect(properties['bg'], kBlueBox);
      expect(properties['clipBehavior'], Clip.antiAlias);
      expect(properties['duration'], kDuration.inMilliseconds);
    });

    testWidgets('animates between two colors and ends at the target',
        (WidgetTester tester) async {
      int ends = 0;
      Widget build(Decoration decoration) => wrap(SmoothAnimatedContainer(
            duration: kDuration,
            width: 40,
            height: 40,
            decoration: decoration,
            onEnd: () => ends++,
          ));

      await tester.pumpWidget(build(kBlueBox));
      expect(paintedDecoration(tester), kBlueBox);

      await tester.pumpWidget(build(kRedBox));
      expect(paintedDecoration(tester), kBlueBox);
      await tester.pump(kDuration ~/ 2);
      final BoxDecoration middle = paintedDecoration(tester)! as BoxDecoration;
      expect(middle.color, Color.lerp(kBlue, kRed, 0.5));
      await tester.pump(kDuration ~/ 2);
      expect(paintedDecoration(tester), kRedBox);
      await tester.pumpAndSettle();
      expect(ends, 1);
      await tester.pump(kDuration);
      expect(ends, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the curve', (WidgetTester tester) async {
      Widget build(Decoration decoration) => wrap(SmoothAnimatedContainer(
            duration: kDuration,
            curve: Curves.easeIn,
            decoration: decoration,
            width: 10,
            height: 10,
          ));
      await tester.pumpWidget(build(kBlueBox));
      await tester.pumpWidget(build(kRedBox));
      await tester.pump(kDuration ~/ 2);
      final BoxDecoration middle = paintedDecoration(tester)! as BoxDecoration;
      expect(
          middle.color, Color.lerp(kBlue, kRed, Curves.easeIn.transform(0.5)));
    });

    testWidgets('animates the foreground decoration too',
        (WidgetTester tester) async {
      Widget build(Decoration decoration) => wrap(SmoothAnimatedContainer(
            duration: kDuration,
            width: 40,
            height: 40,
            foregroundDecoration: decoration,
          ));
      await precacheTestImages(tester);
      await tester.pumpWidget(build(kLinearBox));
      await tester.pumpWidget(build(kRedImageBox));
      await tester.pump(kDuration ~/ 2);
      expect(
        paintedDecoration(tester, position: DecorationPosition.foreground),
        isA<BoxDecorationMix>(),
      );
      await tester.pump(kDuration ~/ 2);
      expect(
        paintedDecoration(tester, position: DecorationPosition.foreground),
        kRedImageBox,
      );
    });

    for (final (String name, Decoration from, Decoration to)
        in <(String, Decoration, Decoration)>[
      ('color to gradient', kBlueBox, kLinearBox),
      ('gradient to gradient', kLinearBox, kSweepBox),
      ('gradient to image', kLinearBox, kRedImageBox),
      ('image to image', kRedImageBox, kBlueImageBox),
      ('image to color', kBlueImageBox, kRedBox),
    ]) {
      testWidgets('animates $name smoothly', (WidgetTester tester) async {
        await precacheTestImages(tester);
        final GlobalKey key = GlobalKey();
        Widget build(Decoration decoration) => wrap(RepaintBoundary(
              key: key,
              child: SmoothAnimatedContainer(
                duration: kDuration,
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: decoration,
              ),
            ));

        await tester.pumpWidget(build(from));
        final Pixels start = await capturePixels(tester, key);
        await tester.pumpWidget(build(to));
        Pixels previous = await capturePixels(tester, key);
        expect(previous.maxDifference(start), lessThanOrEqualTo(3));
        int largestStep = 0;
        for (int i = 0; i < 10; i++) {
          await tester.pump(kDuration ~/ 10);
          final Pixels current = await capturePixels(tester, key);
          final int step = current.maxDifference(previous);
          if (step > largestStep) largestStep = step;
          previous = current;
        }
        expect(paintedDecoration(tester), to);
        final GlobalKey endKey = GlobalKey();
        await tester.pumpWidget(wrap(RepaintBoundary(
          key: endKey,
          child: SizedBox(
            width: 40,
            height: 40,
            child: DecoratedBox(decoration: to),
          ),
        )));
        final Pixels end = await capturePixels(tester, endKey);
        expect(previous.maxDifference(end), lessThanOrEqualTo(3));
        expect(largestStep, lessThan(80));
        expect(tester.takeException(), isNull);
      });

      testWidgets('animates $name smoothly when interrupted',
          (WidgetTester tester) async {
        await precacheTestImages(tester);
        final GlobalKey key = GlobalKey();
        Widget build(Decoration decoration) => wrap(RepaintBoundary(
              key: key,
              child: SmoothAnimatedContainer(
                duration: kDuration,
                width: 40,
                height: 40,
                decoration: decoration,
              ),
            ));

        await tester.pumpWidget(build(from));
        await tester.pumpWidget(build(to));
        await tester.pump(kDuration * 0.4);
        Pixels previous = await capturePixels(tester, key);
        // Go back before the first animation is done.
        await tester.pumpWidget(build(from));
        final Pixels afterInterruption = await capturePixels(tester, key);
        expect(afterInterruption.maxDifference(previous), lessThanOrEqualTo(3));
        int largestStep = 0;
        for (int i = 0; i < 10; i++) {
          await tester.pump(kDuration ~/ 10);
          final Pixels current = await capturePixels(tester, key);
          final int step = current.maxDifference(previous);
          if (step > largestStep) largestStep = step;
          previous = current;
        }
        expect(paintedDecoration(tester), from);
        expect(largestStep, lessThan(80));
        // And once more, while the second animation is running.
        await tester.pumpWidget(build(to));
        await tester.pump(kDuration * 0.3);
        await tester.pumpWidget(build(from));
        await tester.pump(kDuration * 0.3);
        await tester.pumpWidget(build(to));
        await tester.pumpAndSettle();
        expect(paintedDecoration(tester), to);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('animates between a circle and a rounded rectangle',
        (WidgetTester tester) async {
      await precacheTestImages(tester);
      final BoxDecoration rounded = BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 2),
      );
      const BoxDecoration circle =
          BoxDecoration(color: kBlue, shape: BoxShape.circle);
      for (final (Decoration from, Decoration to) in <(Decoration, Decoration)>[
        (circle, rounded),
        (rounded, circle),
        (circle, rounded.copyWith(image: kRedImageBox.image)),
        (rounded.copyWith(image: kRedImageBox.image), circle),
      ]) {
        Widget build(Decoration decoration) => wrap(SmoothAnimatedContainer(
              duration: kDuration,
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: decoration,
            ));
        await tester.pumpWidget(build(from));
        await tester.pumpWidget(build(to));
        for (int i = 0; i < 5; i++) {
          await tester.pump(kDuration ~/ 5);
          expect(tester.takeException(), isNull);
        }
        expect(paintedDecoration(tester), to);
      }
    });

    testWidgets('works with overshooting curves', (WidgetTester tester) async {
      await precacheTestImages(tester);
      final BoxDecoration shadowed = BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const <BoxShadow>[
          BoxShadow(blurRadius: 4, color: Color(0x80000000)),
        ],
      );
      for (final (Decoration from, Decoration to) in <(Decoration, Decoration)>[
        (kBlueBox, shadowed),
        (shadowed, kBlueBox),
        (kRedImageBox, kBlueImageBox),
        (kLinearBox, kSweepBox),
        (kLinearBox, kRedImageBox),
      ]) {
        for (final Curve curve in <Curve>[
          Curves.elasticInOut,
          Curves.easeInOutBack,
        ]) {
          Widget build(Decoration decoration) => wrap(SmoothAnimatedContainer(
                duration: kDuration,
                curve: curve,
                width: 40,
                height: 40,
                decoration: decoration,
              ));
          await tester.pumpWidget(build(from));
          await tester.pumpWidget(build(to));
          for (int i = 0; i < 20; i++) {
            await tester.pump(kDuration ~/ 20);
            expect(tester.takeException(), isNull);
          }
          expect(paintedDecoration(tester), to);
        }
      }
    });

    testWidgets('hit tests the animated decoration',
        (WidgetTester tester) async {
      int taps = 0;
      Widget build(Decoration decoration) => wrap(GestureDetector(
            onTap: () => taps++,
            child: SmoothAnimatedContainer(
              duration: kDuration,
              width: 40,
              height: 40,
              decoration: decoration,
            ),
          ));
      await precacheTestImages(tester);
      const BoxDecoration circle =
          BoxDecoration(color: kBlue, shape: BoxShape.circle);
      await tester.pumpWidget(build(circle));
      await tester.pumpWidget(build(
          BoxDecoration(shape: BoxShape.circle, image: kRedImageBox.image)));
      await tester.pump(kDuration ~/ 4);
      expect(paintedDecoration(tester), isA<BoxDecorationMix>());
      await tester.tapAt(const Offset(2, 2));
      expect(taps, 0);
      await tester.tapAt(const Offset(20, 20));
      expect(taps, 1);
    });

    testWidgets('disposes its image painters', (WidgetTester tester) async {
      await precacheTestImages(tester);
      Widget build(Decoration decoration) => wrap(SmoothAnimatedContainer(
            duration: kDuration,
            width: 40,
            height: 40,
            decoration: decoration,
          ));
      await tester.pumpWidget(build(kRedImageBox));
      await tester.pumpWidget(build(kBlueImageBox));
      await tester.pump(kDuration ~/ 2);
      await tester.pumpWidget(const SizedBox());
      // Only the image cache still holds the images.
      expect(PaintingBinding.instance.imageCache.liveImageCount, 0);
    });
  });
}
