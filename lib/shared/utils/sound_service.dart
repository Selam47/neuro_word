/// Placeholder sound effect service.
///
/// To enable audio, add the `audioplayers` package to pubspec.yaml
/// and drop WAV/MP3 files into `assets/sounds/`.
///
/// Example usage:
/// ```dart
/// SoundService.playCorrect();
/// ```
class SoundService {
  SoundService._();

  // TODO: Replace with actual AudioPlayer implementation when assets are ready.
  //
  // Suggested assets:
  //   - assets/sounds/correct.wav    → bright futuristic blip
  //   - assets/sounds/wrong.wav      → low error buzz
  //   - assets/sounds/tap.wav        → subtle click
  //   - assets/sounds/complete.wav   → triumphant synth chord

  /// Play on correct answer / successful match.
  static void playCorrect() {
    // AudioPlayer().play(AssetSource('sounds/correct.wav'));
  }

  /// Play on wrong answer / timeout.
  static void playWrong() {
    // AudioPlayer().play(AssetSource('sounds/wrong.wav'));
  }

  /// Play on generic button press.
  static void playButtonTap() {
    // AudioPlayer().play(AssetSource('sounds/tap.wav'));
  }

  /// Play on session completion.
  static void playSessionComplete() {
    // AudioPlayer().play(AssetSource('sounds/complete.wav'));
  }
}
