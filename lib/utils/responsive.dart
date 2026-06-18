import 'package:flutter/material.dart';

class Responsive {
  /// Defines the maximum width of the content area on a web/desktop screen
  /// to prevent it from stretching endlessly.
  static const double maxWebWidth = 1200.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Returns the number of columns that should be displayed in a GridView
  /// based on the current screen size.
  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 5, // typical eCommerce default
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Centers a widget and restricts its maximum width on standard web/desktop screens.
  /// If the screen is mobile, it expands to 100% width normally.
  static Widget centeredWebContainer(
    BuildContext context, {
    required Widget child,
    double maxWidth = maxWebWidth,
  }) {
    if (isMobile(context)) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
