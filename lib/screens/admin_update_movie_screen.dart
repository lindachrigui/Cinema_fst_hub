import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../services/movie_service.dart';
import '../services/cloudinary_service.dart';
import '../models/movie_model.dart';

class AdminUpdateMovieScreen extends StatefulWidget {
  final Movie movie;

  const AdminUpdateMovieScreen({super.key, required this.movie});

  @override
  State<AdminUpdateMovieScreen> createState() => _AdminUpdateMovieScreenState();
}

class _AdminUpdateMovieScreenState extends State<AdminUpdateMovieScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late TextEditingController _secondController;
  late TextEditingController _ratingController;

  final MovieService _movieService = MovieService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  late String _selectedGenre;
  late String _selectedLanguage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;
  bool _imageChanged = false;

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
  void initState() {
    super.initState();
    // Initialize controllers with movie data
    _titleController = TextEditingController(text: widget.movie.title);
    _descriptionController = TextEditingController(
      text: widget.movie.description,
    );

    // Convert duration from seconds to hours, minutes, seconds
    final totalSeconds = widget.movie.duration;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    _hourController = TextEditingController(
      text: hours > 0 ? hours.toString() : '',
    );
    _minuteController = TextEditingController(
      text: minutes > 0 ? minutes.toString() : '',
    );
    _secondController = TextEditingController(
      text: seconds > 0 ? seconds.toString() : '',
    );

    _ratingController = TextEditingController(
      text: widget.movie.rating > 0 ? widget.movie.rating.toString() : '',
    );

    _selectedGenre = widget.movie.genre;
    _selectedLanguage = widget.movie.language.isNotEmpty
        ? widget.movie.language
        : 'English';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1800,
      );

      if (image != null) {
        // Show loading indicator
        if (mounted) {
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
                  Text('Compression de l\'image...'),
                ],
              ),
              backgroundColor: Color(0xFF6B46C1),
              duration: Duration(seconds: 10),
            ),
          );
        }

        final bytes = await image.readAsBytes();

        // Compress image asynchronously
        final compressedBytes = await _compressImage(bytes);

        setState(() {
          _selectedImageBytes = compressedBytes;
          _selectedImageName = image.name;
          _imageChanged = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Nouvelle image prête (${(compressedBytes.length / 1024).toStringAsFixed(0)} KB)',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
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

      // Resize to max 600x900 for movie posters (plus léger)
      final int targetWidth = image.width > 600 ? 600 : image.width;
      final int targetHeight = image.height > 900 ? 900 : image.height;

      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average, // Plus rapide
      );

      // Compress to JPEG with 70% quality
      final compressed = img.encodeJpg(resized, quality: 70);
      return Uint8List.fromList(compressed);
    } catch (e) {
      print('Erreur compression: $e');
      return bytes;
    }
  }

  Future<void> _updateFilm() async {
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
      String imageUrl = widget.movie.imageUrl;

      // Upload new image if changed
      if (_imageChanged && _selectedImageBytes != null) {
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
                Text('Upload vers Cloudinary...'),
              ],
            ),
            backgroundColor: Color(0xFF6B46C1),
            duration: Duration(minutes: 1),
          ),
        );

        // Upload image to Cloudinary
        final uploadedUrl = await _cloudinaryService
            .uploadMovieImage(
              imageBytes: _selectedImageBytes!,
              fileName: _selectedImageName ?? 'movie_image.jpg',
            )
            .timeout(const Duration(minutes: 1), onTimeout: () => null);

        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          print('Upload échoué, image non mise à jour');
        }
      }

      // Calculate duration in seconds
      final hour = int.tryParse(_hourController.text) ?? 0;
      final minute = int.tryParse(_minuteController.text) ?? 0;
      final second = int.tryParse(_secondController.text) ?? 0;
      final totalSeconds = (hour * 3600) + (minute * 60) + second;

      // Create updated Movie object
      final updatedMovie = widget.movie.copyWith(
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        description: _descriptionController.text.trim(),
        duration: totalSeconds > 0 ? totalSeconds : widget.movie.duration,
        language: _selectedLanguage,
        imageUrl: imageUrl,
        rating: double.tryParse(_ratingController.text) ?? widget.movie.rating,
        availableLanguages: [_selectedLanguage],
      );

      // Update movie in Firestore
      await _movieService.updateMovie(widget.movie.id, updatedMovie);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Film mis à jour avec succès!'),
              ],
            ),
            backgroundColor: Color(0xFF6B46C1),
          ),
        );

        // Navigate back after a short delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
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
          'film management update',
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

              // Rating
              const Text(
                'Rating',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ratingController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '0.0 - 10.0',
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
                  prefixIcon: const Icon(Icons.star, color: Colors.amber),
                ),
              ),

              const SizedBox(height: 20),

              // Upload image
              const Text(
                'Update image',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Show current image
              if (widget.movie.imageUrl.isNotEmpty && !_imageChanged)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6B46C1),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.movie.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6B46C1),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: Icon(
                              Icons.movie,
                              color: Color(0xFF6B46C1),
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

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
                      color: _imageChanged
                          ? const Color(0xFF6B46C1)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _imageChanged ? Icons.check_circle : Icons.photo_camera,
                        color: _imageChanged
                            ? const Color(0xFF6B46C1)
                            : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _imageChanged
                              ? (_selectedImageName ?? 'Nouvelle image')
                              : 'Changer l\'image',
                          style: TextStyle(
                            color: _imageChanged
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

              const SizedBox(height: 30),

              // Update Film Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateFilm,
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
                          'Update Film',
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
