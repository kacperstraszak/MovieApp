import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/functions/register_check.dart';
import 'package:movie_recommendation_app/models/user_session.dart';
import 'package:movie_recommendation_app/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<StatefulWidget> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? usernameError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void validateAndSignUp() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      emailError =
          EmailValidator.validate(email) ? null : 'Invalid Email Address';
      usernameError = getUsernameError(username);
      passwordError = getPasswordError(password);
    });

    if (emailError == null && usernameError == null && passwordError == null) {
      final userSession = context.read<UserSession>();

      try {
        final signUpResponse = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        final user = signUpResponse.user;
        if (user == null) {
          throw Exception("User creation failed");
        }

        final profileInsert = await supabase.from('profiles').insert({
          'id': user.id,
          'username': username,
          'avatar': null,
        });

        if (profileInsert.error != null) {
          throw Exception(
              "Profile creation failed: ${profileInsert.error!.message}");
        }

        userSession.refresh();

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Sign up failed',
              textAlign: TextAlign.center,
            ),
            content: Text(
              e.toString(),
              textAlign: TextAlign.center,
            ),
            icon: const Icon(Icons.sentiment_very_dissatisfied),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.person_add),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          height: MediaQuery.of(context).size.height - 80,
          width: double.infinity,
          margin: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      prefixIcon: const Icon(
                        Icons.person,
                      ),
                      errorText: usernameError,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      prefixIcon: const Icon(
                        Icons.email,
                      ),
                      errorText: emailError,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      prefixIcon: const Icon(
                        Icons.lock,
                      ),
                      errorText: passwordError,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: validateAndSignUp,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 60,
                      ),
                    ),
                    child: const Text(
                      "Sign up!",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Color.fromARGB(255, 134, 42, 35),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
