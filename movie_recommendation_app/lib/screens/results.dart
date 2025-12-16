import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/providers/result_provider.dart';
import 'package:movie_recommendation_app/screens/home.dart';
import 'package:movie_recommendation_app/widgets/results_view.dart';
import 'package:movie_recommendation_app/widgets/waiting_view.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  var _areResultsReady = false;

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

  Future<void> _handleExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.exit_to_app_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Leave Results',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to leave recommendation results?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void loadResults() async {
    await ref.read(resultsProvider.notifier).loadResults();
    setState(() {
      _areResultsReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(groupProvider, (previous, next) {
      if (next.errorMessage != null) {
        _showSnackbar(
          next.errorMessage!,
          Theme.of(context).colorScheme.error,
        );
      }

      if (previous?.currentGroup?.status != 'completed' &&
          next.currentGroup?.status == 'completed') {
        loadResults();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        title: const Text('Results'),
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
              Icons.emoji_events,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: _areResultsReady ? const ResultsView() : const WaitingView(),
    );
  }
}
