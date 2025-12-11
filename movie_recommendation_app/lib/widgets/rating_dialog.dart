import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _stars = 3.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'How much do you like it?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rate the movie on the scale!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 20),
          RatingBar.builder(
            initialRating: _stars,
            minRating: 0.5,
            direction: Axis.horizontal,
            allowHalfRating: true, 
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _stars = rating;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _stars),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade900.withAlpha(120),
          ),
          child: const Text(
            'Confirm',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }
}