import 'dart:ui' as ui;

import 'package:animated_box_decoration/src/blend_decoration_image.dart';
import 'package:animated_box_decoration/src/box_decoration_mix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    hide paintImage, debugFlushLastFrameImageSizeInfo;
import 'package:flutter_test/flutter_test.dart';

/// An [ImageStreamCompleter] that is driven by the test.
class TestImageStreamCompleter extends ImageStreamCompleter {
  bool get listening => hasListeners;

  void emit(ImageInfo info) => setImage(info);
}

/// An [ImageProvider] that bypasses the image cache and hands out one
/// [TestImageStreamCompleter] per key, where the key is computed from the
/// [ImageConfiguration] by [keyOf].
class TestImageProvider extends ImageProvider<Object> {
  TestImageProvider({Object Function(ImageConfiguration)? keyOf})
      : keyOf = keyOf ?? ((_) => 'key');

  final Object Function(ImageConfiguration) keyOf;
  final Map<Object, TestImageStreamCompleter> completers =
      <Object, TestImageStreamCompleter>{};

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<Object>(keyOf(configuration));

  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    Object key,
    ImageErrorListener handleError,
  ) {
    stream.setCompleter(
        completers.putIfAbsent(key, TestImageStreamCompleter.new));
  }
}

ui.Image createSolidImage(int width, int height) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

int openHandles(ui.Image image) =>
    image.debugGetOpenHandleStackTraces()?.length ?? 0;

List<Invocation> calls(TestRecordingCanvas canvas) =>
    canvas.invocations.map((RecordedInvocation r) => r.invocation).toList();

