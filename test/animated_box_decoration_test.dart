// Checks that the public API (everything exported by
// package:animated_box_decoration/animated_box_decoration.dart) stays source
// compatible.
import 'package:animated_box_decoration/animated_box_decoration.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SmoothAnimatedContainer accepts all AnimatedContainer arguments', () {
    final SmoothAnimatedContainer container = SmoothAnimatedContainer(
      key: const ValueKey<int>(1),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(1),
      decoration: const BoxDecoration(),
      foregroundDecoration: const BoxDecoration(),
      width: 1,
      height: 2,
      constraints: const BoxConstraints(),
      margin: const EdgeInsets.all(2),
      transform: Matrix4.identity(),
      transformAlignment: Alignment.topLeft,
      clipBehavior: Clip.antiAlias,
      curve: Curves.ease,
      duration: const Duration(seconds: 1),
      onEnd: () {},
      child: const SizedBox(),
    );
    expect(container, isA<ImplicitlyAnimatedWidget>());
    expect(container.key, const ValueKey<int>(1));
    expect(container.curve, Curves.ease);
    expect(container.duration, const Duration(seconds: 1));
    expect(container.onEnd, isNotNull);
    expect(container.clipBehavior, Clip.antiAlias);
    expect(container.child, isA<SizedBox>());

    final SmoothAnimatedContainer defaults =
        SmoothAnimatedContainer(duration: const Duration(seconds: 1));
    expect(defaults.curve, Curves.linear);
    expect(defaults.clipBehavior, Clip.none);
    expect(defaults.decoration, isNull);
    expect(defaults.onEnd, isNull);
  });

  test('SmoothDecorationTween API', () {
    final SmoothDecorationTween tween = SmoothDecorationTween(
      begin: const BoxDecoration(),
      end: const BoxDecoration(),
    );
    final DecorationTween asDecorationTween = tween;
    final Tween<Decoration> asTween = tween;
    expect(asDecorationTween, same(asTween));
    final Decoration lerped = tween.lerp(0.5);
    final Decoration? box = tween.lerpBoxDecoration(
        const BoxDecoration(), const BoxDecoration(), 0.5);
    final Gradient? gradient = tween.lerpGradient(
        0.5, null, null, const Color(0xFF000000), const Color(0xFFFFFFFF));
    expect(lerped, isA<Decoration>());
    expect(box, isA<Decoration>());
    expect(gradient, isNull);
    expect(SmoothDecorationTween().begin, isNull);
  });
}
