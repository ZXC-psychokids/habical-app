class FriendInviteItem {
  const FriendInviteItem({
    required this.id,
    required this.fromUserId,
    required this.fromName,
    required this.fromEmail,
    required this.sentAt,
  }) : assert(id != ''),
       assert(fromUserId != ''),
       assert(fromName != ''),
       assert(fromEmail != '');

  final String id;
  final String fromUserId;
  final String fromName;
  final String fromEmail;
  final DateTime sentAt;
}
