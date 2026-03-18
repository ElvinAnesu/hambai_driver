import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../models/predefined_route.dart';
import '../services/mock_route_service.dart';
import '../providers/driver_session_provider.dart';
import '../core/widgets/loading_indicator.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/error_state.dart';

class SelectRouteScreen extends StatefulWidget {
  const SelectRouteScreen({super.key});

  @override
  State<SelectRouteScreen> createState() => _SelectRouteScreenState();
}

class _SelectRouteScreenState extends State<SelectRouteScreen> {
  final MockRouteService _routeService = MockRouteService();
  List<PredefinedRoute> _routes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _routeService.getPredefinedRoutes();
      setState(() {
        _routes = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startSession(PredefinedRoute route) {
    context.read<DriverSessionProvider>().startSession(route);
    Navigator.of(context).pushReplacementNamed(RouteNames.activeRide);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select route'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _routes.isEmpty
                  ? const EmptyState(
                      message: 'No routes available.',
                      icon: Icons.route,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _routes.length,
                      itemBuilder: (context, i) {
                        final route = _routes[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(
                                Icons.route,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              route.displayName,
                              style: AppTextStyles.bodyLarge,
                            ),
                            subtitle: Text(
                              '${route.stops.length} stops',
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _startSession(route),
                          ),
                        );
                      },
                    ),
    );
  }
}
