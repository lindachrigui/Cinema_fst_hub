import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');

  // Calculer le pourcentage de match entre deux utilisateurs
  Future<int> calculateMatchPercentage(String otherUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 0;

      // Récupérer les favoris de l'utilisateur actuel
      final myFavorites = await _favoritesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Récupérer les favoris de l'autre utilisateur
      final otherFavorites = await _favoritesCollection
          .where('userId', isEqualTo: otherUserId)
          .get();

      if (myFavorites.docs.isEmpty && otherFavorites.docs.isEmpty) return 0;

      // Créer des sets de movieIds
      final myMovieIds = myFavorites.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['movieId'] as String)
          .toSet();

      final otherMovieIds = otherFavorites.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['movieId'] as String)
          .toSet();

      // Calculer les films en commun
      final commonMovies = myMovieIds.intersection(otherMovieIds).length;
      final totalUniqueMovies = myMovieIds.union(otherMovieIds).length;

      if (totalUniqueMovies == 0) return 0;

      // Calculer le pourcentage
      final percentage = ((commonMovies / totalUniqueMovies) * 100).round();
      return percentage;
    } catch (e) {
      print('❌ Erreur calcul match: $e');
      return 0;
    }
  }

  // Trouver des utilisateurs avec des goûts similaires
  Future<List<Map<String, dynamic>>> findMatchingUsers({int limit = 20}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Récupérer tous les utilisateurs (sauf l'utilisateur actuel)
      final usersSnapshot = await _usersCollection
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(limit)
          .get();

      final matchingUsers = <Map<String, dynamic>>[];

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final matchPercentage = await calculateMatchPercentage(userDoc.id);

        if (matchPercentage > 0) {
          matchingUsers.add({
            'id': userDoc.id,
            'name': userData['displayName'] ?? 'Utilisateur',
            'email': userData['email'] ?? '',
            'photoUrl': userData['photoURL'] ?? '',
            'matchPercentage': matchPercentage,
          });
        }
      }

      // Trier par pourcentage de match décroissant
      matchingUsers.sort(
        (a, b) => (b['matchPercentage'] as int).compareTo(
          a['matchPercentage'] as int,
        ),
      );

      return matchingUsers;
    } catch (e) {
      print('❌ Erreur recherche matching: $e');
      return [];
    }
  }

  // Récupérer les films en commun avec un utilisateur
  Future<List<Map<String, dynamic>>> getCommonMovies(String otherUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Récupérer mes favoris
      final myFavorites = await _favoritesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Récupérer les favoris de l'autre utilisateur
      final otherFavorites = await _favoritesCollection
          .where('userId', isEqualTo: otherUserId)
          .get();

      // Créer un map des films de l'autre utilisateur
      final otherMovieIds = otherFavorites.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['movieId'] as String)
          .toSet();

      // Filtrer mes favoris pour ne garder que les communs
      final commonMovies = myFavorites.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) => otherMovieIds.contains(data['movieId']))
          .toList();

      return commonMovies;
    } catch (e) {
      print('❌ Erreur films communs: $e');
      return [];
    }
  }

  // Stream des utilisateurs matchés
  Stream<List<Map<String, dynamic>>> streamMatchingUsers() async* {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        yield [];
        return;
      }

      // Écouter les changements sur les utilisateurs
      await for (var snapshot
          in _usersCollection
              .where(FieldPath.documentId, isNotEqualTo: currentUserId)
              .snapshots()) {
        final matchingUsers = <Map<String, dynamic>>[];

        for (var userDoc in snapshot.docs) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final matchPercentage = await calculateMatchPercentage(userDoc.id);

          if (matchPercentage > 0) {
            matchingUsers.add({
              'id': userDoc.id,
              'name': userData['displayName'] ?? 'Utilisateur',
              'email': userData['email'] ?? '',
              'photoUrl': userData['photoURL'] ?? '',
              'matchPercentage': matchPercentage,
            });
          }
        }

        matchingUsers.sort(
          (a, b) => (b['matchPercentage'] as int).compareTo(
            a['matchPercentage'] as int,
          ),
        );

        yield matchingUsers;
      }
    } catch (e) {
      print('❌ Erreur stream matching: $e');
      yield [];
    }
  }

  // Récupérer les détails d'un utilisateur
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;

      final userData = doc.data() as Map<String, dynamic>;
      final matchPercentage = await calculateMatchPercentage(userId);

      return {
        'id': doc.id,
        'name': userData['displayName'] ?? 'Utilisateur',
        'email': userData['email'] ?? '',
        'photoUrl': userData['photoURL'] ?? '',
        'bio': userData['bio'] ?? '',
        'matchPercentage': matchPercentage,
      };
    } catch (e) {
      print('❌ Erreur détails utilisateur: $e');
      return null;
    }
  }
}
