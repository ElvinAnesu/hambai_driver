import 'package:flutter/material.dart';

import '../utils/driver_app_refresh.dart';

/// App bar action: refresh trip history and active trip state from the server.
class AppBarRefreshButton extends StatefulWidget {
  const AppBarRefreshButton({super.key});

  @override
  State<AppBarRefreshButton> createState() => _AppBarRefreshButtonState();
}

class _AppBarRefreshButtonState extends State<AppBarRefreshButton> {
  bool _busy = false;

  Future<void> _onPressed() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      await refreshDriverAppData(context);
    } catch (e, st) {
      debugPrint('AppBarRefreshButton: $e\n$st');
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Could not refresh. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).appBarTheme.foregroundColor;

    return IconButton(
      tooltip: 'Refresh',
      onPressed: _busy ? null : _onPressed,
      icon: _busy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            )
          : const Icon(Icons.refresh),
    );
  }
}
