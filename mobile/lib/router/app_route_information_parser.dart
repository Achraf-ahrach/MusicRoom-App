import 'package:flutter/material.dart';

/// Minimal RouteInformationParser for Navigator 2.0.
/// Since navigation is driven entirely by AuthProvider state (not URL),
/// this parser simply returns a default RouteInformation.
class AppRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation;
  }

  @override
  RouteInformation? restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}
