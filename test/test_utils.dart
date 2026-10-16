import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 2x2 opaque red PNG.
final Uint8List kRedPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x72, 0xb6, 0x0d, 0x24, 0x00, 0x00, 0x00,
  0x11, 0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0x63, 0xf8, 0xcf, 0xc0, 0xf0,
  0x1f, 0x84, 0x19, 0x60, 0x0c, 0x00, 0x47, 0xca, 0x07, 0xf9, 0x1a, 0xb6,
  0xf1, 0xa9, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42,
  0x60, 0x82,
]);

/// A 2x2 opaque blue PNG.
final Uint8List kBluePng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x72, 0xb6, 0x0d, 0x24, 0x00, 0x00, 0x00,
  0x10, 0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0x63, 0x60, 0x60, 0xf8, 0xff,
  0x1f, 0x82, 0xa1, 0x0c, 0x00, 0x3f, 0xd2, 0x07, 0xf9, 0x5c, 0x13, 0xe0,
  0x42, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60,
  0x82,
]);

final MemoryImage kRedImage = MemoryImage(kRedPng);
final MemoryImage kBlueImage = MemoryImage(kBluePng);

/// Decodes [provider] for real and leaves the result in the image cache, so
/// that painting it afterwards happens synchronously.
Future<void> precacheTestImage(
    WidgetTester tester, ImageProvider provider) async {
  await tester.runAsync(() async {
    final Completer<void> completer = Completer<void>();
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool sync) {
        info.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    await completer.future;
    stream.removeListener(listener);
  });
}

/// Precaches the images used by the test decorations.
Future<void> precacheTestImages(WidgetTester tester) async {
  await precacheTestImage(tester, kRedImage);
  await precacheTestImage(tester, kBlueImage);
}

/// The pixels of a rendered widget, as unpremultiplied RGBA bytes.
class Pixels {
  Pixels(this.width, this.height, this.bytes);

  final int width;
  final int height;
  final Uint8List bytes;

  /// The color at (x, y).
  Color at(int x, int y) {
    final int i = (y * width + x) * 4;
    return Color.fromARGB(bytes[i + 3], bytes[i], bytes[i + 1], bytes[i + 2]);
  }

  /// The number of pixels that differ by more than [tolerance] in any channel
  /// from the same pixel of [other].
  int countDifferent(Pixels other, {int tolerance = 3}) {
    assert(other.width == width && other.height == height);
    int result = 0;
    for (int i = 0; i < bytes.length; i += 4) {
      for (int c = 0; c < 4; c++) {
        if ((bytes[i + c] - other.bytes[i + c]).abs() > tolerance) {
          result++;
          break;
        }
      }
    }
    return result;
  }

  /// The largest per-channel difference between this and [other].
  int maxDifference(Pixels other) {
    assert(other.width == width && other.height == height);
    int result = 0;
    for (int i = 0; i < bytes.length; i++) {
      final int d = (bytes[i] - other.bytes[i]).abs();
      if (d > result) result = d;
    }
    return result;
  }
}

const Size kRenderSize = Size(40, 40);

/// Paints [decoration] (on top of an opaque white background, with a margin
/// so that shadows are visible too) and returns the resulting pixels.
Future<Pixels> renderDecoration(
  WidgetTester tester,
  Decoration decoration, {
  Size size = kRenderSize,
}) {
  return renderWidget(
    tester,
    DecoratedBox(decoration: decoration),
    size: size,
  );
}

/// Pumps [child] at [size] inside a [RepaintBoundary] (on top of an opaque
/// white background, with a margin) and returns the resulting pixels.
Future<Pixels> renderWidget(
  WidgetTester tester,
  Widget child, {
  Size size = kRenderSize,
}) async {
  final GlobalKey key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox.fromSize(size: size, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  return capturePixels(tester, key);
}

/// Captures the pixels of the [RepaintBoundary] with the given [key].
Future<Pixels> capturePixels(WidgetTester tester, GlobalKey key) async {
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final Pixels? pixels = await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage();
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    final Pixels result =
        Pixels(image.width, image.height, data!.buffer.asUint8List());
    image.dispose();
    return result;
  });
  return pixels!;
}

/// A matcher for colors whose channels are each within [tolerance] (in 0..255
/// units) of [expected].
Matcher matchesColor(Color expected, {int tolerance = 2}) =>
    _ColorMatcher(expected, tolerance);

class _ColorMatcher extends Matcher {
  _ColorMatcher(this.expected, this.tolerance);

  final Color expected;
  final int tolerance;

  static List<int> _channels(Color c) => <int>[
        (c.a * 255).round(),
        (c.r * 255).round(),
        (c.g * 255).round(),
        (c.b * 255).round(),
      ];

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Color) return false;
    final List<int> a = _channels(item);
    final List<int> b = _channels(expected);
    for (int i = 0; i < 4; i++) {
      if ((a[i] - b[i]).abs() > tolerance) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) => description
      .add('a color with ARGB channels within $tolerance of ')
      .add(_channels(expected).toString());

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is Color) {
      return mismatchDescription
          .add('has ARGB channels ')
          .add(_channels(item).toString());
    }
    return mismatchDescription.add('is not a Color');
  }
}

/// A matcher for [Pixels] that look (almost) the same as [expected].
///
/// The rasterizer quantizes anti-aliasing coverage, so a tiny change in
/// geometry can noticeably change a handful of pixels on the edges of shapes.
/// This allows that, but nothing else.
Matcher looksLike(Pixels expected) => _PixelsMatcher(expected);

class _PixelsMatcher extends Matcher {
  _PixelsMatcher(this.expected);

  final Pixels expected;

  static const int maxEdgePixels = 12;
  static const int maxEdgeDifference = 24;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Pixels ||
        item.width != expected.width ||
        item.height != expected.height) {
      return false;
    }
    return item.countDifferent(expected) <= maxEdgePixels &&
        item.maxDifference(expected) <= maxEdgeDifference;
  }

  @override
  Description describe(Description description) => description.add(
      'pixels that differ by more than 3 in at most $maxEdgePixels pixels, '
      'and by at most $maxEdgeDifference');

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is Pixels &&
        item.width == expected.width &&
        item.height == expected.height) {
      return mismatchDescription
          .add('${item.countDifferent(expected)} pixels differ, by up to '
              '${item.maxDifference(expected)}');
    }
    return mismatchDescription.add('has a different size');
  }
}
