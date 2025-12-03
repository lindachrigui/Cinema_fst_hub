import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/user_service.dart';
import '../services/cloudinary_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_text_field.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final UserService _userService = UserService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _currentProfile;
  String? _newPhotoPath;
  Uint8List? _webImageBytes;

  // Helper pour ajouter cache-busting et forcer le rechargement
  String _getImageUrl(String url) {
    if (url.isEmpty) return url;

    // Ajouter un paramètre de cache-busting avec timestamp
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}cb=$cacheBuster';
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _userService.getUserById(user.uid);
        setState(() {
          _currentProfile = profile;
          _displayNameController.text = profile?.displayName ?? '';
          _bioController.text = profile?.bio ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Loading error: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300, // Réduit pour upload plus rapide
        maxHeight: 300,
        imageQuality: 60, // Compression plus agressive
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newPhotoPath = pickedFile.path;
          _webImageBytes = bytes;
        });

        // Afficher la taille de l'image
        final sizeInKB = (bytes.length / 1024).toStringAsFixed(1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected ($sizeInKB KB)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Selection error: $e')));
      }
    }
  }

  Future<void> _handleUpdateProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? photoURL = _currentProfile?.photoURL;

        // Upload new photo if selected
        if (_newPhotoPath != null && _webImageBytes != null) {
          // Afficher un message pendant l'upload
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text('Upload vers Cloudinary...'),
                  ],
                ),
                duration: Duration(minutes: 1),
              ),
            );
          }

          try {
            photoURL = await _cloudinaryService
                .uploadProfileImage(
                  imageBytes: _webImageBytes!,
                  userId: user.uid,
                )
                .timeout(
                  const Duration(
                    minutes: 1,
                  ), // 1 minute (Cloudinary est plus rapide)
                  onTimeout: () {
                    throw Exception(
                      'Upload timeout - Check your internet connection',
                    );
                  },
                );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Erreur upload: $e')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            setState(() => _isSaving = false);
            return; // Arrêter si l'upload échoue
          }
        }

        // Update Firestore user profile
        await _userService.updateUser(user.uid, {
          'displayName': _displayNameController.text.trim(),
          'bio': _bioController.text.trim(),
          if (photoURL != null) 'photoURL': photoURL,
        });

        // Update Firebase Auth display name
        await user.updateDisplayName(_displayNameController.text.trim());
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        if (mounted) {
          // Fermer tous les snackbars
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile updated successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF6B46C1),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Profile Picture
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: const Color(0xFF6B46C1),
                                child: _webImageBytes != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          _webImageBytes!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (_currentProfile?.photoURL != null &&
                                              _currentProfile!
                                                  .photoURL
                                                  .isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                _getImageUrl(
                                                  _currentProfile!.photoURL,
                                                ),
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                cacheWidth: 120,
                                                cacheHeight: 120,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                          : null,
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Text(
                                                        (_currentProfile
                                                                    ?.displayName ??
                                                                user?.email ??
                                                                'U')
                                                            .substring(0, 1)
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 36,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            )
                                          : Text(
                                              (_currentProfile?.displayName ??
                                                      user?.email ??
                                                      'U')
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B46C1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          _webImageBytes != null
                              ? 'New photo selected'
                              : 'Tap to change photo',
                          style: TextStyle(
                            color: _webImageBytes != null
                                ? Colors.green
                                : const Color(0xFF6B46C1),
                            fontSize: 14,
                            fontWeight: _webImageBytes != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Display Name
                      const Text(
                        'Display Name',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hintText: 'Your name',
                        prefixIcon: Icons.person_outline,
                        controller: _displayNameController,
                        keyboardType: TextInputType.name,
                      ),

                      const SizedBox(height: 24),

                      // Bio
                      const Text(
                        'Biography',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Tell us about yourself...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email (read-only)
                      const Text(
                        'Email',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleUpdateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B46C1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[800],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: _isSaving
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'saving...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _webImageBytes != null
                                          ? 'Save with new photo'
                                          : 'Save changes',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
