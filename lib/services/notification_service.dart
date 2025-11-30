import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // Types de notifications
  static const String TYPE_NEW_MOVIE = 'new_movie';
  static const String TYPE_MATCH_FOUND = 'match_found';
  static const String TYPE_NEW_REVIEW = 'new_review';
  static const String TYPE_FAVORITE_UPDATE = 'favorite_update';

  // Créer une notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationsCollection.add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification créée: $title');
    } catch (e) {
      print('❌ Erreur création notification: $e');
    }
  }

  // Récupérer les notifications de l'utilisateur
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return Stream.value([]);

      return _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  },
                )
                .toList();
          });
    } catch (e) {
      print('❌ Erreur récupération notifications: $e');
      return Stream.value([]);
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur marquage notification: $e');
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Toutes les notifications marquées comme lues');
    } catch (e) {
      print('❌ Erreur marquage notifications: $e');
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      print('✅ Notification supprimée');
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
    }
  }

  // Supprimer toutes les notifications
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Toutes les notifications supprimées');
    } catch (e) {
      print('❌ Erreur suppression notifications: $e');
    }
  }

  // Compter les notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Erreur comptage notifications: $e');
      return 0;
    }
  }

  // Stream du nombre de notifications non lues
  Stream<int> streamUnreadCount() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return Stream.value(0);

      return _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('❌ Erreur stream comptage: $e');
      return Stream.value(0);
    }
  }

  // Notifier l'ajout d'un nouveau film
  Future<void> notifyNewMovie(String movieTitle, String movieId) async {
    try {
      // Notifier tous les utilisateurs
      final usersSnapshot = await _firestore.collection('users').get();

      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _notificationsCollection.doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'type': TYPE_NEW_MOVIE,
          'title': 'Nouveau film disponible !',
          'message': '$movieTitle a été ajouté au catalogue',
          'data': {'movieId': movieId, 'movieTitle': movieTitle},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Notifications nouveau film envoyées');
    } catch (e) {
      print('❌ Erreur notification nouveau film: $e');
    }
  }

  // Notifier un match trouvé
  Future<void> notifyMatchFound(
    String userId,
    String matchedUserName,
    int percentage,
  ) async {
    try {
      await createNotification(
        userId: userId,
        type: TYPE_MATCH_FOUND,
        title: 'Nouveau match !',
        message: 'Vous avez un match de $percentage% avec $matchedUserName',
        data: {'matchedUserName': matchedUserName, 'percentage': percentage},
      );
    } catch (e) {
      print('❌ Erreur notification match: $e');
    }
  }
}
