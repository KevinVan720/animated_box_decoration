## 0.0.1

Initial release. 

## 0.0.2

Fix minor bug

## 0.0.3

Use blendmode to avoid brightness change during image tween

## 0.0.4

Minor fix

## 0.0.5

Minor fix

## 0.0.6

Remove unnecessary dependency

## 0.0.7

Update dependency

## 0.0.8

* Support the latest Flutter stable. Requires Flutter 3.27 (Dart 3.6) or newer.
* No longer depend on `package:flutter/material.dart`: the package only uses
  the widgets layer, so it works with Material, Cupertino or neither.
* Fix jumps at the start or the end of some animations: a translucent background
  color was painted twice, a gradient was faded by the color of the other
  decoration, the background color leaked around the corners of an opaque
  border, and when animating between two images, the first one stayed fully
  visible until the end (visible when the second image is translucent or does
  not cover the box).
* Fix animations that are interrupted (by changing the decoration while it is
  still animating): they used to freeze, then flash. They now continue smoothly.
* Fix an assertion error when animating between a circle and a rounded
  rectangle.
* Fix an assertion error when animating shadows with a curve that overshoots
  (like `Curves.elasticOut`).
* Keep the `backgroundBlendMode` while animating (it switches half way when the
  two decorations use different blend modes).
* Custom `Gradient` types no longer disappear when animating from or to a color.
* Update the image painting code to match the latest Flutter (multiple views,
  opacity clamping, memory allocation tracking).
