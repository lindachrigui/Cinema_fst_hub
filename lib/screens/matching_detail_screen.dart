import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../services/matching_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class MatchingDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int matchPercentage;

  const MatchingDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.matchPercentage,
  });

  @override
  State<MatchingDetailScreen> createState() => _MatchingDetailScreenState();
}

class _MatchingDetailScreenState extends State<MatchingDetailScreen> {
  final MatchingService _matchingService = MatchingService();
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _commonMovies = [];
  UserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final profile = await _userService.getUserById(widget.userId);
        final movies = await _matchingService.getCommonMovies(widget.userId);

        setState(() {
          _userProfile = profile;
          _commonMovies = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header with back button
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Détails de correspondance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // User Info
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF6B46C1),
                          child: Text(
                            (_userProfile?.displayName ?? widget.userName)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _userProfile?.displayName ?? widget.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (_userProfile?.bio != null &&
                            _userProfile!.bio.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 8,
                            ),
                            child: Text(
                              _userProfile!.bio,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 40),

                        // Percentage of Match
                        const Text(
                          'POURCENTAGE DE CORRESPONDANCE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Circular Progress Indicator
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CustomPaint(
                            painter: CircularProgressPainter(
                              percentage: widget.matchPercentage,
                              color: const Color(0xFF6B46C1),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.matchPercentage}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Common movies section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Films en commun (${_commonMovies.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Movies List
                        if (_commonMovies.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.movie_outlined,
                                  color: Colors.grey[700],
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun film en commun',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: _commonMovies.length,
                              itemBuilder: (context, index) {
                                return _buildMovieCard(_commonMovies[index]);
                              },
                            ),
                          ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie, color: Colors.grey, size: 32),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      movie['title'] ?? 'Sans titre',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final int percentage;
  final Color color;

  CircularProgressPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    // Background circle
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
