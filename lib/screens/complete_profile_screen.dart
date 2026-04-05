import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/route_names.dart';
import '../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../core/widgets/app_bar_refresh_button.dart';
import '../core/widgets/loading_indicator.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user?.fullName != null) _nameController.text = user!.fullName!;
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().updateProfile(
          fullName: _nameController.text.trim(),
      avatarUrl: _avatarUrl,
        );
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.home,
      (route) => false,
    );
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;
    setState(() => _avatarUrl = image.path);
  }

  ImageProvider<Object>? _avatarProvider() {
    if (_avatarUrl == null || _avatarUrl!.isEmpty) return null;
    final avatar = _avatarUrl!;
    if (avatar.startsWith('http') || avatar.startsWith('blob:')) {
      return NetworkImage(avatar);
    }
    return FileImage(File(avatar));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: const [AppBarRefreshButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    "Add your name so passengers can see who's driving.",
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: _avatarProvider(),
                          child: _avatarProvider() == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _pickProfileImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Add profile picture'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                    ),
                    validator: Validators.fullName,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 32),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.isLoading) {
                        return const LoadingIndicator();
                      }
                      return FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Continue'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
