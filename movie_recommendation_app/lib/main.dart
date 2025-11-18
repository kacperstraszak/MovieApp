import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/screens/auth.dart';
import 'package:movie_recommendation_app/screens/home.dart';
import 'package:movie_recommendation_app/screens/splash.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'URL',
    anonKey:
        'KEY',
  );
  runApp(const ProviderScope(
    child: App(),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Recommendation App',
      theme: appTheme,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          final session = snapshot.data?.session;

          if (session != null) {
            return const HomeScreen();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}
