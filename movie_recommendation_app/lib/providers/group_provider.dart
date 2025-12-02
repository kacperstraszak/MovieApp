import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/functions/random_string.dart';
import 'package:movie_recommendation_app/models/group.dart';
import 'package:movie_recommendation_app/models/group_member.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class GroupNotifier extends Notifier<GroupState> {
  RealtimeChannel? _groupChannel;

  @override
  GroupState build() {
    ref.onDispose(() {
      _leaveChannel();
    });
    return const GroupState();
  }

  Future<String?> createGroup() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final groupCode = getRandomString(20);

      final groupData = await supabase
          .from('groups')
          .insert({
            'code': groupCode,
            'admin_id': user.id,
            'status': 'lobby',
          })
          .select()
          .single();

      final group = Group.fromJson(groupData);

      state = state.copyWith(
        currentGroup: group,
        isLoading: false,
      );

      await _joinGroupChannel(group.id, user.id, isAdmin: true);

      return group.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create group: $e',
      );
      return null;
    }
  }

  Future<String?> joinGroup(String groupCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final groupData = await supabase
          .from('groups')
          .select()
          .eq('code', groupCode)
          .eq('is_active', true)
          .maybeSingle();

      if (groupData == null) {
        throw Exception('Group not found or inactive');
      }

      final group = Group.fromJson(groupData);

      state = state.copyWith(
        currentGroup: group,
        isLoading: false,
      );

      await _joinGroupChannel(group.id, user.id, isAdmin: false);

      return group.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to join group: $e',
      );
      return null;
    }
  }

  Future<void> _joinGroupChannel(String groupId, String userId,
      {required bool isAdmin}) async {
    final profile = await supabase
        .from(kProfilesTable)
        .select()
        .eq(kUserIdCol, userId)
        .single();

    final username = profile['username'];
    final imageUrl = profile['image_url'];

    final myMemberInfo = GroupMember(
      userId: userId,
      username: username,
      imageUrl: imageUrl,
      isAdmin: isAdmin,
    );

    _groupChannel = supabase.channel('room_$groupId');

    _groupChannel!
        .onPresenceSync((_) {
          final presenceState = _groupChannel!.presenceState();

          final List<GroupMember> activeMembers = [];

          for (final singlePresence in presenceState) {
            for (final presence in singlePresence.presences) {
              activeMembers.add(GroupMember.fromPresence(presence.payload));
            }
          }

          activeMembers.sort((a, b) {
            if (a.isAdmin && !b.isAdmin) return -1;
            if (!a.isAdmin && b.isAdmin) return 1;
            return (a.joinedAt ?? DateTime.now())
                .compareTo(b.joinedAt ?? DateTime.now());
          });

          state = state.copyWith(members: activeMembers);
        })
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'groups',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: groupId,
          ),
          callback: (payload) {
            _leaveChannel();
            state = const GroupState(
                errorMessage: 'The group has been closed by admin.');
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'groups',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: groupId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            if (newData != null) {
              final updatedGroup = Group.fromJson(newData);
              
              final newGroup = Group(
                id: updatedGroup.id,
                code: updatedGroup.code,
                adminId: updatedGroup.adminId,
                isActive: updatedGroup.isActive,
                status: updatedGroup.status,
              );
              
              state = state.copyWith(currentGroup: newGroup);
            }
          },
        )
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _groupChannel!.track(myMemberInfo.toPresencePayload());
          }
        });
  }

  Future<void> startRecommendationProcess() async {
    final group = state.currentGroup;
    if (group == null) return;

    try {
      await supabase
          .from('groups')
          .update({'status': 'recommendation_started'})
          .eq('id', group.id)
          .select()
          .single();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start recommendation: $e',
      );
    }
  }

  Future<void> leaveGroup() async {
    final group = state.currentGroup;
    final userId = supabase.auth.currentUser?.id;

    if (group == null || userId == null) return;

    try {
      if (group.adminId == userId) {
        await supabase.from('groups').delete().eq('id', group.id);
      }

      await _leaveChannel();

      state = const GroupState();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to leave group: $e',
      );
    }
  }

  Future<void> _leaveChannel() async {
    if (_groupChannel != null) {
      await _groupChannel!.untrack();
      await supabase.removeChannel(_groupChannel!);
      _groupChannel = null;
    }
  }

  bool isCurrentUserAdmin() {
    final userId = supabase.auth.currentUser?.id;
    return state.currentGroup?.adminId == userId;
  }
}

final groupProvider = NotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);
