import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../models/driver_session.dart';
import '../models/predefined_route.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_session_provider.dart';
import '../providers/driver_history_provider.dart';
import '../services/dashboard_metrics_service.dart';
import '../services/route_service.dart';
import '../services/trip_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final RouteService _routeService = RouteService();
  final TripService _tripService = TripService();
  PredefinedRoute? _assignedRoute;
  String? _driverId;
  bool _loadingAssigned = true;
  int _summaryRefreshNonce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignedRoute();
    });
  }

  Future<void> _loadAssignedRoute() async {
    final profileId = context.read<AuthProvider>().currentUser?.id;
    if (profileId == null || profileId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _assignedRoute = null;
        _driverId = null;
        _loadingAssigned = false;
      });
      return;
    }
    final driverId = await _tripService.getDriverIdForProfile(profileId);
    final route = await _routeService.getAssignedRouteForDriver(profileId);
    if (mounted) {
      setState(() {
        _driverId = driverId;
        _assignedRoute = route;
        _loadingAssigned = false;
      });
    }
  }

  PredefinedRoute _outboundRouteFrom(PredefinedRoute base) {
    return PredefinedRoute(
      id: base.id,
      displayName: base.displayName,
      stops: List.of(base.stops.reversed),
    );
  }

  DriverSession _sessionFromActiveTripRow(Map<String, dynamic> row) {
    final route = _assignedRoute;
    final startedAtRaw = row['started_at'] as String?;
    final startedAt = startedAtRaw == null
        ? DateTime.now()
        : DateTime.tryParse(startedAtRaw) ?? DateTime.now();
    final currentStopIndex = row['current_stop_index'] is int
        ? row['current_stop_index'] as int
        : 0;
    final routeId = row['route_id'] as String? ?? route?.id ?? '';
    final tripId = row['id'] as String? ?? 'active_trip';
    return DriverSession(
      sessionId: tripId,
      tripId: tripId,
      routeId: routeId,
      routeDisplayName: route?.displayName ?? 'Active trip',
      stops: route?.stops ?? const [],
      driverCode: '—',
      startedAt: startedAt,
      currentStopIndex: currentStopIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<DriverHistoryProvider>().loadSessions();
        await _loadAssignedRoute();
        if (mounted) {
          setState(() => _summaryRefreshNonce++);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Consumer<AuthProvider>(
              builder: (context, auth, _) => _SummaryCard(
                driverProfileId: auth.currentUser?.id,
                refreshNonce: _summaryRefreshNonce,
              ),
            ),
            const SizedBox(height: 24),
            Consumer<DriverSessionProvider>(
              builder: (context, sessionProvider, _) {
                if (sessionProvider.hasActiveSession) {
                  return _ActiveRideCard(
                    session: sessionProvider.activeSession!,
                  );
                }
                if (_driverId != null && _driverId!.isNotEmpty) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _tripService.watchActiveTripsForDriver(_driverId!),
                    initialData: const <Map<String, dynamic>>[],
                    builder: (context, snapshot) {
                      final activeTrips =
                          snapshot.data ?? const <Map<String, dynamic>>[];
                      final hasActiveTrip = activeTrips.isNotEmpty;
                      if (hasActiveTrip) {
                        final activeSession =
                            _sessionFromActiveTripRow(activeTrips.first);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          context
                              .read<DriverSessionProvider>()
                              .syncActiveSessionFromRealtime(activeSession);
                        });
                        return _ActiveRideCard(
                          session: activeSession,
                        );
                      }
                      return _AssignedRouteAndStart(
                        assignedRoute: _assignedRoute,
                        loading: _loadingAssigned,
                        onStartInbound: _assignedRoute == null
                            ? null
                            : () async {
                                final profileId =
                                    context.read<AuthProvider>().currentUser?.id;
                                if (profileId == null || profileId.isEmpty) return;
                                final result =
                                    await sessionProvider.startSession(
                                  route: _assignedRoute!,
                                  profileId: profileId,
                                  direction: 'inbound',
                                );
                                if (!context.mounted) return;
                                if (!result.ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.message ??
                                            TripService.activeTripBlockedMessage,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(context).pushNamed(RouteNames.activeRide);
                              },
                        onStartOutbound: _assignedRoute == null
                            ? null
                            : () async {
                                final profileId =
                                    context.read<AuthProvider>().currentUser?.id;
                                if (profileId == null || profileId.isEmpty) return;
                                final result =
                                    await sessionProvider.startSession(
                                  route: _outboundRouteFrom(_assignedRoute!),
                                  profileId: profileId,
                                  direction: 'outbound',
                                );
                                if (!context.mounted) return;
                                if (!result.ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.message ??
                                            TripService.activeTripBlockedMessage,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(context).pushNamed(RouteNames.activeRide);
                              },
                      );
                    },
                  );
                }
                return _AssignedRouteAndStart(
                  assignedRoute: _assignedRoute,
                  loading: _loadingAssigned,
                  onStartInbound: _assignedRoute == null
                      ? null
                      : () async {
                          final profileId =
                              context.read<AuthProvider>().currentUser?.id;
                          if (profileId == null || profileId.isEmpty) return;
                          final result =
                              await sessionProvider.startSession(
                            route: _assignedRoute!,
                            profileId: profileId,
                            direction: 'inbound',
                          );
                          if (!context.mounted) return;
                          if (!result.ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.message ??
                                      TripService.activeTripBlockedMessage,
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pushNamed(RouteNames.activeRide);
                        },
                  onStartOutbound: _assignedRoute == null
                      ? null
                      : () async {
                          final profileId =
                              context.read<AuthProvider>().currentUser?.id;
                          if (profileId == null || profileId.isEmpty) return;
                          final result =
                              await sessionProvider.startSession(
                            route: _outboundRouteFrom(_assignedRoute!),
                            profileId: profileId,
                            direction: 'outbound',
                          );
                          if (!context.mounted) return;
                          if (!result.ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.message ??
                                      TripService.activeTripBlockedMessage,
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pushNamed(RouteNames.activeRide);
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({
    required this.driverProfileId,
    required this.refreshNonce,
  });

  final String? driverProfileId;
  final int refreshNonce;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  final DashboardMetricsService _metricsService = DashboardMetricsService();
  bool _loadingMetrics = true;
  int _todayTrips = 0;
  int _todayRides = 0;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void didUpdateWidget(covariant _SummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverProfileId != widget.driverProfileId ||
        oldWidget.refreshNonce != widget.refreshNonce) {
      _loadMetrics();
    }
  }

  Future<void> _loadMetrics() async {
    if (!mounted) return;
    setState(() => _loadingMetrics = true);

    final profileId = widget.driverProfileId;
    if (profileId == null || profileId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _todayTrips = 0;
        _todayRides = 0;
        _loadingMetrics = false;
      });
      return;
    }

    try {
      final metrics = await _metricsService.fetchTodayMetricsForProfile(profileId);
      if (!mounted) return;
      setState(() {
        _todayTrips = metrics.todayTrips;
        _todayRides = metrics.todayRidesCollected;
        _loadingMetrics = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todayTrips = 0;
        _todayRides = 0;
        _loadingMetrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primaryLight.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.today_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Today',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                if (_loadingMetrics) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                    value: '$_todayTrips',
                        label: 'Trips',
                        icon: Icons.route_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatPill(
                    value: '$_todayRides',
                        label: 'Rides collected',
                        icon: Icons.confirmation_number_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActiveRideCard extends StatelessWidget {
  const _ActiveRideCard({
    required this.session,
  });

  final DriverSession session;

  @override
  Widget build(BuildContext context) {
    final currentStop = session.currentStop?.name ?? '—';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride in progress',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.routeDisplayName,
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Now at $currentStop',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.activeRide),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedRouteAndStart extends StatelessWidget {
  const _AssignedRouteAndStart({
    required this.assignedRoute,
    required this.loading,
    required this.onStartInbound,
    required this.onStartOutbound,
  });

  final PredefinedRoute? assignedRoute;
  final bool loading;
  final VoidCallback? onStartInbound;
  final VoidCallback? onStartOutbound;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (assignedRoute == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.route_rounded,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No route assigned',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wait for admin to assign you a route.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    final route = assignedRoute!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.assistant_direction_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned route',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.displayName,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DirectionChip(
              title: 'Start trip',
              direction: 'Inbound',
              icon: Icons.arrow_forward_rounded,
              onTap: onStartInbound,
            ),
            const SizedBox(height: 12),
            _DirectionChip(
              title: 'Start trip',
              direction: 'Outbound',
              icon: Icons.arrow_back_rounded,
              onTap: onStartOutbound,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({
    required this.title,
    required this.direction,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String direction;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      direction,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
