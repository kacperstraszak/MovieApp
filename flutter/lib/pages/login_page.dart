import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/models/user_session.dart';
import 'package:movie_recommendation_app/pages/signup_page.dart';
import 'package:email_validator/email_validator.dart';
import 'package:movie_recommendation_app/main.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/functions/register_check.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void validateAndLogin() async {
    setState(() {
      emailError = EmailValidator.validate(emailController.text)
          ? null
          : 'Invalid Email Address';
      passwordError = getPasswordError(passwordController.text);
    });

    if (emailError == null && passwordError == null) {
      final userSession = context.read<UserSession>();

      try {
        final response = await supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (response.user != null) {
          userSession.refresh();

          if (!mounted) return;
          Navigator.pop(context);
        } else {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text(
                'Login Failed',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'No user was returned from Supabase.',
                textAlign: TextAlign.center,
              ),
              icon: Icon(Icons.sentiment_very_dissatisfied),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text(
              'Login Failed',
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Invalid email or password!',
              textAlign: TextAlign.center,
            ),
            icon: Icon(Icons.sentiment_very_dissatisfied),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.login),
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
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Log into your account',
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
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      errorText: emailError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      prefixIcon: const Icon(Icons.lock),
                      errorText: passwordError,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: validateAndLogin,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 60,
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // meow meow meow meow
                    },
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 134, 42, 35),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupPage()),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Color.fromARGB(255, 134, 42, 35),
                          ),
                        ),
                      ),
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
