import 'dart:io';

import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:movie_recommendation_app/widgets/user_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredPasswordRepeated = ''; // do walidacji
  var _enteredUsername = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  // URL DO API Z LOSOWYMI AWATARAMI
  static const String _defaultAvatarUrl =
      'https://api.dicebear.com/7.x/avataaars/png?seed=default';

  // PRYWATNA METODA DO POKAZYWANIA BŁĘDÓW
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();
    FocusScope.of(context).unfocus();

    try {
      setState(() {
        _isAuthenticating = true;
      });

      if (_isLogin) {
        // LOGOWANIE
        await supabase.auth.signInWithPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        // REJESTRACJA
        final authResponse = await supabase.auth.signUp(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        if (authResponse.user == null) {
          throw Exception('Registration failed');
        }

        final userId = authResponse.user!.id;
        String imageUrl = _defaultAvatarUrl;

        // WRZUCENIE ZDJĘCIA DO BAZY JEŚLI WYBRANE
        if (_selectedImage != null) {
          final String fileName = '$userId.jpg';
          final String filePath = '$kUserImagesPath/$fileName';

          await supabase.storage.from(kAvatarsBucket).upload(
                filePath,
                _selectedImage!,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );

          imageUrl = supabase.storage
              .from(kAvatarsBucket)
              .getPublicUrl(filePath); 
        }

        // ZAPIS DANYCH UŻYTKOWNIKA
        await supabase.from(kProfilesTable).insert({
          kUserIdCol: userId,
          kUsernameCol: _enteredUsername.trim(),
          kEmailCol: _enteredEmail,
          kImageUrlCol: imageUrl,
        });
      }
    } on AuthException catch (error) {
      _showErrorSnackBar(error.message);
    } on StorageException catch (error) {
      _showErrorSnackBar('Image upload failed: ${error.message}');
    } catch (error) {
      _showErrorSnackBar('An error occurred: $error');
    } finally {
      // BLOK FINALLY
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
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
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextFormField(
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value.trim().length < 4) {
                                  return 'Username must be at least 4 characters';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                            ),
                          TextFormField(
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 8) {
                                return 'Password must be at least 8 characters long';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                            onChanged: (value) {
                              _enteredPassword = value;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Repeat Password',
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please repeat your password';
                                }
                                if (value != _enteredPassword) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _enteredPasswordRepeated = value;
                              },
                            ),
                          const SizedBox(height: 24),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                              child: Text(
                                _isLogin ? 'Login' : 'Sign Up',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: _toggleAuthMode,
                              child: Text(
                                _isLogin
                                    ? 'Create an account'
                                    : 'I already have an account',
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