const ImageConfiguration kConfiguration = ImageConfiguration(
  size: Size(20, 30),
  textDirection: TextDirection.ltr,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BlendDecorationImagePainter', () {
    late ui.Image image;

    setUp(() {
      image = createSolidImage(4, 4);
    });

    tearDown(() {
      image.dispose();
    });

    test('paints once the image arrives, with the blend mode', () {
      final TestImageProvider provider = TestImageProvider();
      int changes = 0;
      final BlendDecorationImagePainter painter = BlendDecorationImagePainter(
        DecorationImage(image: provider, fit: BoxFit.fill, opacity: 0.5),
        () => changes++,
      );
      const Rect rect = Rect.fromLTWH(1, 2, 20, 30);

      TestRecordingCanvas canvas = TestRecordingCanvas();
      painter.paint(canvas, rect, null, kConfiguration, BlendMode.plus);
      expect(calls(canvas), isEmpty);
      final TestImageStreamCompleter completer = provider.completers['key']!;
      expect(completer.listening, isTrue);

      completer.emit(ImageInfo(image: image.clone()));
      expect(changes, 1);

      canvas = TestRecordingCanvas();
      painter.paint(canvas, rect, null, kConfiguration, BlendMode.plus);
      final List<Invocation> drawn = calls(canvas)
          .where((Invocation i) => i.memberName == #drawImageRect)
          .toList();
      expect(drawn, hasLength(1));
      expect(drawn.single.positionalArguments[2], rect);
      final Paint paint = drawn.single.positionalArguments[3] as Paint;
      expect(paint.blendMode, BlendMode.plus);
      expect(paint.color.a, closeTo(0.5, 0.01));

      painter.dispose();
      expect(completer.listening, isFalse);
    });

    test('disposes the image it holds', () {
      final TestImageProvider provider = TestImageProvider();
      final BlendDecorationImagePainter painter = BlendDecorationImagePainter(
        DecorationImage(image: provider),
        () {},
      );
      painter.paint(TestRecordingCanvas(), Rect.zero, null, kConfiguration,
          BlendMode.srcOver);
      final TestImageStreamCompleter completer = provider.completers['key']!;
      expect(openHandles(image), 1);
      completer.emit(ImageInfo(image: image.clone()));
      // Ours, the completer's and the painter's.
      expect(openHandles(image), 3);
      painter.dispose();
      // The completer has no listener anymore and disposed its image too.
      expect(completer.listening, isFalse);
      expect(openHandles(image), 1);
    });

    test('ignores clones of the image it already has', () {
      final TestImageProvider provider = TestImageProvider();
      int changes = 0;
      final BlendDecorationImagePainter painter = BlendDecorationImagePainter(
        DecorationImage(image: provider),
        () => changes++,
      );
      painter.paint(TestRecordingCanvas(), Rect.zero, null, kConfiguration,
          BlendMode.srcOver);
      final TestImageStreamCompleter completer = provider.completers['key']!;
      completer.emit(ImageInfo(image: image.clone()));
      completer.emit(ImageInfo(image: image.clone()));
      expect(changes, 1);
      painter.dispose();
      expect(openHandles(image), 1);
    });

    test('moves its listener when the image stream changes', () {
      final TestImageProvider provider = TestImageProvider(
        keyOf: (ImageConfiguration configuration) => configuration.size!,
      );
      final BlendDecorationImagePainter painter = BlendDecorationImagePainter(
        DecorationImage(image: provider),
        () {},
      );
      const ImageConfiguration small = ImageConfiguration(size: Size(1, 1));
      const ImageConfiguration large = ImageConfiguration(size: Size(2, 2));
      painter.paint(
          TestRecordingCanvas(), Rect.zero, null, small, BlendMode.srcOver);
      expect(provider.completers[const Size(1, 1)]!.listening, isTrue);
      painter.paint(
          TestRecordingCanvas(), Rect.zero, null, large, BlendMode.srcOver);
      expect(provider.completers[const Size(1, 1)]!.listening, isFalse);
      expect(provider.completers[const Size(2, 2)]!.listening, isTrue);
      painter.dispose();
      expect(provider.completers[const Size(2, 2)]!.listening, isFalse);
    });

    test('clips to the clip path', () {
      final TestImageProvider provider = TestImageProvider();
      final BlendDecorationImagePainter painter = BlendDecorationImagePainter(
        DecorationImage(image: provider),
        () {},
      );
      painter.paint(TestRecordingCanvas(), Rect.zero, null, kConfiguration,
          BlendMode.srcOver);
      provider.completers['key']!.emit(ImageInfo(image: image.clone()));
      final TestRecordingCanvas canvas = TestRecordingCanvas();
      final int saveCount = canvas.getSaveCount();
      final Path clip = Path()..addOval(const Rect.fromLTWH(0, 0, 20, 30));
      painter.paint(canvas, const Rect.fromLTWH(0, 0, 20, 30), clip,
          kConfiguration, BlendMode.srcOver);
      expect(
        calls(canvas).map((Invocation i) => i.memberName),
        containsAllInOrder(
            <Symbol>[#save, #clipPath, #drawImageRect, #restore]),
      );
      expect(canvas.getSaveCount(), saveCount);
      painter.dispose();
    });

    test('flips the image for right-to-left text when asked to', () {
      final TestImageProvider provider = TestImageProvider();
      final BlendDecorationImagePainter painter = BlendDecorationImagePainter(
        DecorationImage(image: provider, matchTextDirection: true),
        () {},
      );
      painter.paint(TestRecordingCanvas(), Rect.zero, null, kConfiguration,
          BlendMode.srcOver);
      provider.completers['key']!.emit(ImageInfo(image: image.clone()));
      final TestRecordingCanvas canvas = TestRecordingCanvas();
      painter.paint(
        canvas,
        const Rect.fromLTWH(0, 0, 20, 30),
        null,
        const ImageConfiguration(
            size: Size(20, 30), textDirection: TextDirection.rtl),
        BlendMode.srcOver,
      );
      expect(
          calls(canvas).map((Invocation i) => i.memberName), contains(#scale));
      painter.dispose();
    });

    test('matchTextDirection needs a text direction', () {
      final BlendDecorationImagePainter painter = BlendDecorationImagePainter(
        DecorationImage(image: TestImageProvider(), matchTextDirection: true),
        () {},
      );
      expect(
        () => painter.paint(TestRecordingCanvas(), Rect.zero, null,
            ImageConfiguration.empty, BlendMode.srcOver),
        throwsFlutterError,
      );
      painter.dispose();
    });
  });

  group('paintImage', () {
    late ui.Image image;

    setUp(() {
      image = createSolidImage(10, 10);
    });

    tearDown(() {
      image.dispose();
      debugFlushLastFrameImageSizeInfo();
    });

    Paint paintWith({required double opacity, BlendMode? blendMode}) {
      final TestRecordingCanvas canvas = TestRecordingCanvas();
      paintImage(
        canvas: canvas,
        rect: const Rect.fromLTWH(0, 0, 10, 10),
        image: image,
        opacity: opacity,
        blendMode: blendMode ?? BlendMode.srcOver,
      );
      final Invocation draw = calls(canvas)
          .singleWhere((Invocation i) => i.memberName == #drawImageRect);
      return draw.positionalArguments[3] as Paint;
    }

    testWidgets('uses the blend mode', (WidgetTester tester) async {
      expect(paintWith(opacity: 1, blendMode: BlendMode.plus).blendMode,
          BlendMode.plus);
      expect(paintWith(opacity: 1, blendMode: BlendMode.multiply).blendMode,
          BlendMode.multiply);
    });

    testWidgets('clamps the opacity', (WidgetTester tester) async {
      expect(paintWith(opacity: 0.25).color.a, closeTo(0.25, 0.01));
      expect(paintWith(opacity: 1.3).color.a, 1.0);
      expect(paintWith(opacity: -0.3).color.a, 0.0);
    });

    testWidgets('paints nothing into an empty rect',
        (WidgetTester tester) async {
      final TestRecordingCanvas canvas = TestRecordingCanvas();
      paintImage(
        canvas: canvas,
        rect: Rect.zero,
        image: image,
        blendMode: BlendMode.srcOver,
      );
      expect(calls(canvas), isEmpty);
    });

    testWidgets('reports the image size using the device pixel ratio',
        (WidgetTester tester) async {
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      final List<ImageSizeInfo> reported = <ImageSizeInfo>[];
      debugOnPaintImage = reported.add;

      paintImage(
        canvas: TestRecordingCanvas(),
        rect: const Rect.fromLTWH(0, 0, 20, 30),
        image: image,
        blendMode: BlendMode.srcOver,
        debugImageLabel: 'test image',
      );
      expect(reported, hasLength(1));
      expect(reported.single.source, 'test image');
      expect(reported.single.imageSize, const Size(10, 10));
      expect(reported.single.displaySize, const Size(60, 90));
      debugOnPaintImage = null;
      // Flushes the post frame callback.
      await tester.pump();
    });
  });

  group('BoxDecorationMix', () {
    test('releases its image listeners when its painter is disposed', () {
      final TestImageProvider provider1 = TestImageProvider();
      final TestImageProvider provider2 = TestImageProvider();
      final BoxPainter painter = BoxDecorationMix(
        image1: DecorationImage(image: provider1),
        image2: DecorationImage(image: provider2),
      ).createBoxPainter(() {});
      painter.paint(TestRecordingCanvas(), Offset.zero, kConfiguration);
      expect(provider1.completers['key']!.listening, isTrue);
      expect(provider2.completers['key']!.listening, isTrue);
      painter.dispose();
      expect(provider1.completers['key']!.listening, isFalse);
      expect(provider2.completers['key']!.listening, isFalse);
    });

    test('repaints when an image arrives', () {
      final TestImageProvider provider = TestImageProvider();
      int changes = 0;
      final BoxPainter painter = BoxDecorationMix(
        image1: DecorationImage(image: provider),
        image2: DecorationImage(image: provider),
      ).createBoxPainter(() => changes++);
      painter.paint(TestRecordingCanvas(), Offset.zero, kConfiguration);
      final ui.Image image = createSolidImage(2, 2);
      provider.completers['key']!.emit(ImageInfo(image: image.clone()));
      expect(changes, 2);
      painter.dispose();
      expect(openHandles(image), 1);
      image.dispose();
    });
  });
}
