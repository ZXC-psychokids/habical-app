import 'model_parsers.dart';

class Category {
  const Category({required this.id, required this.name})
    : assert(id != ''),
      assert(name != '');

  final String id;
  final String name;

  Category copyWith({String? id, String? name}) {
    return Category(id: id ?? this.id, name: name ?? this.name);
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
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
        other is Category &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name;
  }

  @override
  int get hashCode {
    return Object.hash(id, name);
  }
}
