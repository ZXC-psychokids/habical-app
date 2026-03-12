import 'model_parsers.dart';

class Friendship {
  const Friendship({required this.user1Id, required this.user2Id})
    : assert(user1Id != ''),
      assert(user2Id != ''),
      assert(user1Id != user2Id);

  final String user1Id;
  final String user2Id;

  Friendship copyWith({String? user1Id, String? user2Id}) {
    return Friendship(
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
    );
  }

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      user1Id: parseRequiredString(map['user1Id'], 'user1Id'),
      user2Id: parseRequiredString(map['user2Id'], 'user2Id'),
    );
  }

  Map<String, dynamic> toMap() {
    return {'user1Id': user1Id, 'user2Id': user2Id};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Friendship) {
      return false;
    }
    final sameDirection = user1Id == other.user1Id && user2Id == other.user2Id;
    final oppositeDirection =
        user1Id == other.user2Id && user2Id == other.user1Id;
    return sameDirection || oppositeDirection;
  }

  @override
  int get hashCode {
    final sorted = [user1Id, user2Id]..sort();
    return Object.hash(sorted[0], sorted[1]);
  }
}
