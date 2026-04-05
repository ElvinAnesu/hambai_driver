import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_bar_refresh_button.dart';
import '../core/theme/app_text_styles.dart';
import '../services/incidence_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();
  final IncidenceService _incidenceService = IncidenceService();

  static const List<String> _incidenceTypes = [
    'Accident',
    'Breakdown',
    'Traffic obstruction',
    'Passenger issue',
    'Route blockage',
    'Other',
  ];

  String _selectedType = _incidenceTypes.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitIncidence() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final details = _detailsController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await _incidenceService.submitIncidence(
        incidenceType: _selectedType,
        details: details,
      );
      if (!mounted) return;
      _detailsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidence updated successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit incidence')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidences'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: const [AppBarRefreshButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Log incidents during duty such as accidents, breakdowns, and route issues.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Incidence type',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: _incidenceTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedType = value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceBright,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Details',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened...',
                      filled: true,
                      fillColor: AppColors.surfaceBright,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please add incident details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_isSubmitting)
                    const Center(child: CircularProgressIndicator())
                  else
                    FilledButton.icon(
                      onPressed: _submitIncidence,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Record incidence'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
