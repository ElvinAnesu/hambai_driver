import 'location.dart';

/// Predefined route with ordered stops (for driver selection).
class PredefinedRoute {
  final String id;
  final String displayName;
  final List<Location> stops;

  const PredefinedRoute({
    required this.id,
    required this.displayName,
    required this.stops,
  });

  /// Same route in the opposite direction (e.g. CBD → Borrowdale becomes Borrowdale → CBD).
  PredefinedRoute reversed() {
    if (stops.isEmpty) return this;
    final reversedStops = List<Location>.from(stops.reversed);
    final from = reversedStops.first.name;
    final to = reversedStops.last.name;
    return PredefinedRoute(
      id: '${id}_return',
      displayName: '$from – $to',
      stops: reversedStops,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'stops': stops.map((s) => s.toJson()).toList(),
      };

  factory PredefinedRoute.fromJson(Map<String, dynamic> json) => PredefinedRoute(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        stops: (json['stops'] as List<dynamic>)
            .map((e) => Location.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
