import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/moviedb_api_service.dart';
import '../models/movie_model.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_add_film_screen.dart';
import 'admin_update_movie_screen.dart';
import 'admin_profile_screen.dart';

class AdminFilmsScreen extends StatefulWidget {
  const AdminFilmsScreen({super.key});

  @override
  State<AdminFilmsScreen> createState() => _AdminFilmsScreenState();
}

// Class pour représenter un film avec sa source
class MovieItem {
  final String id;
  final String title;
  final String imageUrl;
  final double rating;
  final String source; // 'api' ou 'firestore'
  final Movie? movie; // Pour les films Firestore

  MovieItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.source,
    this.movie,
  });
}

class _AdminFilmsScreenState extends State<AdminFilmsScreen> {
  int _selectedIndex = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MovieDbApiService _apiService = MovieDbApiService();

  bool _isSelectionMode = false;
  final Set<String> _selectedFilms = {};
  List<MovieItem> _allMovies = [];
  bool _isLoadingApi = true;

  // Helper pour proxy CORS et cache-busting
  String _getProxiedUrl(String url) {
    if (url.isEmpty) return url;

    // Ajouter cache-busting pour forcer le rechargement
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    String urlWithCache = '$url${separator}cb=$cacheBuster';

    // Proxy CORS pour images Amazon
    if (url.contains('m.media-amazon.com') || url.contains('amazon')) {
      return 'https://corsproxy.io/?${Uri.encodeComponent(urlWithCache)}';
    }

    return urlWithCache;
  }

  @override
  void initState() {
    super.initState();
    _loadApiMovies();
  }

