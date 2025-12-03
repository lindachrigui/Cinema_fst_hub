import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Configuration pour le web - Client ID configuré
    clientId:
        '211369555556-dmsijqdv80q37p99hrlavmtcm8go51hb.apps.googleusercontent.com',
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream pour écouter les changements d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inscription avec email et mot de passe + données utilisateur
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? photoURL,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Créer un document utilisateur dans Firestore avec toutes les données
      await _createUserDocument(
        result.user,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        photoURL: photoURL,
      );

      return result;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Connexion avec first name et mot de passe
  Future<UserCredential?> signInWithFirstNameAndPassword(
    String firstName,
    String password,
  ) async {
    try {
      // Rechercher l'utilisateur par firstName dans Firestore
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('firstName', isEqualTo: firstName)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('No user found with this first name');
      }

      // Vérifier si le compte est actif (sauf pour les admins)
      final userData = userQuery.docs.first.data() as Map<String, dynamic>;
      final role = userData['role'] ?? 'user';

      if (role != 'admin') {
        final isActive = userData['isActive'] ?? true;
        if (!isActive) {
          throw Exception(
            'Your account has been deactivated. Please contact the administrator.',
          );
        }
      }

      // Récupérer l'email de l'utilisateur
      String email = userQuery.docs.first.get('email');

      // Se connecter avec email et password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour la dernière connexion
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastSignIn': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      print('Erreur de connexion: $e');
      rethrow;
    }
  }

  // Connexion avec email et mot de passe (garde pour compatibilité)
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vérifier si le compte est actif (sauf pour les admins)
      final userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'user';

        if (role != 'admin') {
          final isActive = userData['isActive'] ?? true;
          if (!isActive) {
            // Disconnect immediately
            await _auth.signOut();
            throw Exception(
              'Your account has been deactivated. Please contact the administrator.',
            );
          }
        }

        // Mettre à jour la dernière connexion
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }

      return result;
    } catch (e) {
      print('Sign-in error: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      // Déconnexion Firebase Auth
      await _auth.signOut();

      // Déconnexion Google seulement si l'utilisateur était connecté via Google
      try {
        final googleUser = _googleSignIn.currentUser;
        if (googleUser != null) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        // Ignorer les erreurs de déconnexion Google si non configuré
        print('Google sign out skipped: $e');
      }
    } catch (e) {
      print('Sign-out error: $e');
      rethrow;
    }
  }

  // Vérifier si Google Sign-In est disponible
  bool get isGoogleSignInAvailable {
    // Client ID configuré directement
    return true;
  }

  // Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!isGoogleSignInAvailable) {
        throw Exception(
          'Google Sign-In is not configured. Please configure GOOGLE_CLIENT_ID.',
        );
      }

      // Déclencher le processus d'authentification
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      // Obtenir les détails d'authentification de la demande
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Créer un nouvel identifiant
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter avec l'identifiant
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      // Vérifier si le compte est actif (sauf pour les admins)
      final userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'user';

        if (role != 'admin') {
          final isActive = userData['isActive'] ?? true;
          if (!isActive) {
            // Disconnect immediately
            await _auth.signOut();
            await _googleSignIn.signOut();
            throw Exception(
              'Your account has been deactivated. Please contact the administrator.',
            );
          }
        }
      }

      // Créer ou mettre à jour le document utilisateur
      await _createUserDocument(result.user);

      return result;
    } catch (e) {
      print('Erreur de connexion Google: $e');
      rethrow;
    }
  }

  // Inscription avec Google (même processus que la connexion)
  Future<UserCredential?> signUpWithGoogle() async {
    try {
      if (!isGoogleSignInAvailable) {
        throw Exception(
          'Google Sign-In is not configured. Please configure GOOGLE_CLIENT_ID.',
        );
      }

      // Le processus d'inscription avec Google est identique à la connexion
      return await signInWithGoogle();
    } catch (e) {
      print('Erreur d\'inscription Google: $e');
      rethrow;
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Erreur de réinitialisation: $e');
      rethrow;
    }
  }

  // Obtenir le rôle de l'utilisateur connecté
  Future<String> getUserRole() async {
    try {
      final user = currentUser;
      if (user == null) {
        return 'user'; // Par défaut
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.get('role') ?? 'user';
      }
      return 'user';
    } catch (e) {
      print('Erreur lors de la récupération du rôle: $e');
      return 'user';
    }
  }

  // Créer un document utilisateur dans Firestore
  Future<void> _createUserDocument(
    User? user, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? photoURL,
  }) async {
    if (user != null) {
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

      // Vérifier si le document existe déjà
      DocumentSnapshot docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'firstName': firstName ?? user.displayName?.split(' ').first ?? '',
          'lastName': lastName ?? user.displayName?.split(' ').last ?? '',
          'displayName': user.displayName ?? '$firstName $lastName',
          'dateOfBirth': dateOfBirth ?? '',
          'photoURL': photoURL ?? user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'authProvider': _getAuthProvider(user),
          'role':
              'user', // Par défaut, tous les nouveaux utilisateurs sont 'user'
          'isActive': true, // Par défaut, les utilisateurs sont actifs
        });
      } else {
        // Mettre à jour la dernière connexion
        await userDoc.update({
          'lastSignIn': FieldValue.serverTimestamp(),
          'displayName':
              user.displayName ??
              docSnapshot.get('displayName') ??
              'Utilisateur',
          'photoURL': photoURL ?? user.photoURL ?? docSnapshot.get('photoURL'),
        });
      }
    }
  }

  // Déterminer le fournisseur d'authentification
  String _getAuthProvider(User user) {
    for (UserInfo info in user.providerData) {
      if (info.providerId == 'google.com') {
        return 'Google';
      } else if (info.providerId == 'password') {
        return 'Email/Password';
      }
    }
    return 'Inconnu';
  }

  // Obtenir les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Erreur de récupération des données utilisateur: $e');
      return null;
    }
  }

  // Mettre à jour les données utilisateur
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Erreur de mise à jour des données utilisateur: $e');
      rethrow;
    }
  }

  // Vérifier si l'email existe déjà
  Future<bool> isEmailAlreadyInUse(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Gestion des erreurs Firebase
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'user-disabled':
          return 'This account has been deactivated.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Connection error. Check your internet connection.';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return 'Une erreur inattendue s\'est produite.';
  }
}
