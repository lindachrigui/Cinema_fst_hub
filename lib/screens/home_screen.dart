import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_screen.dart';
import 'favourite_movies_screen.dart';
import 'profile_screen.dart';
import 'matching_screen.dart';
import 'api_movie_detail_screen.dart';
import 'movie_detail_screen.dart';
import '../services/moviedb_api_service.dart';
import '../services/user_service.dart';
import '../services/movie_service.dart';
import '../models/api_movie_model.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final MovieDbApiService _apiService = MovieDbApiService();
  final UserService _userService = UserService();
  final MovieService _movieService = MovieService();

  List<ApiMovie> _popularMovies = [];
  List<ApiMovie> _newReleases = [];
  List<Movie> _firestoreMovies = [];
  ApiMovie? _trendingMovie;
  bool _isLoading = true;
  String? _error;
  UserModel? _currentUser;

  // Widget helper for displaying movie images with loading and error states
  Widget _buildMovieImage(String imageUrl, {double iconSize = 40}) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF1E1E1E),
        child: Center(
          child: Icon(
            Icons.movie,
            color: const Color(0xFF6B46C1),
            size: iconSize,
          ),
        ),
      );
    }

    // Use CORS proxy for Amazon images to avoid CORS errors
    String proxyUrl = imageUrl;
    if (imageUrl.contains('m.media-amazon.com') ||
        imageUrl.contains('amazon')) {
      // Use a CORS proxy service
      proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}';
    }

    return Image.network(
      proxyUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF1E1E1E),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF6B46C1),
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Silently handle CORS errors - show placeholder instead
        return Container(
          color: const Color(0xFF1E1E1E),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_outlined,
                  color: const Color(0xFF6B46C1),
                  size: iconSize,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Image',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFirestoreMovies();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadUserProfile(), _loadMovies()]);
  }

  void _loadFirestoreMovies() {
    _movieService.getAllMovies().listen((movies) {
      if (mounted) {
        setState(() {
          _firestoreMovies = movies;
        });
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final user = await _userService.getUserById(userId);
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement profil: $e');
    }
  }

  Future<void> _loadMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger films populaires
      final popularData = await _apiService.getPopularMovies();

      if (popularData.isEmpty) {
        setState(() {
          _error = 'No movies available at the moment';
          _isLoading = false;
        });
        return;
      }

      final popular = <ApiMovie>[];
      for (var json in popularData) {
        try {
          final movieData = _apiService.convertToMovieModel(json);
          final movie = ApiMovie.fromJson(movieData);
          popular.add(movie);
        } catch (e) {
          print('Erreur conversion film: $e');
          continue;
        }
      }

      // Charger nouveautés
      final newReleasesData = await _apiService.getNewReleases();
      final newMovies = <ApiMovie>[];
      for (var json in newReleasesData) {
        try {
          final movieData = _apiService.convertToMovieModel(json);
          final movie = ApiMovie.fromJson(movieData);
          newMovies.add(movie);
        } catch (e) {
          print('Erreur conversion nouveauté: $e');
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _popularMovies = popular.take(10).toList();
          _newReleases = newMovies.take(10).toList();
          _trendingMovie = popular.isNotEmpty ? popular.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des films: $e');
      if (mounted) {
        setState(() {
          _error = 'Unable to load movies.\nCheck your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on index
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MatchingScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FavouriteMoviesScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
    // Index 0 is already Home Screen, no navigation needed
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
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF6B46C1),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HEY, ${_currentUser?.displayName.split(' ').first.toUpperCase() ?? user?.displayName?.split(' ').first.toUpperCase() ?? user?.email?.split('@').first.toUpperCase() ?? 'USER'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'Bienvenue >',
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
                                        builder: (context) =>
                                            const SearchScreen(),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_outline,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Trending Movie Card (from API)
                        if (_trendingMovie != null)
                          Container(
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF7B2CBF), Color(0xFFE0AAFF)],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Background Image from API
                                if (_trendingMovie!.imageUrl.isNotEmpty)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        _trendingMovie!.imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF7B2CBF),
                                                  Color(0xFFE0AAFF),
                                                ],
                                              ),
                                            ),
                                            child: Center(
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
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(0xFF7B2CBF),
                                                      Color(0xFFE0AAFF),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),

                                // Gradient Overlay
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Watch Trailer Button
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ApiMovieDetailScreen(
                                                      movie: _trendingMovie!,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Text(
                                                  'Watch Trailer',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      const Spacer(),

                                      // Movie Info from API
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'TRENDING',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _trendingMovie!.title
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_trendingMovie!.language.toUpperCase()}\n${_trendingMovie!.primaryGenre.toUpperCase()}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6B46C1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _trendingMovie!.rating
                                                      .toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 30),

                        // Popular Movies Section
                        Row(
                          children: [
                            const Text(
                              'Popular Movies',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Popular Movies List (from API)
                        SizedBox(
                          height: 220,
                          child: _popularMovies.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No movies available',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _popularMovies.length,
                                  itemBuilder: (context, index) {
                                    final movie = _popularMovies[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ApiMovieDetailScreen(
                                                  movie: movie,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Movie Poster from API
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF1E1E1E,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: _buildMovieImage(
                                                        movie.imageUrl,
                                                      ),
                                                    ),
                                                    // Rating Badge
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                              size: 12,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              movie.rating
                                                                  .toStringAsFixed(
                                                                    1,
                                                                  ),
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
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
                                              movie.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            // Genre
                                            Text(
                                              movie.primaryGenre,
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 10,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 30),

                        // Firestore Movies Section (Admin Added)
                        if (_firestoreMovies.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Added Movies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B46C1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_firestoreMovies.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              itemCount: _firestoreMovies.length,
                              itemBuilder: (context, index) {
                                final movie = _firestoreMovies[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MovieDetailScreen(movie: movie),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    margin: EdgeInsets.only(
                                      right: index < _firestoreMovies.length - 1
                                          ? 16
                                          : 0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Movie Poster
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E1E1E),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                children: [
                                                  movie.imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          movie.imageUrl,
                                                          width:
                                                              double.infinity,
                                                          height:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder:
                                                              (
                                                                context,
                                                                child,
                                                                loadingProgress,
                                                              ) {
                                                                if (loadingProgress ==
                                                                    null)
                                                                  return child;
                                                                return Center(
                                                                  child: CircularProgressIndicator(
                                                                    color: const Color(
                                                                      0xFF6B46C1,
                                                                    ),
                                                                    value:
                                                                        loadingProgress.expectedTotalBytes !=
                                                                            null
                                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                        : null,
                                                                  ),
                                                                );
                                                              },
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return Container(
                                                                  color: const Color(
                                                                    0xFF1E1E1E,
                                                                  ),
                                                                  child: const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .movie,
                                                                      color: Color(
                                                                        0xFF6B46C1,
                                                                      ),
                                                                      size: 50,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                        )
                                                      : Container(
                                                          color: const Color(
                                                            0xFF1E1E1E,
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons.movie,
                                                              color: Color(
                                                                0xFF6B46C1,
                                                              ),
                                                              size: 50,
                                                            ),
                                                          ),
                                                        ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.7),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                            size: 12,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            movie.rating
                                                                .toStringAsFixed(
                                                                  1,
                                                                ),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          movie.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          movie.genre,
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],

                        // New Releases Section
                        Row(
                          children: [
                            const Text(
                              'New Releases',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // New Releases List (from API)
                        SizedBox(
                          height: 220,
                          child: _newReleases.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No new releases available',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _newReleases.length,
                                  itemBuilder: (context, index) {
                                    final movie = _newReleases[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ApiMovieDetailScreen(
                                                  movie: movie,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Movie Poster from API
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF1E1E1E,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: _buildMovieImage(
                                                        movie.imageUrl,
                                                      ),
                                                    ),
                                                    // NEW Badge
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF6B46C1,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'NEW',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                              size: 12,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              movie.rating
                                                                  .toStringAsFixed(
                                                                    1,
                                                                  ),
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
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
                                              movie.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            // Year
                                            Text(
                                              movie.releaseYear.toString(),
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
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
                  label: 'Profile',
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
