import 'package:cloud_firestore/cloud_firestore.dart';
import 'moviedb_api_service.dart';
import '../models/api_movie_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MovieDbApiService _apiService = MovieDbApiService();

  // Collection des films Firebase
  CollectionReference get _moviesCollection => _firestore.collection('movies');

  // Collection des recherches récentes
  CollectionReference get _recentSearchesCollection =>
      _firestore.collection('recent_searches');

  // Rechercher dans Firebase ET l'API MovieDB
  Future<Map<String, dynamic>> searchMovies(
    String query, {
    String userId = '',
  }) async {
    try {
      // Sauvegarder la recherche si userId fourni
      if (userId.isNotEmpty && query.trim().isNotEmpty) {
        await _saveRecentSearch(userId, query);
      }

      // Rechercher dans Firebase
      final firebaseResults = await _searchInFirebase(query);

      // Rechercher dans l'API MovieDB
      final apiResults = await _searchInAPI(query);

      return {'firebase': firebaseResults, 'api': apiResults, 'query': query};
    } catch (e) {
      print('❌ Erreur recherche: $e');
      return {'firebase': [], 'api': [], 'query': query};
    }
  }

  // Rechercher dans Firebase uniquement
  Future<List<Map<String, dynamic>>> _searchInFirebase(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final queryLower = query.toLowerCase();

      // Recherche par titre (case-insensitive approximation)
      final snapshot = await _moviesCollection.get();

      final results = snapshot.docs
          .map(
            (doc) => {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
              'source': 'firebase',
            },
          )
          .where(
            (movie) =>
                (movie['title'] as String).toLowerCase().contains(queryLower) ||
                (movie['genre'] as String).toLowerCase().contains(queryLower) ||
                (movie['director'] as String?)?.toLowerCase().contains(
                      queryLower,
                    ) ==
                    true,
          )
          .toList();

      print('✅ Trouvé ${results.length} films dans Firebase');
      return results;
    } catch (e) {
      print('❌ Erreur recherche Firebase: $e');
      return [];
    }
  }

  // Rechercher dans l'API MovieDB
  Future<List<ApiMovie>> _searchInAPI(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      print('🔍 Recherche API pour: "$query"');
      final results = await _apiService.searchMovies(query);
      print('📦 Résultats bruts API: ${results.length} films');

      final movies = results
          .map((json) {
            try {
              return ApiMovie.fromJson(_apiService.convertToMovieModel(json));
            } catch (e) {
              print('❌ Erreur conversion film: $e');
              return null;
            }
          })
          .where((movie) => movie != null)
          .cast<ApiMovie>()
          .toList();

      print('✅ Trouvé ${movies.length} films dans API');
      return movies;
    } catch (e) {
      print('❌ Erreur recherche API: $e');
      return [];
    }
  }

  // Sauvegarder une recherche récente
  Future<void> _saveRecentSearch(String userId, String query) async {
    try {
      await _recentSearchesCollection.add({
        'userId': userId,
        'query': query.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Garder seulement les 20 dernières recherches
      await _cleanOldSearches(userId);
    } catch (e) {
      print('❌ Erreur sauvegarde recherche: $e');
    }
  }

  // Nettoyer les anciennes recherches
  Future<void> _cleanOldSearches(String userId) async {
    try {
      final snapshot = await _recentSearchesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.length > 20) {
        final docsToDelete = snapshot.docs.skip(20);
        final batch = _firestore.batch();

        for (var doc in docsToDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      print('❌ Erreur nettoyage recherches: $e');
    }
  }

  // Récupérer les recherches récentes
  Future<List<String>> getRecentSearches(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _recentSearchesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final searches = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['query'] as String)
          .toSet() // Éliminer les doublons
          .toList();

      return searches;
    } catch (e) {
      print('❌ Erreur récupération recherches: $e');
      return [];
    }
  }

  // Supprimer toutes les recherches récentes
  Future<void> clearRecentSearches(String userId) async {
    try {
      final snapshot = await _recentSearchesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Recherches récentes supprimées');
    } catch (e) {
      print('❌ Erreur suppression recherches: $e');
      rethrow;
    }
  }

  // Rechercher par genre
  Future<Map<String, dynamic>> searchByGenre(String genre) async {
    try {
      // Firebase
      final firebaseSnapshot = await _moviesCollection
          .where('genre', isEqualTo: genre)
          .get();

      final firebaseResults = firebaseSnapshot.docs
          .map(
            (doc) => {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
              'source': 'firebase',
            },
          )
          .toList();

      // API
      final apiResults = await _apiService.getMoviesByGenre(genre);
      final apiMovies = apiResults
          .map(
            (json) => ApiMovie.fromJson(_apiService.convertToMovieModel(json)),
          )
          .toList();

      return {'firebase': firebaseResults, 'api': apiMovies, 'genre': genre};
    } catch (e) {
      print('❌ Erreur recherche par genre: $e');
      return {'firebase': [], 'api': [], 'genre': genre};
    }
  }

  // Récupérer les films tendances (combiné Firebase + API)
  Future<Map<String, dynamic>> getTrendingMovies() async {
    try {
      // Films populaires de Firebase (par viewCount)
      final firebaseSnapshot = await _moviesCollection
          .orderBy('viewCount', descending: true)
          .limit(10)
          .get();

      final firebaseResults = firebaseSnapshot.docs
          .map(
            (doc) => {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
              'source': 'firebase',
            },
          )
          .toList();

      // Films populaires de l'API
      final apiResults = await _apiService.getPopularMovies();
      final apiMovies = apiResults
          .map(
            (json) => ApiMovie.fromJson(_apiService.convertToMovieModel(json)),
          )
          .take(10)
          .toList();

      return {'firebase': firebaseResults, 'api': apiMovies};
    } catch (e) {
      print('❌ Erreur films tendances: $e');
      return {'firebase': [], 'api': []};
    }
  }
}
