import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieDbApiService {
  // Configuration RapidAPI
  static const String _baseUrl = 'https://moviesdatabase.p.rapidapi.com';
  static const String _rapidApiKey =
      'a14a7e4944mshe05bffb60029eacp1e00fcjsnf37cd198ea8d';
  static const String _rapidApiHost = 'moviesdatabase.p.rapidapi.com';

  // Mode demo pour tester sans API
  static const bool _useMockData =
      true; // Changez à false après abonnement RapidAPI

  // Headers pour RapidAPI
  Map<String, String> get _headers => {
    'X-RapidAPI-Key': _rapidApiKey,
    'X-RapidAPI-Host': _rapidApiHost,
  };

  // Récupérer les films populaires
  Future<List<Map<String, dynamic>>> getPopularMovies({int page = 1}) async {
    if (_useMockData) {
      print('🎭 Mode DEMO - Données mockées');
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simuler délai réseau
      return _getMockMovies();
    }

    try {
      print('🎬 Appel API getPopularMovies - page: $page');
      final response = await http.get(
        Uri.parse('$_baseUrl/titles?page=$page&limit=20'),
        headers: _headers,
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Données reçues: ${data.toString().substring(0, 200)}...');

        final results = data['results'] ?? [];
        print('✅ Nombre de films: ${results.length}');

        return List<Map<String, dynamic>>.from(results);
      } else {
        print('❌ Erreur API: ${response.statusCode} - ${response.body}');
        print(
          '⚠️  Conseil: Vérifiez votre abonnement sur https://rapidapi.com/SAdrian/api/moviesdatabase',
        );
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Erreur lors de la récupération des films populaires: $e');
      return [];
    }
  }

  // Récupérer les détails d'un film par ID
  Future<Map<String, dynamic>?> getMovieDetails(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/titles/$movieId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] as Map<String, dynamic>?;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des détails du film: $e');
      return null;
    }
  }

  // Rechercher des films
  Future<List<Map<String, dynamic>>> searchMovies(
    String query, {
    int page = 1,
  }) async {
    if (_useMockData) {
      print('🔍 Mode DEMO - Recherche mockée pour: "$query"');
      await Future.delayed(const Duration(milliseconds: 500));
      return _searchMockMovies(query);
    }

    try {
      print('🔍 Recherche API pour: "$query"');
      final response = await http.get(
        Uri.parse('$_baseUrl/titles/search/title/$query?page=$page&limit=20'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results'] ?? []);
        print('✅ Trouvé ${results.length} résultats pour "$query"');
        return results;
      } else {
        print('❌ Erreur API recherche: ${response.statusCode}');
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors de la recherche de films: $e');
      print(
        '💡 Conseil: Utilisez le mode mock (_useMockData = true) pour tester',
      );
      return [];
    }
  }

  // Récupérer les films par genre
  Future<List<Map<String, dynamic>>> getMoviesByGenre(
    String genre, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/titles?genre=$genre&page=$page&limit=20'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des films par genre: $e');
      return [];
    }
  }

  // Récupérer les genres disponibles
  Future<List<String>> getGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/titles/utils/genres'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['results'] ?? []);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des genres: $e');
      return [];
    }
  }

  // Récupérer les images d'un film
  Future<Map<String, dynamic>?> getMovieImages(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/titles/$movieId/images'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] as Map<String, dynamic>?;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des images: $e');
      return null;
    }
  }

  // Récupérer les films récents/nouveautés
  Future<List<Map<String, dynamic>>> getNewReleases({int page = 1}) async {
    if (_useMockData) {
      print('🎭 Mode DEMO - Nouveautés mockées');
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockNewReleases();
    }

    try {
      print('🎬 Appel API getNewReleases - page: $page');
      final currentYear = DateTime.now().year;
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/titles?year=$currentYear&page=$page&limit=20&sort=year.decr',
        ),
        headers: _headers,
      );

      print('📡 Status Code (New Releases): ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] ?? [];
        print('✅ Nombre de nouveautés: ${results.length}');

        return List<Map<String, dynamic>>.from(results);
      } else {
        print('❌ Erreur API New Releases: ${response.statusCode}');
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Erreur lors de la récupération des nouveautés: $e');
      return [];
    }
  }

  // Convertir un film de l'API en format compatible avec notre modèle
  Map<String, dynamic> convertToMovieModel(Map<String, dynamic> apiMovie) {
    print(
      '🔄 Conversion du film: ${apiMovie['titleText']?['text'] ?? 'Inconnu'}',
    );
    return {
      'id': apiMovie['id'] ?? '',
      'title': apiMovie['titleText']?['text'] ?? 'Sans titre',
      'genre': _extractGenres(apiMovie['genres']),
      'description': apiMovie['plot']?['plotText']?['plainText'] ?? '',
      'duration': _extractDuration(apiMovie['runtime']),
      'language':
          apiMovie['originalTitleText']?['language']?['name'] ?? 'English',
      'imageUrl': _extractImageUrl(apiMovie['primaryImage']),
      'rating': _extractRating(apiMovie['ratingsSummary']),
      'viewCount': 0,
      'cast': _extractCast(apiMovie['cast']),
      'director': _extractDirector(apiMovie['directors']),
      'releaseYear': apiMovie['releaseYear']?['year'] ?? 0,
      'availableLanguages': _extractLanguages(apiMovie['spokenLanguages']),
    };
  }

  // Helper: Extraire les genres
  String _extractGenres(dynamic genres) {
    if (genres == null) return 'Unknown';
    if (genres is List && genres.isNotEmpty) {
      final genreList = genres.map((g) => g['text'] ?? g['id'] ?? '').toList();
      return genreList.first;
    }
    return 'Unknown';
  }

  // Helper: Extraire la durée
  int _extractDuration(dynamic runtime) {
    if (runtime == null) return 0;
    if (runtime is Map && runtime['seconds'] != null) {
      return runtime['seconds'] as int;
    }
    return 0;
  }

  // Helper: Extraire l'URL de l'image
  String _extractImageUrl(dynamic primaryImage) {
    if (primaryImage == null) return '';
    if (primaryImage is Map && primaryImage['url'] != null) {
      return primaryImage['url'] as String;
    }
    return '';
  }

  // Helper: Extraire la note
  double _extractRating(dynamic ratingsSummary) {
    if (ratingsSummary == null) return 0.0;
    if (ratingsSummary is Map && ratingsSummary['aggregateRating'] != null) {
      final rating = ratingsSummary['aggregateRating'];
      return (rating is num) ? rating.toDouble() : 0.0;
    }
    return 0.0;
  }

  // Helper: Extraire le casting
  List<String> _extractCast(dynamic cast) {
    if (cast == null) return [];
    if (cast is List) {
      return cast
          .take(5)
          .map((c) => c['actor']?['name'] ?? '')
          .where((name) => name.isNotEmpty)
          .toList()
          .cast<String>();
    }
    return [];
  }

  // Helper: Extraire le réalisateur
  String _extractDirector(dynamic directors) {
    if (directors == null) return '';
    if (directors is List && directors.isNotEmpty) {
      return directors.first['name'] ?? '';
    }
    return '';
  }

  // Helper: Extraire les langues disponibles
  List<String> _extractLanguages(dynamic spokenLanguages) {
    if (spokenLanguages == null) return ['English'];
    if (spokenLanguages is List) {
      return spokenLanguages
          .map((lang) => lang['name'] ?? '')
          .where((name) => name.isNotEmpty)
          .cast<String>()
          .toList();
    }
    return ['English'];
  }

  // ===== DONNÉES MOCKÉES POUR DEMO =====
  List<Map<String, dynamic>> _getMockMovies() {
    return [
      {
        'id': 'tt1517268',
        'titleText': {'text': 'Barbie'},
        'releaseYear': {'year': 2023},
        'genres': {
          'genres': [
            {'text': 'Comedy'},
            {'text': 'Adventure'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'Barbie and Ken are having the time of their lives in the colorful and seemingly perfect world of Barbie Land. However, when they get a chance to go to the real world, they soon discover the joys and perils of living among humans.',
          },
        },
        'runtime': {'seconds': 6840},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BNjU3N2QxNzYtMjk1NC00MTc4LTk1NTQtMmUxNTljM2I0NDA5XkEyXkFqcGdeQXVyODE5NzE3OTE@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 7.0},
      },
      {
        'id': 'tt15398776',
        'titleText': {'text': 'Oppenheimer'},
        'releaseYear': {'year': 2023},
        'genres': {
          'genres': [
            {'text': 'Biography'},
            {'text': 'Drama'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.',
          },
        },
        'runtime': {'seconds': 10800},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BMDBmYTZjNjUtN2M1MS00MTQ2LTk2ODgtNzc2M2QyZGE5NTVjXkEyXkFqcGdeQXVyNzAwMjU2MTY@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 8.3},
      },
      {
        'id': 'tt9362722',
        'titleText': {'text': 'Spider-Man: Across the Spider-Verse'},
        'releaseYear': {'year': 2023},
        'genres': {
          'genres': [
            {'text': 'Animation'},
            {'text': 'Action'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'Miles Morales catapults across the Multiverse, where he encounters a team of Spider-People charged with protecting its very existence.',
          },
        },
        'runtime': {'seconds': 8400},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BMzI0NmVkMjEtYmY4MS00ZDMxLTlkZmEtMzU4MDQxYTMzMjU2XkEyXkFqcGdeQXVyMzQ0MzA0NTM@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 8.7},
      },
      {
        'id': 'tt6710474',
        'titleText': {'text': 'Everything Everywhere All at Once'},
        'releaseYear': {'year': 2022},
        'genres': {
          'genres': [
            {'text': 'Action'},
            {'text': 'Adventure'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'An aging Chinese immigrant is swept up in an insane adventure, in which she alone can save the world by exploring other universes connecting with the lives she could have led.',
          },
        },
        'runtime': {'seconds': 8340},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BYTdiOTIyZTQtNmQ1OS00NjZlLWIyMTgtYzk5Y2M3ZDVmMDk1XkEyXkFqcGdeQXVyMTAzMDg4NzU0._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 7.8},
      },
      {
        'id': 'tt1745960',
        'titleText': {'text': 'Top Gun: Maverick'},
        'releaseYear': {'year': 2022},
        'genres': {
          'genres': [
            {'text': 'Action'},
            {'text': 'Drama'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'After thirty years, Maverick is still pushing the envelope as a top naval aviator, but must confront ghosts of his past when he leads TOP GUN\'s elite graduates on a mission that demands the ultimate sacrifice from those chosen to fly it.',
          },
        },
        'runtime': {'seconds': 7860},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BZWYzOGEwNTgtNWU3NS00ZTQ0LWJkODUtMmVhMjIwMjA1ZmQwXkEyXkFqcGdeQXVyMjkwOTAyMDU@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 8.3},
      },
      {
        'id': 'tt10366206',
        'titleText': {'text': 'John Wick: Chapter 4'},
        'releaseYear': {'year': 2023},
        'genres': {
          'genres': [
            {'text': 'Action'},
            {'text': 'Thriller'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'John Wick uncovers a path to defeating The High Table. But before he can earn his freedom, Wick must face off against a new enemy with powerful alliances across the globe.',
          },
        },
        'runtime': {'seconds': 10140},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BMDExZGMyOTMtMDIyYi00OWNiLWI3YzItYWIwMTZlNWUzNWEyXkEyXkFqcGdeQXVyMjM4NTM5NDgx._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 7.7},
      },
      {
        'id': 'tt1160419',
        'titleText': {'text': 'Dune'},
        'releaseYear': {'year': 2021},
        'genres': {
          'genres': [
            {'text': 'Adventure'},
            {'text': 'Sci-Fi'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'A noble family becomes embroiled in a war for control over the galaxy\'s most valuable asset while its heir becomes troubled by visions of a dark future.',
          },
        },
        'runtime': {'seconds': 9360},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BN2FjNmEyNWMtYzM0ZS00NjIyLTg5YzYtYThlMGVjNzE1OGViXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 8.0},
      },
      {
        'id': 'tt8721424',
        'titleText': {'text': 'Ambulance'},
        'releaseYear': {'year': 2022},
        'genres': {
          'genres': [
            {'text': 'Action'},
            {'text': 'Crime'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'Two robbers steal an ambulance after their heist goes awry.',
          },
        },
        'runtime': {'seconds': 8160},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BYjUzNGQwMWUtMzMwZC00YWQ3LWJkZjQtMmM0YmE0NWFiNjA4XkEyXkFqcGdeQXVyMTEyNzgwMDUw._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 6.1},
      },
    ];
  }

  List<Map<String, dynamic>> _getMockNewReleases() {
    return [
      {
        'id': 'tt14208870',
        'titleText': {'text': 'The Marvels'},
        'releaseYear': {'year': 2023},
        'genres': {
          'genres': [
            {'text': 'Action'},
            {'text': 'Fantasy'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'Carol Danvers gets her powers entangled with those of Kamala Khan and Monica Rambeau, forcing them to work together to save the universe.',
          },
        },
        'runtime': {'seconds': 6300},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BM2U2YWU5NWMtOGI2Ni00MGE5LWFkOGItOGVlYTMxNGE2OTI3XkEyXkFqcGdeQXVyMDM2NDM2MQ@@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 5.5},
      },
      {
        'id': 'tt9603212',
        'titleText': {'text': 'Wonka'},
        'releaseYear': {'year': 2023},
        'genres': {
          'genres': [
            {'text': 'Adventure'},
            {'text': 'Comedy'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'The story will focus specifically on a young Willy Wonka and how he met the Oompa-Loompas on one of his earliest adventures.',
          },
        },
        'runtime': {'seconds': 6960},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BOTUyMWRhNzAtNmQ3Yi00NzJmLTk3YTAtNGRkNzE2ZGJmNmNlXkEyXkFqcGdeQXVyMTUzMTg2ODkz._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 7.1},
      },
      {
        'id': 'tt11245972',
        'titleText': {'text': 'Aquaman and the Lost Kingdom'},
        'releaseYear': {'year': 2023},
        'genres': {
          'genres': [
            {'text': 'Action'},
            {'text': 'Adventure'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'Black Manta seeks revenge on Aquaman for his father\'s death. Wielding the Black Trident\'s power, he becomes a formidable foe. To defend Atlantis, Aquaman forges an alliance with his imprisoned brother.',
          },
        },
        'runtime': {'seconds': 7440},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BYTRiODMxNGMtMjA1MS00ODZkLTg2ZDYtNGE2OGU3OWQyNjY5XkEyXkFqcGdeQXVyMTUzMTg2ODkz._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 5.7},
      },
      {
        'id': 'tt6467266',
        'titleText': {'text': 'Avatar: The Way of Water'},
        'releaseYear': {'year': 2022},
        'genres': {
          'genres': [
            {'text': 'Action'},
            {'text': 'Adventure'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'Jake Sully lives with his newfound family formed on the extrasolar moon Pandora. Once a familiar threat returns to finish what was previously started, Jake must work with Neytiri and the army of the Na\'vi race to protect their home.',
          },
        },
        'runtime': {'seconds': 11520},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BYjhiNjBlODctY2ZiOC00YjVlLWFlNzAtNTVhNzM1YjI1NzMxXkEyXkFqcGdeQXVyMjQxNTE1MDA@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 7.6},
      },
      {
        'id': 'tt11214590',
        'titleText': {'text': 'House of Gucci'},
        'releaseYear': {'year': 2021},
        'genres': {
          'genres': [
            {'text': 'Biography'},
            {'text': 'Crime'},
          ],
        },
        'plot': {
          'plotText': {
            'plainText':
                'When Patrizia Reggiani, an outsider from humble beginnings, marries into the Gucci family, her unbridled ambition begins to unravel their legacy and triggers a reckless spiral of betrayal, decadence, revenge, and ultimately...murder.',
          },
        },
        'runtime': {'seconds': 9480},
        'primaryImage': {
          'url':
              'https://m.media-amazon.com/images/M/MV5BYzdlMTMyZmEtNmNhNS00YTRhLWE5NDYtNzQzNzM5ZGYyN2UwXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_.jpg',
        },
        'ratingsSummary': {'aggregateRating': 6.6},
      },
    ];
  }

  // Recherche dans les films mockés
  List<Map<String, dynamic>> _searchMockMovies(String query) {
    final List<Map<String, dynamic>> allMovies = [
      ..._getMockMovies(),
      ..._getMockNewReleases(),
    ];

    if (query.trim().isEmpty) {
      return allMovies;
    }

    final queryLower = query.toLowerCase();

    final List<Map<String, dynamic>> results = allMovies
        .where((movie) {
          final title = (movie['titleText']?['text'] ?? '')
              .toString()
              .toLowerCase();
          final genres = movie['genres']?['genres'] as List?;
          final genreText =
              genres?.map((g) => g['text']).join(' ').toLowerCase() ?? '';
          final plot = (movie['plot']?['plotText']?['plainText'] ?? '')
              .toString()
              .toLowerCase();

          return title.contains(queryLower) ||
              genreText.contains(queryLower) ||
              plot.contains(queryLower);
        })
        .toList()
        .cast<Map<String, dynamic>>();

    print(
      '🔍 Recherche mock: "${query}" - ${results.length} résultats trouvés',
    );
    return results;
  }
}
