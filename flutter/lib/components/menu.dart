import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/models/user_session.dart';
import 'package:movie_recommendation_app/pages/home_page.dart';
import 'package:movie_recommendation_app/pages/signup_page.dart';
import 'package:movie_recommendation_app/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:movie_recommendation_app/main.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);

    void resetAndPush(BuildContext context, Widget targetPage) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetPage),
        (route) => route.isFirst,
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B7D4C), Color(0xFF44A574)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    session.isLoggedIn
                        ? session.avatarUrl!
                        : 'https://cdn-icons-png.flaticon.com/512/847/847969.png',
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isLoggedIn
                          ? 'Witaj, ${session.userName}!'
                          : 'Witaj!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              // meow meow meow meow
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home Page'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.groups_2),
            title: const Text('Create Group'),
            onTap: () {
              // meow meow meow meow
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('Join Group'),
            onTap: () {
              // meow meow meow meow
            },
          ),
          const Divider(),
          if (!session.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Sign up'),
              onTap: () => resetAndPush(context, const SignupPage()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () => resetAndPush(context, const LoginPage()),
            ),
            const Divider(),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                // meow meow meow meow
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final userSession = context.read<UserSession>();
                await supabase.auth.signOut();
                userSession.refresh();
                
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // meow meow meow meow
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
