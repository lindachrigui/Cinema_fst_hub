class FirebaseConstants {
  // Collections Firestore
  static const String usersCollection = 'users';
  static const String moviesCollection = 'movies';
  static const String reviewsCollection = 'reviews';
  static const String favoritesCollection = 'favorites';

  // Champs utilisateur
  static const String userUid = 'uid';
  static const String userEmail = 'email';
  static const String userFirstName = 'firstName';
  static const String userLastName = 'lastName';
  static const String userDisplayName = 'displayName';
  static const String userDateOfBirth = 'dateOfBirth';
  static const String userPhotoUrl = 'photoURL';
  static const String userCreatedAt = 'createdAt';
  static const String userLastSignIn = 'lastSignIn';
  static const String userAuthProvider = 'authProvider';
  static const String userRole = 'role'; // 'admin' ou 'user'
  static const String userIsActive = 'isActive'; // true ou false

  // Messages d'erreur
  static const String networkError = 'Erreur de connexion internet';
  static const String unknownError = 'Une erreur inattendue s\'est produite';
  static const String signInSuccess = 'Connexion réussie!';
  static const String signUpSuccess = 'Compte créé avec succès!';
  static const String signOutSuccess = 'Déconnexion réussie!';
}
