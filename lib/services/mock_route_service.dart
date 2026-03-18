import '../models/location.dart';
import '../models/predefined_route.dart';

/// Mock predefined routes for driver selection (no backend).
class MockRouteService {
  static final List<PredefinedRoute> _routes = [
    PredefinedRoute(
      id: 'route_1',
      displayName: 'Harare CBD – Avondale',
      stops: [
        const Location(id: 's1', name: 'Harare CBD', address: 'Corner of Jason Moyo & First St'),
        const Location(id: 's2', name: 'Avondale Shops', address: 'Avondale Shopping Centre'),
        const Location(id: 's3', name: 'Borrowdale', address: 'Borrowdale Village'),
      ],
    ),
    PredefinedRoute(
      id: 'route_2',
      displayName: 'Mbare – CBD – Highlands',
      stops: [
        const Location(id: 's4', name: 'Mbare Musika', address: 'Mbare Bus Terminus'),
        const Location(id: 's5', name: 'Harare CBD', address: 'Fourth Street'),
        const Location(id: 's6', name: 'Highlands Shops', address: 'Highlands Shopping Centre'),
      ],
    ),
    PredefinedRoute(
      id: 'route_3',
      displayName: 'Epworth – CBD',
      stops: [
        const Location(id: 's7', name: 'Epworth', address: 'Epworth Centre'),
        const Location(id: 's8', name: 'Harare CBD', address: 'Robert Mugabe Rd'),
      ],
    ),
  ];

  Future<List<PredefinedRoute>> getPredefinedRoutes() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.from(_routes);
  }

  Future<PredefinedRoute?> getRouteById(String routeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return _routes.firstWhere((r) => r.id == routeId);
    } catch (_) {
      return null;
    }
  }

  /// Mock: route assigned to this driver by admin (first route).
  Future<PredefinedRoute?> getAssignedRouteForDriver() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_routes.isEmpty) return null;
    return _routes.first;
  }
}
