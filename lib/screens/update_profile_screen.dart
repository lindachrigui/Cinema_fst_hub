import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _currentProfile;
  String? _newPhotoPath;

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
        ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newPhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de sélection: $e')));
      }
    }
  }

  Future<void> _handleUpdateProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le nom est requis')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? photoURL = _currentProfile?.photoURL;

        // Upload new photo if selected
        if (_newPhotoPath != null) {
          final bytes = await File(_newPhotoPath!).readAsBytes();
          photoURL = await _storageService.uploadProfileImage(bytes, user.uid);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès!'),
              backgroundColor: Color(0xFF6B46C1),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
                            'Modifier le profil',
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
                                backgroundImage: _newPhotoPath != null
                                    ? FileImage(File(_newPhotoPath!))
                                          as ImageProvider
                                    : (_currentProfile?.photoURL != null
                                          ? NetworkImage(
                                              _currentProfile!.photoURL!,
                                            )
                                          : null),
                                child:
                                    _newPhotoPath == null &&
                                        _currentProfile?.photoURL == null
                                    ? Text(
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
                                      )
                                    : null,
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

                      const Center(
                        child: Text(
                          'Toucher pour changer la photo',
                          style: TextStyle(
                            color: Color(0xFF6B46C1),
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Display Name
                      const Text(
                        'Nom d\'affichage',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hintText: 'Votre nom',
                        prefixIcon: Icons.person_outline,
                        controller: _displayNameController,
                        keyboardType: TextInputType.name,
                      ),

                      const SizedBox(height: 24),

                      // Bio
                      const Text(
                        'Biographie',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Parlez-nous de vous...',
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
                      CustomButton(
                        text: _isSaving
                            ? 'Enregistrement...'
                            : 'Enregistrer les modifications',
                        onPressed: _isSaving ? () {} : _handleUpdateProfile,
                        isLoading: _isSaving,
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
