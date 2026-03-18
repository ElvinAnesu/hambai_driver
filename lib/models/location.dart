/// A stop/location on a route.
class Location {
  final String id;
  final String name;
  final String? address;

  const Location({
    required this.id,
    required this.name,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
      };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
      );
}
