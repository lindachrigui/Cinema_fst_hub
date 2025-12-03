import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/search_service.dart';
import '../models/api_movie_model.dart';
import 'api_movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();

  List<String> _recentSearches = [];
  List<ApiMovie> _searchResults = [];
  List<Map<String, dynamic>> _firebaseResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        final searches = await _searchService.getRecentSearches(userId);
        if (mounted) {
          setState(() {
            _recentSearches = searches;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement recherches: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final results = await _searchService.searchMovies(query, userId: userId);

      final apiMovies = (results['api'] as List<dynamic>).cast<ApiMovie>();
      final firebaseMovies = (results['firebase'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _searchResults = apiMovies;
          _firebaseResults = firebaseMovies;
          _isLoading = false;
        });
      }

      await _loadRecentSearches();
    } catch (e) {
      print('Erreur recherche: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        await _searchService.clearRecentSearches(userId);
        setState(() {
          _recentSearches = [];
        });
      }
    } catch (e) {
      print('Erreur suppression recherches: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button and search bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search for a movie...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF6B46C1),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _hasSearched = false;
                                      _searchResults = [];
                                      _firebaseResults = [];
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                        onSubmitted: _performSearch,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B46C1),
                      ),
                    )
                  : _hasSearched
                  ? _buildSearchResults()
                  : _buildRecentSearches(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Color(0xFF6B46C1)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentSearches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.search_off, color: Colors.grey, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'No recent searches',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _recentSearches.length,
                itemBuilder: (context, index) {
                  final search = _recentSearches[index];
                  return ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text(
                      search,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.north_west, color: Colors.grey),
                    onTap: () {
                      _searchController.text = search;
                      _performSearch(search);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final totalResults = _searchResults.length + _firebaseResults.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              'no results for "${_searchController.text}"',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalResults result${totalResults > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (_firebaseResults.isNotEmpty) ...[
              const Text(
                'In our catalog',
                style: TextStyle(
                  color: Color(0xFF6B46C1),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._firebaseResults.map((movie) => _buildMovieCard(movie)),
              const SizedBox(height: 24),
            ],

            if (_searchResults.isNotEmpty) ...[
              const Text(
                'Other available movies',
                style: TextStyle(
                  color: Color(0xFF6B46C1),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._searchResults.map((movie) => _buildApiMovieCard(movie)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to Firebase movie detail
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 100,
                color: Colors.grey[800],
                child: const Icon(Icons.movie, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['title'] ?? 'Sans titre',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie['genre'] ?? '',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${movie['rating'] ?? 0.0}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiMovieCard(ApiMovie movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApiMovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.imageUrl.isNotEmpty
                  ? Image.network(
                      movie.imageUrl,
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 100,
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 100,
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.primaryGenre} • ${movie.releaseYear}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
