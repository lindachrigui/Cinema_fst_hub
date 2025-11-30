import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'matching_detail_screen.dart';
import 'home_screen.dart';
import 'favourite_movies_screen.dart';
import 'profile_screen.dart';
import '../services/matching_service.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  int _selectedIndex = 1;
  final MatchingService _matchingService = MatchingService();
  List<Map<String, dynamic>> _matchingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchingUsers();
  }

  Future<void> _loadMatchingUsers() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final allMatches = await _matchingService.findMatchingUsers(limit: 50);
        // Filtrer ceux avec plus de 75% de correspondance
        final matches = allMatches
            .where((m) => m['matchPercentage'] >= 75)
            .toList();

        // Calculer le nombre de films en commun pour chaque utilisateur
        for (var match in matches) {
          final commonMovies = await _matchingService.getCommonMovies(
            match['id'],
          );
          match['commonMoviesCount'] = commonMovies.length;
          match['userId'] = match['id'];
          match['displayName'] = match['name'];
        }

        setState(() {
          _matchingUsers = matches;
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
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FavouriteMoviesScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'UTILISATEURS AVEC PLUS DE 75% DE CORRESPONDANCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Users List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B46C1),
                      ),
                    )
                  : _matchingUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: Colors.grey[700],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune correspondance trouvée',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez plus de films à vos favoris',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatchingUsers,
                      color: const Color(0xFF6B46C1),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount: _matchingUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(_matchingUsers[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.movie_outlined,
                  label: 'Movies',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onNavItemTapped(0),
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  label: 'Match',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onNavItemTapped(1),
                ),
                _buildNavItem(
                  icon: Icons.favorite_outline,
                  label: 'Favourite',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onNavItemTapped(2),
                ),
                _buildNavItem(
                  icon: Icons.more_horiz,
                  label: '',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onNavItemTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final matchPercentage = user['matchPercentage'] ?? 0;
    final commonMoviesCount = user['commonMoviesCount'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchingDetailScreen(
              userId: user['userId'],
              userName: user['displayName'] ?? user['email'],
              matchPercentage: matchPercentage,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: matchPercentage >= 90
                ? const Color(0xFF6B46C1)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Match Percentage Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: matchPercentage >= 90
                    ? const Color(0xFF6B46C1)
                    : const Color(0xFF2A2A2A),
              ),
              child: Center(
                child: Text(
                  '${matchPercentage.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['displayName'] ?? user['email'] ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFF6B46C1),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$commonMoviesCount films en commun',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            if (label.isNotEmpty && isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
