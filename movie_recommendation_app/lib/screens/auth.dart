import 'dart:io';

import 'package:movie_recommendation_app/providers/auth_provider.dart';
import 'package:movie_recommendation_app/widgets/user_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredPasswordRepeated = '';
  var _enteredUsername = '';
  File? _selectedImage;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();
    FocusScope.of(context).unfocus();

    final authNotifier = ref.read(authProvider.notifier);

    if (_isLogin) {
      // LOGOWANIE
      await authNotifier.signIn(
        email: _enteredEmail,
        password: _enteredPassword,
      );
    } else {
      // REJESTRACJA
      await authNotifier.signUp(
          email: _enteredEmail,
          password: _enteredPassword,
          username: _enteredUsername,
          imageFile: _selectedImage);
    }
  }

void _toggleAuthMode() {
  FocusScope.of(context).unfocus();
  setState(() {
    _isLogin = !_isLogin;
    _form.currentState?.reset();
    _selectedImage = null;
    _enteredEmail = '';
    _enteredPassword = '';
    _enteredPasswordRepeated = '';
    _enteredUsername = '';
  });
}

@override
Widget build(BuildContext context) {

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.errorMessage != null && next.errorMessage != previous?.errorMessage){
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.errorMessage!),
        backgroundColor: Theme.of(context).colorScheme.error,)
      );

    }
  });

  final authState = ref.watch(authProvider);
  final isAuthenticating = authState.isAuthenticating;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/movie.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin) ...[
                            UserImagePicker(
                              onPickImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                            Text(
                              'Profile picture is optional',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextFormField(
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty || !value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) => _enteredEmail = value!,
                          ),
                          if (!_isLogin)
                            TextFormField(
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              decoration: const InputDecoration(labelText: 'Username'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty || value.trim().length < 4) {
                                  return 'Username must be at least 4 characters';
                                }
                                return null;
                              },
                              onSaved: (value) => _enteredUsername = value!,
                            ),
                          TextFormField(
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 8) {
                                return 'Password must be at least 8 characters long';
                              }
                              return null;
                            },
                            onChanged: (value) => _enteredPassword = value,
                            onSaved: (value) => _enteredPassword = value!,
                          ),
                          if (!_isLogin)
                            TextFormField(
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              decoration: const InputDecoration(labelText: 'Repeat Password'),
                              obscureText: true,
                              validator: (value) {
                                if (value != _enteredPassword) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 24),
                          if (isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                              child: Text(
                                _isLogin ? 'Login' : 'Sign Up',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                              ),
                            ),
                          if (!isAuthenticating)
                            TextButton(
                              onPressed: _toggleAuthMode,
                              child: Text(
                                _isLogin ? 'Create an account' : 'I already have an account',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}