import 'package:movie_recommendation_app/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAuthState {
  const MyAuthState({
    this.user,
    this.profile,
    this.isAuthenticating = false,
    this.errorMessage,
  });

  final User? user; // auth zalogowanego użytkownika (mail/id)
  final UserProfile?
      profile; // reszta elementów profilu użytkownika (imageUrl/username)
  final bool
      isAuthenticating; // stan - czy apliakcja przeprowadza teraz autentykacje z supabasem
  final String? errorMessage;

  MyAuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isAuthenticating,
    String? errorMessage,
  }) {
    return MyAuthState(
      user: user ?? this.user,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: errorMessage,
      profile: profile ?? this.profile,
    );
  }
}