import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/user_avatar.dart';
import '../providers/auth_provider.dart';
import '../services/driver_rating_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _maxAvatarBytes = 1024 * 1024;
  final ImagePicker _imagePicker = ImagePicker();
  final DriverRatingService _driverRatingService = DriverRatingService();
  late final Future<double?> _ratingFuture;

  @override
  void initState() {
    super.initState();
    _ratingFuture = _driverRatingService.getAverageRatingForCurrentDriver();
  }

  Future<void> _pickAndUploadAvatar() async {
    final selected = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (selected == null) return;

    final fileSize = await selected.length();
    if (fileSize >= _maxAvatarBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be smaller than 1MB')),
      );
      return;
    }

    final bytes = await selected.readAsBytes();
    final ext = selected.name.split('.').last.toLowerCase();
    final allowed = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    final contentType = allowed[ext];
    if (contentType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only JPG, PNG, and WEBP are allowed')),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().uploadAvatar(
        bytes: bytes,
        fileExtension: ext,
        contentType: contentType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile picture')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              UserAvatar(
                avatarUrl: user?.avatarUrl,
                displayName: user?.fullName,
                size: 80,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: auth.isLoading ? null : _pickAndUploadAvatar,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Upload profile picture'),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile details',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Name',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.fullName ?? 'Not set',
                        style: AppTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.phone ?? AppConstants.countryCode,
                        style: AppTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Driver rating',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<double?>(
                        future: _ratingFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const _RatingStars(rating: 0);
                          }
                          final rating = snapshot.data;
                          if (rating == null) {
                            return const _RatingStars(rating: 0);
                          }
                          return _RatingStars(rating: rating);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final normalized = rating.clamp(0, 5).toDouble();
    final roundedToHalf = (normalized * 2).round() / 2;
    final stars = List<Widget>.generate(5, (index) {
      final starPosition = index + 1;
      if (roundedToHalf >= starPosition) {
        return const Icon(Icons.star, color: Colors.amber, size: 20);
      }
      if (roundedToHalf >= starPosition - 0.5) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 20);
      }
      return const Icon(Icons.star_border, color: Colors.amber, size: 20);
    });

    return Row(
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text(
          '${normalized.toStringAsFixed(1)} / 5.0',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
