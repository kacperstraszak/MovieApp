import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/user_profile.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:movie_recommendation_app/utils/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Stan providera
class AuthState {
  const AuthState({
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

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isAuthenticating,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: errorMessage, // Jeśli null, to błąd znika
      profile: profile ?? this.profile,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _storageService = StorageService();

  @override
  AuthState build() {
    final currentUser = supabase.auth.currentUser;

    if (currentUser != null) {
      Future.microtask(() => _loadProfile(currentUser.id));
    }

    return AuthState(user: currentUser);
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final data = await supabase
          .from(kProfilesTable)
          .select()
          .eq(kUserIdCol, userId)
          .single();

      final profile = UserProfile.fromJson(data);
      state = state.copyWith(profile: profile);
    } on PostgrestException catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load profile: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unexpected error loading profile: $e',
      );
    }
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

      if (response.user != null) {
        await _loadProfile(response.user!.id);
      }
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
          '$defaultAvatarUrl${Random().nextInt(10000).toString()}';

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

      await _loadProfile(userId);
    } on AuthException catch (error) {
      state =
          state.copyWith(isAuthenticating: false, errorMessage: error.message);
    } on StorageException catch (error) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Image upload failed: ${error.message}',
      );
    } catch (error) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'An error occurred: $error',
      );
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = const AuthState(user: null);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
