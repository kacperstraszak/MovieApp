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
  RealtimeChannel? _membersChannel;

  @override
  GroupState build() {
    ref.onDispose(() {
      _membersChannel?.unsubscribe();
    });
    return const GroupState();
  }

  Future<String?> createGroup() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final groupCode = getRandomString(20);

      final groupData = await supabase
          .from('groups')
          .insert({
            'code': groupCode,
            'admin_id': userId,
          })
          .select()
          .single();

      final group = Group.fromJson(groupData);

      await supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
      });

      state = state.copyWith(
        currentGroup: group,
        isLoading: false,
      );

      _subscribeToMembers(group.id, group.adminId);

      await _loadMembers(group.id, group.adminId);

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
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

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

      final existingMember = await supabase
          .from('group_members')
          .select()
          .eq('group_id', group.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember == null) {
        await supabase.from('group_members').insert({
          'group_id': group.id,
          'user_id': userId,
        });
      }

      state = state.copyWith(
        currentGroup: group,
        isLoading: false,
      );

      _subscribeToMembers(group.id, group.adminId);

      await _loadMembers(group.id, group.adminId);

      return group.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to join group: $e',
      );
      return null;
    }
  }

  Future<void> _loadMembers(String groupId, String adminId) async {
    try {
      final membersData = await supabase.from('group_members').select('''
            user_id,
            joined_at,
            profiles!inner(username, imageurl, email)
          ''').eq('group_id', groupId);

      final members = (membersData as List).map((data) {
        return GroupMember.fromJson(data, adminId);
      }).toList();

      members.sort((a, b) {
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return (a.joinedAt ?? DateTime.now())
            .compareTo(b.joinedAt ?? DateTime.now());
      });

      state = state.copyWith(members: members);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load members: $e',
      );
    }
  }

  void _subscribeToMembers(String groupId, String adminId) {
    _membersChannel?.unsubscribe();

    _membersChannel = supabase
        .channel('group_members_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            _loadMembers(groupId, adminId);
          },
        )
        .subscribe();
  }

  Future<void> leaveGroup() async {
    final group = state.currentGroup;
    final userId = supabase.auth.currentUser?.id;

    if (group == null || userId == null) return;

    try {
      if (group.adminId == userId) {
        await supabase
            .from('groups')
            .update({'is_active': false}).eq('id', group.id);
      }

      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', group.id)
          .eq('user_id', userId);

      _membersChannel?.unsubscribe();
      state = const GroupState();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to leave group: $e',
      );
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
