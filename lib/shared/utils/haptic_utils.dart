import 'package:flutter/services.dart';

class HapticUtils {
  HapticUtils._();

  static void tap() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.lightImpact();

  static void error() => HapticFeedback.heavyImpact();

  static void milestone() => HapticFeedback.mediumImpact();
}
