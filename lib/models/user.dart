import 'model_parsers.dart';

class User {
  const User({required this.id, required this.name})
    : assert(id != ''),
      assert(name != '');

  final String id;
  final String name;

  User copyWith({String? id, String? name}) {
    return User(id: id ?? this.id, name: name ?? this.name);
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: parseRequiredString(map['id'], 'id'),
      name: parseRequiredString(map['name'], 'name'),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is User &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name;
  }

  @override
  int get hashCode {
    return Object.hash(id, name);
  }
}
