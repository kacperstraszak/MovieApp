import 'package:movie_recommendation_app/models/group.dart';
import 'package:movie_recommendation_app/models/group_member.dart';

class GroupState {
  final Group? currentGroup;
  final List<GroupMember> members;
  final bool isLoading;
  final String? errorMessage;

  const GroupState({
    this.currentGroup,
    this.members = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  GroupState copyWith({
    Group? currentGroup,
    List<GroupMember>? members,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GroupState(
      currentGroup: currentGroup ?? this.currentGroup,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}