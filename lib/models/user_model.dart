import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String displayName;
  final String dateOfBirth;
  final String photoURL;
  final String bio;
  final String role; // 'user' ou 'admin'
  final bool isActive;
  final String authProvider; // 'email', 'google', etc.
  final DateTime? createdAt;
  final DateTime? lastSignIn;
  final List<String> favoriteMovies;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.dateOfBirth = '',
    this.photoURL = '',
    this.bio = '',
    this.role = 'user',
    this.isActive = true,
    this.authProvider = 'email',
    this.createdAt,
    this.lastSignIn,
    this.favoriteMovies = const [],
  });

  // Convertir depuis Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      displayName: data['displayName'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      photoURL: data['photoURL'] ?? '',
      bio: data['bio'] ?? '',
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
      authProvider: data['authProvider'] ?? 'email',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastSignIn: data['lastSignIn'] != null
          ? (data['lastSignIn'] as Timestamp).toDate()
          : null,
      favoriteMovies: data['favoriteMovies'] != null
          ? List<String>.from(data['favoriteMovies'])
          : [],
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'dateOfBirth': dateOfBirth,
      'photoURL': photoURL,
      'bio': bio,
      'role': role,
      'isActive': isActive,
      'authProvider': authProvider,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastSignIn': lastSignIn != null
          ? Timestamp.fromDate(lastSignIn!)
          : FieldValue.serverTimestamp(),
      'favoriteMovies': favoriteMovies,
    };
  }

  // Copier avec modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? displayName,
    String? dateOfBirth,
    String? photoURL,
    String? bio,
    String? role,
    bool? isActive,
    String? authProvider,
    DateTime? createdAt,
    DateTime? lastSignIn,
    List<String>? favoriteMovies,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      favoriteMovies: favoriteMovies ?? this.favoriteMovies,
    );
  }

  // Vérifier si admin
  bool get isAdmin => role == 'admin';

  // Nom complet
  String get fullName => '$firstName $lastName';
}
