import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Service pour gérer les uploads d'images vers Cloudinary
///
/// Configuration Cloudinary :
/// 1. Créez un compte gratuit sur https://cloudinary.com/
/// 2. Dans votre Dashboard, notez :
///    - Cloud Name (ex: "dxxxxxx")
///    - Upload Preset (créez-en un "unsigned" dans Settings > Upload)
/// 3. Remplacez les valeurs ci-dessous
class CloudinaryService {
  // ⚠️ CONFIGURATION REQUISE - Remplacez ces valeurs par les vôtres
  static const String cloudName = 'da92y9s6t'; // Ex: 'dxxxxxxx'
  static const String uploadPreset = 'cinema_preset'; // Ex: 'cinema_preset'

  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  /// Upload une image de film vers Cloudinary
  ///
  /// Avantages Cloudinary :
  /// - Upload ultra-rapide (CDN global)
  /// - Compression automatique
  /// - Transformation d'images à la volée
  /// - URLs optimisées avec cache
  Future<String?> uploadMovieImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: fileName,
          folder: 'cinema_fst_hub/movies', // Dossier dans Cloudinary
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final url = response.secureUrl;

      // Retourne l'URL avec transformation optimisée
      return _getOptimizedUrl(url, width: 600, quality: 'auto');
    } catch (e) {
      // Erreur silencieuse - retourne null
      return null;
    }
  }

  /// Upload une image de profil vers Cloudinary
  Future<String?> uploadProfileImage({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    try {
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: fileName,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final url = response.secureUrl;

      // Retourne l'URL avec transformation optimisée (sans gravity: face qui nécessite un plan payant)
      return _getOptimizedUrl(url, width: 300, quality: 'auto');
    } catch (e) {
      // Erreur silencieuse - retourne null
      return null;
    }
  }

  /// Supprime une image de Cloudinary
  /// Note: La suppression nécessite l'API signée, non disponible avec upload preset unsigned
  /// Pour le moment, cette fonction est désactivée
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // La suppression nécessite une API Key et Secret (mode signé)
      // Avec le mode unsigned (upload preset), on ne peut pas supprimer
      print(
        '⚠️ Suppression Cloudinary nécessite l\'API signée (pas implémenté)',
      );
      print(
        '💡 Alternative: les images restent dans Cloudinary (plan gratuit 25GB)',
      );
      return false;
    } catch (e) {
      print('❌ Erreur suppression Cloudinary: $e');
      return false;
    }
  }

  /// Génère une URL optimisée avec transformations Cloudinary
  ///
  /// Exemples de transformations :
  /// - width: largeur max
  /// - quality: 'auto' (Cloudinary optimise automatiquement)
  /// - format: 'auto' (WebP pour navigateurs compatibles, JPEG sinon)
  /// - gravity: 'face' (centre sur les visages pour les profils)
  String _getOptimizedUrl(
    String originalUrl, {
    int? width,
    String quality = 'auto',
    String format = 'auto',
    String? gravity,
  }) {
    // Cloudinary URL format:
    // https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{public_id}.{format}

    final transformations = <String>[];

    if (width != null) transformations.add('w_$width');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    if (gravity != null) transformations.add('g_$gravity');

    // Insérer les transformations dans l'URL
    final transformationString = transformations.join(',');

    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/$transformationString/',
    );
  }

  /// Obtient une URL d'image avec transformation à la volée
  ///
  /// Utile pour afficher différentes tailles de la même image
  /// sans re-upload
  String getTransformedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
  }) {
    final transformations = <String>[];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (crop != null) transformations.add('c_$crop');
    if (gravity != null) transformations.add('g_$gravity');

    final transformationString = transformations.join(',');

    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/$transformationString/',
    );
  }
}
