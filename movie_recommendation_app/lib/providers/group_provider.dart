import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/functions/random_string.dart';
import 'package:movie_recommendation_app/models/group.dart';
import 'package:movie_recommendation_app/models/group_member.dart';
import 'package:movie_recommendation_app/models/group_state.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            final updatedGroup = Group.fromJson(newData);

            final newGroup = Group(
              id: updatedGroup.id,
              code: updatedGroup.code,
              adminId: updatedGroup.adminId,
              isActive: updatedGroup.isActive,
              status: updatedGroup.status,
            );

            state = state.copyWith(currentGroup: newGroup);
          },
        )
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _groupChannel!.track(myMemberInfo.toPresencePayload());
          }
        });
  }

  Future<void> changeGroupStatus(String status) async {
    final group = state.currentGroup;
    if (group == null) return;

    try {
      await supabase
          .from('groups')
          .update({'status': status})
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

  Future<void> updateAllGroupMembers({bool isFinished = false}) async {
    try {
      final presenceState = _groupChannel!.presenceState();

      final onlineUserIds = <String>{};

      for (final presenceGroup in presenceState) {
        for (final presence in presenceGroup.presences) {
          final userId = presence.payload['user_id'] as String?;
          if (userId != null) {
            onlineUserIds.add(userId);
          }
        }
      }
      final userIdList = onlineUserIds.toList();

      if (userIdList.isEmpty) {
        return;
      }

      final membersToInsert = userIdList
          .map((userId) => {
                'group_id': state.currentGroup!.id,
                'user_id': userId,
                'is_finished': isFinished,
              })
          .toList();

      await supabase.from('group_members').upsert(
            membersToInsert,
            onConflict: 'group_id,user_id',
          );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed while adding group members: $e',
      );
    }
  }

  Future<void> updateCurrentUserStatus({required bool isFinished}) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        state = state.copyWith(
          errorMessage: 'User not authenticated',
        );
        return;
      }

      await supabase
          .from('group_members')
          .update({'is_finished': isFinished})
          .eq('group_id', state.currentGroup!.id)
          .eq('user_id', currentUserId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update user status: $e',
      );
    }
  }

  Future<bool> areAllUsersFinished() async {
    try {
      final presenceState = _groupChannel!.presenceState();
      final onlineUserIds = <String>{};

      for (final presenceGroup in presenceState) {
        for (final presence in presenceGroup.presences) {
          final userId = presence.payload['user_id'] as String?;
          if (userId != null) onlineUserIds.add(userId);
        }
      }

      if (onlineUserIds.isEmpty) return false;

      final response = await supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', state.currentGroup!.id)
          .eq('is_finished', true);

      final finishedUserIds = (response as List<dynamic>)
          .map((m) => m['user_id'] as String)
          .toSet();

      return onlineUserIds.length == finishedUserIds.length &&
          onlineUserIds.every((id) => finishedUserIds.contains(id));
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to check if all users finished: $e',
      );
      return false;
    }
  }
}

final groupProvider = NotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);
