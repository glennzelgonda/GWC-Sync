import 'package:flutter/material.dart';

/// Simple breakpoint helper for adapting layouts between phone-sized and
/// tablet/desktop-sized viewports. Used to switch between BottomNavigationBar
/// vs NavigationRail, ListView vs GridView, etc.
class Responsive {
  static const double tabletBreakpoint = 700;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static double width(BuildContext context) => MediaQuery.of(context).size.width;
}
