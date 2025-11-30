import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection des favoris
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');

  // Ajouter un film aux favoris
  Future<void> addToFavorites(
    String movieId,
    Map<String, dynamic> movieData,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await _favoritesCollection.doc('$userId\_$movieId').set({
        'userId': userId,
        'movieId': movieId,
        'movieTitle': movieData['title'],
        'movieImage': movieData['imageUrl'],
        'movieGenre': movieData['genre'],
        'movieRating': movieData['rating'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Film ajouté aux favoris: ${movieData['title']}');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout aux favoris: $e');
      rethrow;
    }
  }

  // Retirer un film des favoris
  Future<void> removeFromFavorites(String movieId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await _favoritesCollection.doc('$userId\_$movieId').delete();
      print('✅ Film retiré des favoris');
    } catch (e) {
      print('❌ Erreur lors du retrait des favoris: $e');
      rethrow;
    }
  }

  // Vérifier si un film est dans les favoris
  Future<bool> isFavorite(String movieId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _favoritesCollection.doc('$userId\_$movieId').get();
      return doc.exists;
    } catch (e) {
      print('❌ Erreur lors de la vérification favori: $e');
      return false;
    }
  }

  // Récupérer tous les favoris de l'utilisateur
  Stream<List<Map<String, dynamic>>> getUserFavorites() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return Stream.value([]);

      // Temporaire: sans orderBy pour éviter l'erreur d'index
      // Une fois l'index créé dans Firebase Console, décommenter la ligne avec orderBy
      return _favoritesCollection
          .where('userId', isEqualTo: userId)
          .orderBy(
            'addedAt',
            descending: true,
          ) // Décommenter après création de l'index
          .snapshots()
          .map((snapshot) {
            final docs = snapshot.docs
                .map(
                  (doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  },
                )
                .toList();

            return docs;
          });
    } catch (e) {
      print('❌ Erreur lors de la récupération des favoris: $e');
      return Stream.value([]);
    }
  }

  // Récupérer le nombre de favoris
  Future<int> getFavoritesCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erreur lors du comptage des favoris: $e');
      return 0;
    }
  }

  // Supprimer tous les favoris de l'utilisateur
  Future<void> clearAllFavorites() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Tous les favoris supprimés');
    } catch (e) {
      print('❌ Erreur lors de la suppression des favoris: $e');
      rethrow;
    }
  }

  // Toggle favori (ajouter/retirer)
  Future<bool> toggleFavorite(
    String movieId,
    Map<String, dynamic> movieData,
  ) async {
    try {
      final isFav = await isFavorite(movieId);

      if (isFav) {
        await removeFromFavorites(movieId);
        return false;
      } else {
        await addToFavorites(movieId, movieData);
        return true;
      }
    } catch (e) {
      print('❌ Erreur toggle favori: $e');
      rethrow;
    }
  }
}
