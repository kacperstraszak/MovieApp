import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/main.dart';

class UserSession extends ChangeNotifier {
  bool isLoggedIn = false;
  String? userName;
  String? avatarUrl;

  UserSession() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final userProf = await supabase.from('profiles').select().eq('id', user.id).single();
      isLoggedIn = true;
      userName = userProf['username'] ?? 'User';
      avatarUrl = userProf['avatar'] ??
          'https://cdn-icons-png.flaticon.com/512/847/847969.png';
    } else {
      isLoggedIn = false;
      userName = null;
      avatarUrl = null;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    await _loadUser();
  }

  void refresh() {
    _loadUser();
  }
}
