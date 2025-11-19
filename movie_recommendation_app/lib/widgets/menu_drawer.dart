import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/providers/auth_provider.dart';

class MenuDrawer extends ConsumerWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    void showLogoutDialog() {
      final colorScheme = Theme.of(context).colorScheme;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          alignment: Alignment.center,
          icon: Icon(
            Icons.logout_rounded,
            color: colorScheme.error,
            size: 32,
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).signOut();
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );
    }

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.onPrimary,
                  Theme.of(context).colorScheme.surfaceContainer,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 24),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundImage:
                        profile != null ? NetworkImage(profile.imageUrl) : null,
                    child: profile?.imageUrl == null
                        ? const CircularProgressIndicator()
                        : null,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        profile !=null ? profile.username : '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        softWrap: false,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'meow meow',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
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
              //meow meow
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.groups_2),
            title: const Text('Create Group'),
            onTap: () {},
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
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              // meow meow meow meow
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // meow meow meow meow
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.red[300],
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red[300],
              ),
            ),
            onTap: () {
              showLogoutDialog();
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
