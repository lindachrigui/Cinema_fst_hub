import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/splash_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/home_screen.dart';
import '../screens/admin_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Affichage pendant le chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Si l'utilisateur est connecté
        if (snapshot.hasData && snapshot.data != null) {
          // Vérifier le rôle de l'utilisateur pour rediriger
          return FutureBuilder<String>(
            future: authService.getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              final role = roleSnapshot.data ?? 'user';

              // Rediriger selon le rôle
              if (role == 'admin') {
                return const AdminDashboardScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        }

        // Si l'utilisateur n'est pas connecté
        return const SignInScreen();
      },
    );
  }
}
