import 'model_parsers.dart';

class AppUser {
  const AppUser({required this.id, required this.name})
    : assert(id != ''),
      assert(name != '');

  final String id;
  final String name;

  AppUser copyWith({String? id, String? name}) {
    return AppUser(id: id ?? this.id, name: name ?? this.name);
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
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
        other is AppUser &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name;
  }

  @override
  int get hashCode {
    return Object.hash(id, name);
  }
}
