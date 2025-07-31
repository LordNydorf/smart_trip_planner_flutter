import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIService {
  /// Configure system UI for light theme
  static void setLightSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Configure system UI for dark theme
  static void setDarkSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// Hide status bar and navigation bar (immersive mode)
  static void setImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  /// Show status bar and navigation bar with content behind them
  static void setEdgeToEdgeMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Show status bar and navigation bar normally
  static void setNormalMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  /// Hide only the status bar
  static void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  /// Hide only the navigation bar
  static void hideNavigationBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// Set custom status bar color
  static void setStatusBarColor(Color color, {bool lightIcons = false}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: lightIcons
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: lightIcons ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// Configure based on theme brightness
  static void setSystemUIForTheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      setDarkSystemUI();
    } else {
      setLightSystemUI();
    }
  }
}
