import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router_delegate.dart';
import 'router/app_route_information_parser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar to match the app theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MusicRoomApp(),
    ),
  );
}

/// Root widget for MusicRoom.
/// Uses [MaterialApp.router] with Navigator 2.0 for declarative routing
/// driven by [AuthProvider] state.
class MusicRoomApp extends StatefulWidget {
  const MusicRoomApp({super.key});

  @override
  State<MusicRoomApp> createState() => _MusicRoomAppState();
}

class _MusicRoomAppState extends State<MusicRoomApp> {
  late final AppRouterDelegate _routerDelegate;
  final _routeInformationParser = AppRouteInformationParser();

  @override
  void initState() {
    super.initState();
    // Create the router delegate with a reference to AuthProvider.
    // We use `listen: false` because the delegate registers its own listener.
    _routerDelegate = AppRouterDelegate(
      authProvider: Provider.of<AuthProvider>(context, listen: false),
    );
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MusicRoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}
