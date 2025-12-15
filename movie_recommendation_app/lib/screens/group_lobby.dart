import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/screens/preferences.dart';

class GroupLobbyScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  final String groupId;

  const GroupLobbyScreen({
    super.key,
    required this.isAdmin,
    required this.groupId,
  });

  @override
  ConsumerState<GroupLobbyScreen> createState() => _GroupLobbyScreenState();
}

class _GroupLobbyScreenState extends ConsumerState<GroupLobbyScreen> {
  void _showSnackbar(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyGroupCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code)).then((_) {
      _showSnackbar(
        'Group code copied to clipboard!',
        Colors.green,
      );
    });
  }

  Future<void> _startRecommendationProcess(BuildContext context) async {
    final provider = ref.read(groupProvider.notifier);
    await provider.updateAllGroupMembers();
    await provider.changeGroupStatus('started');
  }

  Future<void> _handleExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        title: Text(
          'Leave Group',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        content: Text(
          widget.isAdmin
              ? 'As admin, leaving will close the group for all members. Continue?'
              : 'Are you sure you want to leave this group?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      ref.read(groupProvider.notifier).leaveGroup();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(groupProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage!.contains('closed by admin')) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _showSnackbar(
              next.errorMessage!, Theme.of(context).colorScheme.error);
          Navigator.of(context).pop();
        }
      }

      if (previous?.currentGroup?.status != next.currentGroup?.status &&
          next.currentGroup?.status == 'started') {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _showSnackbar(
            'Recommendation process started!',
            Colors.green,
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const PreferencesScreen(),
                ),
              );
            }
          });
        }
      }
    });

    final groupState = ref.watch(groupProvider);
    final group = groupState.currentGroup;
    final members = groupState.members;
    final errorMessage = groupState.errorMessage;

    if (errorMessage != null && !errorMessage.contains('closed by admin')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackbar(
          errorMessage,
          Theme.of(context).colorScheme.error,
        );
      });
    }

    if (group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Lobby'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading group...'),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Lobby'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleExit,
            tooltip: 'Leave Group',
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.groups,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.25),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  if (widget.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade300,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade600),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber.shade900,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You are the Group Admin',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Group Invitation Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            group.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _copyGroupCode(context, group.code),
                          icon: const Icon(Icons.copy),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.onSecondary,
                            foregroundColor: Colors.white,
                          ),
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share this code with friends to invite them',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Members (${members.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: members.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Waiting for members...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final member = members[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundImage:
                                        NetworkImage(member.imageUrl),
                                  ),
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          member.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (member.isAdmin) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            if (widget.isAdmin)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.surface,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: members.length >= 2
                      ? () => _startRecommendationProcess(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        members.length >= 2
                            ? 'Start Recommendation Process'
                            : 'Waiting for members... (${members.length}/2)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
