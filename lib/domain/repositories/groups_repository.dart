import '../entities/group.dart';

abstract class GroupsRepository {
  Future<Group> createGroup({
    required String name,
    required String description,
    required bool isPrivate,
    String? rules,
    String? avatarUrl,
    String? coverUrl,
  });
  Future<({List<Group> items, String? nextCursor})> getMyGroups({
    String? cursor,
    int limit = 20,
  });
  Future<Group> getGroup(String groupId);
  Future<bool> joinGroup(String groupId);
  Future<bool> leaveGroup(String groupId);
}
