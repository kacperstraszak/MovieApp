import 'package:equatable/equatable.dart';
import 'package:movie_recommendation_app/models/group.dart';
import 'package:movie_recommendation_app/models/group_member.dart';

class GroupState extends Equatable {
  const GroupState({
    this.currentGroup,
    this.members = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final Group? currentGroup;
  final List<GroupMember> members;
  final bool isLoading;
  final String? errorMessage;

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

  @override
  List<Object?> get props => [currentGroup, members, isLoading, errorMessage];
}