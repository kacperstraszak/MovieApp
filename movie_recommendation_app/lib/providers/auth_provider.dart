import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/my_auth_state.dart';
import 'package:movie_recommendation_app/models/user_profile.dart';
import 'package:movie_recommendation_app/providers/supabase_client_provider.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:movie_recommendation_app/utils/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends Notifier<MyAuthState> {
  SupabaseClient get _supabase => ref.read(supabaseClientProvider);
  StorageService get _storageService => ref.read(storageServiceProvider);

  @override
  MyAuthState build() {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser != null) {
      Future.microtask(() => _loadProfile(currentUser.id));
    }

    return MyAuthState(user: currentUser);
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final data = await _supabase
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
    final data = await _supabase
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
      final response = await _supabase.auth.signInWithPassword(
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
      final authResponse = await _supabase.auth.signUp(
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

      await _supabase.from(kProfilesTable).insert({
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
    await _supabase.auth.signOut();
    state = const MyAuthState(user: null);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authProvider =
    NotifierProvider<AuthNotifier, MyAuthState>(AuthNotifier.new);
