import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Supabase Client
final supabase = Supabase.instance.client;

// Supabase Tables
const kProfilesTable = 'profiles';
const kAvatarsBucket = 'avatars';

// Supabase Columns
const kUserIdCol = 'id';
const kUsernameCol = 'username';
const kEmailCol = 'email';
const kImageUrlCol = 'image_url';

// Storage Paths
const kUserImagesPath = 'user_images';

// Random Avatars
const String defaultAvatarUrl =
    'https://api.dicebear.com/7.x/avataaars/png?seed=default';

// Preloader
const preloader = Center(child: CircularProgressIndicator());

// Theme
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromARGB(255, 15, 57, 108),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);
