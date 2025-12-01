import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../services/movie_service.dart';
import '../services/storage_service.dart';
import '../models/movie_model.dart';

class AdminAddFilmScreen extends StatefulWidget {
  const AdminAddFilmScreen({super.key});

  @override
  State<AdminAddFilmScreen> createState() => _AdminAddFilmScreenState();
}

class _AdminAddFilmScreenState extends State<AdminAddFilmScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();

  final MovieService _movieService = MovieService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  String _selectedGenre = 'romance';
  String _selectedLanguage = 'English';
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;

  final List<String> _genres = [
    'romance',
    'action',
    'comedy',
    'drama',
    'horror',
    'sci-fi',
    'thriller',
    'animation',
  ];

  final List<String> _languages = [
    'English',
    'French',
    'Spanish',
    'Arabic',
    'Hindi',
    'Mandarin',
    'Japanese',
    'Korean',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        // Compress image
        final compressedBytes = await _compressImage(bytes);

        setState(() {
          _selectedImageBytes = compressedBytes;
          _selectedImageName = image.name;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Image sélectionnée (${(compressedBytes.length / 1024).toStringAsFixed(0)} KB)',
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF6B46C1),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sélection d\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Resize to max 800x1200 for movie posters
      final resized = img.copyResize(
        image,
        width: image.width > 800 ? 800 : image.width,
        height: image.height > 1200 ? 1200 : image.height,
      );

      // Compress to JPEG with 75% quality
      final compressed = img.encodeJpg(resized, quality: 75);
      return Uint8List.fromList(compressed);
    } catch (e) {
      print('Erreur compression: $e');
      return bytes;
    }
  }

  Future<void> _addFilm() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un titre'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = '';

      // Upload image seulement si une image est sélectionnée
      if (_selectedImageBytes != null) {
        // Show upload progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Upload de l\'image en cours...'),
              ],
            ),
            backgroundColor: Color(0xFF6B46C1),
            duration: Duration(seconds: 30),
          ),
        );

        // Upload image to Firebase Storage
        final uploadedUrl = await _storageService
            .uploadMovieImage(
              _selectedImageBytes!,
              _selectedImageName ?? 'movie_image.jpg',
            )
            .timeout(const Duration(seconds: 30), onTimeout: () => null);

        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          // Continue without image if upload fails
          print('Upload échoué, film ajouté sans image');
        }
      }

      // Calculate duration in seconds
      final hour = int.tryParse(_hourController.text) ?? 0;
      final minute = int.tryParse(_minuteController.text) ?? 0;
      final second = int.tryParse(_secondController.text) ?? 0;
      final totalSeconds = (hour * 3600) + (minute * 60) + second;

      // Create Movie object
      final movie = Movie(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        description: _descriptionController.text.trim(),
        duration: totalSeconds > 0
            ? totalSeconds
            : 7200, // Default 2h if not set
        language: _selectedLanguage,
        imageUrl: imageUrl,
        rating: 0.0,
        viewCount: 0,
        createdAt: DateTime.now(),
        cast: [],
        director: '',
        releaseYear: DateTime.now().year,
        availableLanguages: [_selectedLanguage],
      );

      // Add movie to Firestore
      final movieId = await _movieService.addMovie(movie);

      if (movieId == null) {
        throw Exception('Échec de l\'ajout du film');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Film ajouté avec succès!'),
              ],
            ),
            backgroundColor: Color(0xFF6B46C1),
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _hourController.clear();
        _minuteController.clear();
        _secondController.clear();
        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
          _selectedGenre = 'romance';
          _selectedLanguage = 'English';
        });

        // Navigate back after a short delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'film management add',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie Name
              const Text(
                'Movie Name',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Movie genre
              const Text(
                'Movie genre',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGenre,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    items: _genres.map((String genre) {
                      return DropdownMenuItem<String>(
                        value: genre,
                        child: Text(genre),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedGenre = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Upload image
              const Text(
                'Upload image',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImageBytes != null
                          ? const Color(0xFF6B46C1)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedImageBytes != null
                            ? Icons.check_circle
                            : Icons.photo_camera,
                        color: _selectedImageBytes != null
                            ? const Color(0xFF6B46C1)
                            : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImageName ?? 'Photo',
                          style: TextStyle(
                            color: _selectedImageBytes != null
                                ? const Color(0xFF6B46C1)
                                : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description
              const Text(
                'Description',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'bla bla bla',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 20),

              // Duration
              const Text(
                'Duration',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTimeField(_hourController, 'Hour')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeField(_minuteController, 'Minute')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeField(_secondController, 'Second')),
                ],
              ),

              const SizedBox(height: 20),

              // Available Languages
              const Text(
                'Available Languages',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    items: _languages.map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Frame 3 (placeholder)
              const Text(
                'Frame 3',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 30),

              // Add Film Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addFilm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Film',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem('Dashboard', false),
                _buildNavItem('Films', true),
                _buildNavItem('Users', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(TextEditingController controller, String label) {
    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          decoration: InputDecoration(
            hintText: '00',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNavItem(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6B46C1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
