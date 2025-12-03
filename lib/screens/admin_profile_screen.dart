import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/favorite_service.dart';
import '../models/user_model.dart';
import 'sign_in_screen.dart';
import 'update_profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_films_screen.dart';
import 'admin_users_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  int _selectedIndex = 3; // Nouvel onglet pour profil
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FavoriteService _favoriteService = FavoriteService();

  UserModel? _userProfile;
  int _favoritesCount = 0;
  bool _isLoading = true;
  String _memberSince = '0m';

  // Helper pour ajouter cache-busting et forcer le rechargement
  String _getImageUrl(String url) {
    if (url.isEmpty) return url;

    // Ajouter un paramètre de cache-busting avec timestamp
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    String urlWithCache = '$url${separator}cb=$cacheBuster';

    return urlWithCache;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _userService.getUserById(user.uid);
        final count = await _favoriteService.getFavoritesCount();

        setState(() {
          _userProfile = profile;
          _favoritesCount = count;
          _memberSince = _calculateMemberSince(profile?.createdAt);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminFilmsScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _calculateMemberSince(DateTime? createdAt) {
    if (createdAt == null) return '0m';

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays < 30) {
      return '${difference.inDays}j';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}m';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}a';
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    }
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
            : Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
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
                          'Profil Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFF6B46C1),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UpdateProfileScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadUserData();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Profile Picture
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF6B46C1),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      _userProfile?.photoURL != null &&
                                          _userProfile!.photoURL.isNotEmpty
                                      ? Image.network(
                                          _getImageUrl(_userProfile!.photoURL),
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Color(
                                                          0xFF6B46C1,
                                                        ),
                                                      ),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Text(
                                                  (_userProfile?.displayName ??
                                                          user?.email ??
                                                          'A')
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          color: const Color(0xFF6B46C1),
                                          child: Center(
                                            child: Text(
                                              (_userProfile?.displayName ??
                                                      user?.email ??
                                                      'A')
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6B46C1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Name
                          Text(
                            _userProfile?.displayName ??
                                user?.displayName ??
                                'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Bio
                          if (_userProfile?.bio != null &&
                              _userProfile!.bio.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                _userProfile!.bio,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Stats Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Color(0xFF6B46C1),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _favoritesCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Favoris',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.white24,
                                ),
                                Column(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF6B46C1),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _memberSince,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Membre depuis',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Email Info
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user?.email ?? 'Non renseigné',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Log out button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40.0,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _handleLogout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B46C1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Déconnexion',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Navigation (Admin)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: _onNavItemTapped,
                      backgroundColor: Colors.transparent,
                      selectedItemColor: const Color(0xFF6B46C1),
                      unselectedItemColor: Colors.grey,
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.dashboard),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.movie),
                          label: 'Films',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.people),
                          label: 'Users',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person),
                          label: 'Profil',
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
