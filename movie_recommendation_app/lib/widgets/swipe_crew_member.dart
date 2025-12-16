import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/models/crew_member.dart';
import 'package:movie_recommendation_app/screens/crew_member_details.dart';

class SwipeCrewMemberElement extends StatelessWidget {
  const SwipeCrewMemberElement({super.key, required this.crewMember});

  final CrewMember crewMember;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => CrewMemberDetailsScreen(crewMember: crewMember),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag:
                  crewMember.id, 
              child: Image.network(
                crewMember.profilePath ??
                    'https://placehold.co/500x750?text=No+Image',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.person, size: 80),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crewMember.name,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    crewMember.department,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