  Future<void> _loadApiMovies() async {
    try {
      setState(() {
        _isLoadingApi = true;
      });

      final apiMovies = await _apiService.getPopularMovies();

      final List<MovieItem> apiMovieItems = apiMovies.map((apiMovie) {
        final converted = _apiService.convertToMovieModel(apiMovie);
        return MovieItem(
          id: 'api_${converted['id']}',
          title: converted['title'] ?? 'Untitled',
          imageUrl: converted['imageUrl'] ?? '',
          rating: (converted['rating'] ?? 0.0).toDouble(),
          source: 'api',
        );
      }).toList();

      setState(() {
        _allMovies = apiMovieItems;
        _isLoadingApi = false;
      });
    } catch (e) {
      print('Erreur chargement API: $e');
      setState(() {
        _isLoadingApi = false;
      });
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFilms.clear();
      }
    });
  }

  void _toggleFilmSelection(String filmId) {
    setState(() {
      if (_selectedFilms.contains(filmId)) {
        _selectedFilms.remove(filmId);
      } else {
        _selectedFilms.add(filmId);
      }
    });
  }

  Future<void> _deleteSelectedFilms() async {
    if (_selectedFilms.isEmpty) return;

    // Vérifier si des films API sont sélectionnés
    final apiFilms = _selectedFilms
        .where((id) => id.startsWith('api_'))
        .toList();
    if (apiFilms.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cannot delete API movies. Only added movies can be deleted.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to permanently delete ${_selectedFilms.length} movie(s)?\n\nThis action is irreversible.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Deletion in progress...'),
              ],
            ),
            backgroundColor: Color(0xFF6B46C1),
            duration: Duration(seconds: 10),
          ),
        );

        for (String filmId in _selectedFilms) {
          await _firestore.collection('movies').doc(filmId).delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedFilms.length} movie(s) deleted successfully',
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF6B46C1),
            ),
          );
          setState(() {
            _selectedFilms.clear();
            _isSelectionMode = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Erreur: $e')),
                ],
              ),
              backgroundColor: Colors.red[900],
            ),
          );
        }
      }
    }
  }

  void _navigateToAddFilm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAddFilmScreen()),
    );
  }

  void _updateSelectedFilm() async {
    if (_selectedFilms.length != 1) return;

    final filmId = _selectedFilms.first;
    if (filmId.startsWith('api_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit API movies'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Trouver le film dans la liste combinée
    MovieItem? movieItem;
    try {
      movieItem = _allMovies.firstWhere((m) => m.id == filmId);
    } catch (e) {
      print('Film non trouvé dans _allMovies: $filmId');
    }

    // Si le film n'est pas dans _allMovies, le chercher dans Firestore
    if (movieItem == null || movieItem.movie == null) {
      try {
        final doc = await _firestore.collection('movies').doc(filmId).get();
        if (!doc.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Movie not found in database'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final movie = Movie.fromFirestore(doc);

        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUpdateMovieScreen(movie: movie),
            ),
          );

          if (result == true) {
            setState(() {
              _isSelectionMode = false;
              _selectedFilms.clear();
            });
          }
        }
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    // À ce stade, movieItem existe et a un movie
    if (movieItem.movie == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data error: Movie data is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUpdateMovieScreen(movie: movieItem!.movie!),
      ),
    );

    if (result == true) {
      // Film mis à jour, rafraîchir
      setState(() {
        _isSelectionMode = false;
        _selectedFilms.clear();
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
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HEY, LINDA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminProfileScreen(),
                            ),
                          );
                        },
                        tooltip: 'My Profile',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Title and action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'List of movies',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isSelectionMode) ...[
                        if (_selectedFilms.isNotEmpty) ...[
                          ElevatedButton(
                            onPressed: _deleteSelectedFilms,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Delete'),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedFilms.length == 1 &&
                              !_selectedFilms.first.startsWith('api_'))
                            ElevatedButton(
                              onPressed: _updateSelectedFilm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B46C1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Update'),
                            ),
                          if (_selectedFilms.length == 1 &&
                              !_selectedFilms.first.startsWith('api_'))
                            const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: _toggleSelectionMode,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ] else ...[
                        ElevatedButton(
                          onPressed: _toggleSelectionMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A2A2A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Select'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _navigateToAddFilm,
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6B46C1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Movies Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('movies').snapshots(),
                builder: (context, snapshot) {
                  // Combine API movies with Firestore movies
                  List<MovieItem> combinedMovies = List.from(_allMovies);

                  if (snapshot.hasData) {
                    final firestoreMovies = snapshot.data!.docs.map((doc) {
                      final movie = Movie.fromFirestore(doc);
                      return MovieItem(
                        id: movie.id,
                        title: movie.title,
                        imageUrl: movie.imageUrl,
                        rating: movie.rating,
                        source: 'firestore',
                        movie: movie,
                      );
                    }).toList();

                    // Add Firestore movies at the beginning
                    combinedMovies.insertAll(0, firestoreMovies);
                  }

                  if (_isLoadingApi && combinedMovies.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B46C1),
                      ),
                    );
                  }

                  if (combinedMovies.isEmpty) {
                    return const Center(
                      child: Text(
                        'No movies available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: combinedMovies.length,
                    itemBuilder: (context, index) {
                      final movieItem = combinedMovies[index];
                      final isSelected = _selectedFilms.contains(movieItem.id);

                      return _buildMovieCard(
                        movieId: movieItem.id,
                        title: movieItem.title,
                        imageUrl: movieItem.imageUrl,
                        rating: movieItem.rating,
                        isSelected: isSelected,
                        source: movieItem.source,
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard({
    required String movieId,
    required String title,
    required String imageUrl,
    required double rating,
    required bool isSelected,
    required String source,
  }) {
    return GestureDetector(
      onTap: _isSelectionMode ? () => _toggleFilmSelection(movieId) : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                _getProxiedUrl(imageUrl),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: const Color(0xFF2A2A2A),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: const Color(0xFF6B46C1),
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF2A2A2A),
                                    child: const Center(
                                      child: Icon(
                                        Icons.movie,
                                        color: Color(0xFF6B46C1),
                                        size: 50,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFF2A2A2A),
                                child: const Center(
                                  child: Icon(
                                    Icons.movie,
                                    color: Color(0xFF6B46C1),
                                    size: 50,
                                  ),
                                ),
                              ),
                      ),
                      // Rating badge
                      if (rating > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Source badge (seulement si pas en mode sélection)
                      if (!_isSelectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: source == 'api'
                                  ? Colors.blue.withOpacity(0.8)
                                  : const Color(0xFF6B46C1).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              source == 'api' ? 'API' : 'ADDED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Selection badge (seulement en mode sélection)
                      if (_isSelectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6B46C1)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6B46C1)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
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
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Movies'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
