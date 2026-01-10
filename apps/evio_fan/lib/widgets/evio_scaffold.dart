import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

/// Scaffold wrapper que aplica automáticamente el fondo con noise/grain
/// 
/// Uso:
/// ```dart
/// EvioScaffold(
///   body: MyContent(),
/// )
/// ```
class EvioScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool applyNoiseBackground;

  const EvioScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.applyNoiseBackground = true, // Por defecto aplica el noise
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? EvioFanColors.background;

    if (applyNoiseBackground) {
      // Scaffold con noise background
      return Scaffold(
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        drawer: drawer,
        endDrawer: endDrawer,
        body: Container(
          decoration: EvioBackgrounds.screenBackground(bgColor),
          child: body,
        ),
      );
    } else {
      // Scaffold normal (sin noise)
      return Scaffold(
        backgroundColor: bgColor,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        drawer: drawer,
        endDrawer: endDrawer,
        body: body,
      );
    }
  }
}
