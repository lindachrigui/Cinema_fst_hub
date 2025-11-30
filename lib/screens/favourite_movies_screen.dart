import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_screen.dart';
import 'home_screen.dart';
import 'matching_screen.dart';
import '../services/favorite_service.dart';
import '../services/moviedb_api_service.dart';
import '../models/api_movie_model.dart';
import 'api_movie_detail_screen.dart';

class FavouriteMoviesScreen extends StatefulWidget {
  const FavouriteMoviesScreen({super.key});

  @override
  State<FavouriteMoviesScreen> createState() => _FavouriteMoviesScreenState();
}

class _FavouriteMoviesScreenState extends State<FavouriteMoviesScreen> {
  int _selectedIndex = 2;
  final FavoriteService _favoriteService = FavoriteService();
  final MovieDbApiService _apiService = MovieDbApiService();

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      // Navigate to Matching Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MatchingScreen()),
      );
    } else if (index == 2) {
      // Already on Favourite Movies, just update selection
      setState(() {
        _selectedIndex = index;
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HEY, ${user?.displayName?.split(' ').first.toUpperCase() ?? 'USER'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Mes Favoris',
                        style: TextStyle(
                          color: Color(0xFF6B46C1),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // My Favourite Movies Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'My Favourite Movies',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Favourite Movies Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _favoriteService.getUserFavorites(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6B46C1),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final favorites = snapshot.data ?? [];

                    if (favorites.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun film favori',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ajoutez des films à vos favoris\npour les retrouver ici',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        return _buildMovieCard(favorites[index]);
                      },
                    );
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

  Widget _buildMovieCard(Map<String, dynamic> favorite) {
    return GestureDetector(
      onTap: () async {
        // Récupérer les détails du film depuis l'API
        try {
          final movieDetails = await _apiService.getMovieDetails(
            favorite['movieId'],
          );
          if (movieDetails != null) {
            final movieData = _apiService.convertToMovieModel(movieDetails);
            final movie = ApiMovie.fromJson(movieData);

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApiMovieDetailScreen(movie: movie),
                ),
              );
            }
          }
        } catch (e) {
          print('Erreur chargement détails: $e');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie Poster
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Movie image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[850],
                      child:
                          favorite['movieImage'] != null &&
                              favorite['movieImage'].toString().isNotEmpty
                          ? Image.network(
                              favorite['movieImage'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.movie,
                                    color: Colors.grey[700],
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.movie,
                                color: Colors.grey[700],
                                size: 40,
                              ),
                            ),
                    ),
                  ),

                  // Play button overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                  // Favorite star indicator
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Color(0xFF6B46C1),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Movie Title
          Text(
            favorite['movieTitle'] ?? 'Sans titre',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 4),
              Text(
                (favorite['movieRating'] ?? 0.0).toStringAsFixed(1),
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ),
        ],
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
