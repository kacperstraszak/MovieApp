import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:movie_recommendation_app/utils/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Stan providera
class AuthState {
  final User? user; // Aktualnie zalogowany użytkownik
  final bool
      isAuthenticating; // stan - czy apliakcja przeprowadza teraz autentykacje z supabasem
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isAuthenticating = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticating,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: errorMessage, // Jeśli null, to błąd znika
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _storageService = StorageService();

  @override
  AuthState build() {
    final currentUser = supabase.auth.currentUser;
    return AuthState(user: currentUser);
  }

  Future<void> _checkUsernameAvailability(String username) async {
    final data = await supabase
        .from(kProfilesTable)
        .select('username')
        .eq(kUsernameCol, username)
        .maybeSingle();

    if (data != null) {
      throw const AuthException('Username is already taken');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isAuthenticating: true, errorMessage: null);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isAuthenticating: false, user: response.user);
    } on AuthException catch (error) {
      state =
          state.copyWith(isAuthenticating: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'An unexpected error occurred');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    File? imageFile,
  }) async {
    state = state.copyWith(isAuthenticating: true, errorMessage: null);

    try {
      await _checkUsernameAvailability(username);
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw const AuthException('Registration failed: User is null');
      }

      final userId = authResponse.user!.id;
      String imageUrl =
          'https://api.dicebear.com/7.x/avataaars/png?seed=default'; // losowy avatar

      if (imageFile != null) {
        imageUrl = await _storageService.uploadAvatar(
          imageFile: imageFile,
          userId: userId,
          isUpdate: false,
        );
      }

      await supabase.from(kProfilesTable).insert({
        kUserIdCol: userId,
        kUsernameCol: username.trim(),
        kEmailCol: email,
        kImageUrlCol: imageUrl,
      });

      state = state.copyWith(isAuthenticating: false, user: authResponse.user);
    } on AuthException catch (error) {
      state =
          state.copyWith(isAuthenticating: false, errorMessage: error.message);
    } on StorageException catch (error) {
      state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Image upload failed: ${error.message}');
    } catch (error) {
      state = state.copyWith(
          isAuthenticating: false, errorMessage: 'An error occurred: $error');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = const AuthState(user: null);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
