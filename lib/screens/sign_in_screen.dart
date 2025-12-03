import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/social_login_button.dart';
import '../services/auth_service.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorDialog('Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Vérifier le rôle de l'utilisateur
        final role = await _authService.getUserRole();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Connexion réussie!')));

          // Navigation selon le rôle
          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        String exceptionString = e.toString();

        if (exceptionString.contains('wrong-password')) {
          errorMessage = 'Mot de passe incorrect';
        } else if (exceptionString.contains('user-not-found')) {
          errorMessage = 'Aucun compte trouvé avec cet email';
        } else if (exceptionString.contains('invalid-email')) {
          errorMessage = 'Email invalide';
        } else if (exceptionString.contains('désactivé') ||
            exceptionString.contains('desactivated') ||
            exceptionString.contains('administrateur')) {
          errorMessage =
              'Votre compte a été désactivé. Veuillez contacter l\'administrateur.';
        } else {
          // Extraire le message après "Exception: "
          if (exceptionString.contains('Exception: ')) {
            errorMessage = exceptionString.split('Exception: ').last;
          } else {
            errorMessage = exceptionString;
          }
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        String errorString = e.toString();

        // Extraire le message d'erreur propre
        if (errorString.contains('Exception: ')) {
          errorMessage = errorString.split('Exception: ').last;
        } else if (errorString.contains('désactivé') ||
            errorString.contains('administrateur')) {
          errorMessage =
              'Votre compte a été désactivé. Veuillez contacter l\'administrateur.';
        } else {
          errorMessage = errorString;
        }
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Erreur', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF6B46C1))),
          ),
        ],
      ),
    );
  }

  void _handleSocialLogin(String provider) async {
    if (provider == 'Google') {
      await _handleGoogleSignIn();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connexion avec $provider (Non implémenté)')),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        // Vérifier le rôle de l'utilisateur
        final role = await _authService.getUserRole();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion Google réussie!')),
          );

          // Navigation selon le rôle
          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        String errorString = e.toString();

        if (errorString.contains('Google Sign-In n\'est pas configuré')) {
          errorMessage =
              'Google Sign-In n\'est pas encore configuré.\n\nPour l\'activer :\n1. Obtenez un Client ID Google\n2. Remplacez YOUR_GOOGLE_CLIENT_ID dans web/index.html';
        } else if (errorString.contains('Exception: ')) {
          errorMessage = errorString.split('Exception: ').last;
        } else if (errorString.contains('désactivé') ||
            errorString.contains('administrateur')) {
          errorMessage =
              'Votre compte a été désactivé. Veuillez contacter l\'administrateur.';
        } else {
          errorMessage = errorString;
        }
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réinitialisation du mot de passe')),
    );
  }

  void _handleSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),
              // Welcome message
              const Text(
                'WELCOME',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'BACK!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // Email field
              CustomTextField(
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Password field
              CustomTextField(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),

              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF6B46C1), fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login button
              CustomButton(
                text: 'Login',
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 40),

              // OR divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[700])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '- OR Continue with -',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[700])),
                ],
              ),

              const SizedBox(height: 24),

              // Social login buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialLoginButton(
                    assetPath: 'google',
                    onPressed: () => _handleSocialLogin('Google'),
                  ),
                  SocialLoginButton(
                    assetPath: 'apple',
                    onPressed: () => _handleSocialLogin('Apple'),
                  ),
                  SocialLoginButton(
                    assetPath: 'facebook',
                    onPressed: () => _handleSocialLogin('Facebook'),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create An Account ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _handleSignUp,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF6B46C1),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
