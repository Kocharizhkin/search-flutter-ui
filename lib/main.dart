import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mkniga_search/firebase_options.dart';
import 'package:go_router/go_router.dart';

import 'package:mkniga_search/login.dart'; // replace with your actual import
import 'package:mkniga_search/search.dart';
import 'package:mkniga_search/upload.dart';
import 'package:mkniga_search/workin.dart';
import 'package:mkniga_search/update_progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

/// The route configuration.
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return WorkInProgress();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'search',
          builder: (BuildContext context, GoRouterState state) {
            return LoginPage();
          },
        ),
        GoRoute(
          path: 'progress',
          builder: (BuildContext context, GoRouterState state) {
            return ProgressScreen();
          },
        ),
        GoRoute(
          path: 'update',
          builder: (BuildContext context, GoRouterState state) {
            return UploadPage();
          },
        ),
      ],
    ),
  ],
);

/// The main app.
class MyApp extends StatelessWidget {
  /// Constructs a [MyApp]
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 55, 34, 3),
          background: Color.fromARGB(255, 250, 223, 183)
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 16.0,
            color: Color.fromARGB(255, 55, 34, 3)
          ), // Customize text styles
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}


