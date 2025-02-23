import 'dart:math';

import 'package:flutter/rendering.dart';

/// the [scanWindow] rect will be relative and scaled to the [widgetSize] not the texture. so it is possible,
/// depending on the [fit], for the [scanWindow] to partially or not at all overlap the [textureSize]
///
/// since when using a [BoxFit] the content will always be centered on its parent. we can convert the rect
/// to be relative to the texture.
///
/// since the textures size and the actuall image (on the texture size) might not be the same, we also need to
/// calculate the scanWindow in terms of percentages of the texture, not pixels.
Rect calculateScanWindowRelativeToTextureInPercentage(
  BoxFit fit,
  Rect scanWindow,
  Size textureSize,
  Size widgetSize,
) {
  /// map the texture size to get its new size after fitted to screen
  final fittedTextureSize = applyBoxFit(fit, textureSize, widgetSize);

  // Get the correct scaling values depending on the given BoxFit mode
  double sx = fittedTextureSize.destination.width / textureSize.width;
  double sy = fittedTextureSize.destination.height / textureSize.height;

  switch (fit) {
    case BoxFit.fill:
      // nop
      // Just use sx and sy
      break;
    case BoxFit.contain:
      final s = min(sx, sy);
      sx = s;
      sy = s;
      break;
    case BoxFit.cover:
      final s = max(sx, sy);
      sx = s;
      sy = s;
      break;
    case BoxFit.fitWidth:
      sy = sx;
      break;
    case BoxFit.fitHeight:
      sx = sy;
      break;
    case BoxFit.none:
      sx = 1.0;
      sy = 1.0;
      break;
    case BoxFit.scaleDown:
      final s = min(sx, sy);
      sx = s;
      sy = s;
      break;
  }

  // Fit the texture size to the widget rectangle given by the scaling values above
  final textureWindow = Alignment.center.inscribe(
    Size(textureSize.width * sx, textureSize.height * sy),
    Rect.fromLTWH(0, 0, widgetSize.width, widgetSize.height),
  );

  // Transform the scan window from widget coordinates to texture coordinates
  final scanWindowInTexSpace = Rect.fromLTRB(
    (1 / sx) * (scanWindow.left - textureWindow.left),
    (1 / sy) * (scanWindow.top - textureWindow.top),
    (1 / sx) * (scanWindow.right - textureWindow.left),
    (1 / sy) * (scanWindow.bottom - textureWindow.top),
  );

  // Clip the scan window in texture coordinates with the texture bounds.
  // This prevents percentages outside the range [0; 1].
  final clippedScanWndInTexSpace = scanWindowInTexSpace
      .intersect(Rect.fromLTWH(0, 0, textureSize.width, textureSize.height));

  // Compute relative rectangle coordinates with respect to the texture size, i.e. scan image
  final percentageLeft = clippedScanWndInTexSpace.left / textureSize.width;
  final percentageTop = clippedScanWndInTexSpace.top / textureSize.height;
  final percentageRight = clippedScanWndInTexSpace.right / textureSize.width;
  final percentageBottom = clippedScanWndInTexSpace.bottom / textureSize.height;

  // This rectangle can be send to native code and used to cut out a rectangle of the scan image
  return Rect.fromLTRB(
    percentageLeft,
    percentageTop,
    percentageRight,
    percentageBottom,
  );
}
