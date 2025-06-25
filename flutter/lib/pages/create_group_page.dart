import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie_recommendation_app/functions/random_string.dart';
import 'package:movie_recommendation_app/models/user_session.dart';
import 'package:provider/provider.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<StatefulWidget> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroupPage> {
  String creategroupcode() {
    return getRandomString(20);
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    final String groupcode = creategroupcode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.groups),
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(
                    session.isLoggedIn
                        ? session.avatarUrl!
                        : 'https://cdn-icons-png.flaticon.com/512/847/847969.png',
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          session.isLoggedIn ? session.userName! : 'Anon',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Group Admin',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Invite friends to your group!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Group Invitation Code:',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 5),
            Container(
              decoration: BoxDecoration(
                border: Border.all(),
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 240,
                    child: Text(
                      groupcode,
                      softWrap: true,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filled(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: groupcode)).then((_) {
                        final snackBar = const SnackBar(
                          content: Text('Invite code has been copied!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color.fromARGB(255, 134, 42, 35),
                          duration: Duration(seconds: 2),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      });
                    },
                    icon: const Icon(Icons.copy),
                    color: Colors.black,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
