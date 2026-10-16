import 'package:flutter/material.dart';

abstract final class DashenColors {
  static const Color green = Color(0xFF034F2A);
  static const Color surface = Color(0xFF182029);
  static const Color lime = Color(0xFF85C838);
  static const Color highlight = Color(0xFF25D366);
  static const Color text = Color(0xFFFFFFFF);
  static final Color photoTile = Color.alphaBlend(
    text.withValues(alpha: 0.08),
    surface,
  );
  static final Color subtle = Color.alphaBlend(
    text.withValues(alpha: 0.12),
    surface,
  );
}
