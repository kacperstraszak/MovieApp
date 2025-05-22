import 'package:movie_recommendation_app/models/user_session.dart';
import 'package:movie_recommendation_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movie_recommendation_app/components/themes.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://rbprhqawjugawkcmryyu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJicHJocWF3anVnYXdrY21yeXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMjA5NzEsImV4cCI6MjA2Mjg5Njk3MX0.xC3TP9g1H77f5WnrXkcXRJOGa4WEAGmFATDPFEwjDBg',
  );
  runApp(ChangeNotifierProvider(
    create: (_) => UserSession(),
    child: const MyApp(),
  ));
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Recommendation App',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
