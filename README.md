<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

Lets you smoothly animate between two BoxDecoration. Specifically, lets you animate
between any color, gradient or image background. 

## Features

Currently the default implementation
in Flutter does not support animating background (BoxDecoration) between color and gradient, two gradient with different type,
and anything involving a image.

## Usage

If you want to get a intermediate Decoration at progress t between the initial and final Decoration, use:
```dart
const intermediate=SmoothDecorationTween(begin: begin, end: end, t);
```

You can also just use the SmoothAnimatedContainer widget just as you use the AnimatedContainer widget.

## Additional information

This package primarily modifies the tweening between two BoxDecoration and focuses on making the animation of the background smooth.
The animation of the shape is not implemented. But you can look at the [morphable_shape](https://pub.dev/packages/morphable_shape)
package if you want that functionality. 
