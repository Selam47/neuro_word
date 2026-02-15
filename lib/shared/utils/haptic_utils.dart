import 'package:flutter/services.dart';

/// Centralized haptic feedback utility.
/// Wraps platform-safe calls so game screens stay clean.
class HapticUtils {
  HapticUtils._();

  /// Subtle tap feedback — button presses, card flips.
  static void tap() => HapticFeedback.selectionClick();

  /// Positive action — correct answer, successful match.
  static void success() => HapticFeedback.lightImpact();

  /// Negative action — wrong answer, timeout, mismatch.
  static void error() => HapticFeedback.heavyImpact();

  /// Strong milestone — session complete, level up.
  static void milestone() => HapticFeedback.mediumImpact();
}
