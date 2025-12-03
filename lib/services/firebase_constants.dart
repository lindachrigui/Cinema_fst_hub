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
  static const String userFavoriteMovies = 'favoriteMovies';

  // Champs film
  static const String movieTitle = 'title';
  static const String movieGenre = 'genre';
  static const String movieDescription = 'description';
  static const String movieDuration = 'duration';
  static const String movieLanguage = 'language';
  static const String movieImageUrl = 'imageUrl';
  static const String movieRating = 'rating';
  static const String movieViewCount = 'viewCount';
  static const String movieCreatedAt = 'createdAt';
  static const String movieCast = 'cast';
  static const String movieDirector = 'director';
  static const String movieReleaseYear = 'releaseYear';
  static const String movieAvailableLanguages = 'availableLanguages';

  // Champs critique
  static const String reviewUserId = 'userId';
  static const String reviewUserName = 'userName';
  static const String reviewMovieId = 'movieId';
  static const String reviewRating = 'rating';
  static const String reviewComment = 'comment';
  static const String reviewCreatedAt = 'createdAt';

  // Dossiers Storage
  static const String storageMoviesFolder = 'movies';
  static const String storageUsersFolder = 'users';
  static const String storageProfilesFolder = 'profiles';

  // Rôles utilisateur
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  // Messages d'erreur
  static const String networkError = 'Erreur de connexion internet';
  static const String unknownError = 'Une erreur inattendue s\'est produite';
  static const String signInSuccess = 'Connexion réussie!';
  static const String signUpSuccess = 'Compte créé avec succès!';
  static const String signOutSuccess = 'Logout successful!';

  // Success messages
  static const String movieAddedSuccess = 'Movie added successfully!';
  static const String movieUpdatedSuccess = 'Movie updated successfully!';
  static const String movieDeletedSuccess = 'Movie deleted successfully!';
  static const String reviewAddedSuccess = 'Review added successfully!';
  static const String favoriteAddedSuccess = 'Added to favourites!';
  static const String favoriteRemovedSuccess = 'Removed from favourites!';
}
