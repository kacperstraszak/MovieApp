import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/screens/auth.dart';
import 'package:movie_recommendation_app/screens/splash.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rbprhqawjugawkcmryyu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJicHJocWF3anVnYXdrY21yeXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMjA5NzEsImV4cCI6MjA2Mjg5Njk3MX0.xC3TP9g1H77f5WnrXkcXRJOGa4WEAGmFATDPFEwjDBg',
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
            return const SplashScreen();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}
