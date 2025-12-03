# 🎬 Cinema FST Hub

A modern Flutter cinema application with Firebase backend and Google Sign-In authentication.

## 🚀 Features

- 🔐 **Authentication System**
  - Email/Password authentication
  - Google Sign-In integration
  - User profile management
  - Admin dashboard
- 🎥 **Movie Management**
  - Browse movies from database and TMDB API
  - Add/Edit/Delete movies (Admin)
  - Movie details with ratings
  - Favorite movies system
- 👥 **User Features**
  - Personal profile customization
  - Favorite movies collection
  - Movie matching system
  - Search and filter movies
- 📱 **Multi-Platform**
  - Web (Chrome, Edge, Firefox)
  - Android (coming soon)
  - iOS (coming soon)

---

## 📋 Prerequisites

- Flutter SDK (3.8.1 or higher)
- Firebase account
- Google Cloud Console account (for Google Sign-In)
- Dart SDK

---

## 🛠️ Installation

### 1. Clone the repository

```bash
git clone https://github.com/helazouch/Cinema_fst_hub.git
cd Cinema_fst_hub
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

The Firebase configuration is already set up in `lib/firebase_options.dart` for the web platform.

For other platforms (Android, iOS), you'll need to:

1. Download the appropriate configuration files from Firebase Console
2. Place them in the correct directories
3. Update `lib/firebase_options.dart` with your platform-specific values

### 4. Configure Google Sign-In

**⚠️ Required for Google authentication to work**

Choose one of these methods:

#### Option A: Automated Setup (Windows - PowerShell)

```powershell
.\setup_google_signin.ps1
```

#### Option B: Manual Setup (5 minutes)

Follow the detailed guide: **[GOOGLE_SIGNIN_README.md](./GOOGLE_SIGNIN_README.md)**

**Quick steps:**

1. Enable Google Sign-In in [Firebase Console](https://console.firebase.google.com/)
2. Copy your Web Client ID
3. Update `web/index.html` (line 34)
4. Run with: `flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID`

📚 **Full documentation:**

- [Quick Start Guide](./ACTIVATION_GOOGLE_SIGNIN.md)
- [Complete Setup Guide](./GOOGLE_SETUP.md)

---

## 🎮 Running the Application

### Web (Chrome)

```bash
# Without Google Sign-In
flutter run -d chrome

# With Google Sign-In
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID
```

### Android (when configured)

```bash
flutter run -d android
```

### iOS (when configured)

```bash
flutter run -d ios
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart                 # Application entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
├── screens/                  # UI screens
│   ├── sign_in_screen.dart
│   ├── sign_up_screen.dart
│   ├── home_screen.dart
│   ├── admin_*.dart         # Admin screens
│   └── ...
├── services/                 # Business logic & Firebase services
│   ├── auth_service.dart    # Authentication (Email + Google)
│   ├── movie_service.dart
│   ├── favorite_service.dart
│   └── ...
└── widgets/                  # Reusable UI components
```

---

## 🔐 Authentication

### User Roles

- **User** (default): Can browse movies, add favorites, use matching system
- **Admin**: Full access including movie management and user administration

### Default Admin Account

To create an admin account:

1. Sign up normally through the app
2. Go to Firebase Console → Firestore Database
3. Find your user document in the `users` collection
4. Change the `role` field from `user` to `admin`

---

## 🎨 Technologies Used

- **Frontend**: Flutter & Dart
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Authentication**: Firebase Auth + Google Sign-In
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage + Cloudinary
- **API**: The Movie Database (TMDB) API
- **State Management**: StatefulWidget

---

## 📦 Key Dependencies

```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.3
firebase_storage: ^12.3.2
google_sign_in: ^6.2.1 # Google Sign-In
image_picker: ^1.1.2
cloudinary_public: ^0.21.0
http: ^1.2.0
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Authors

- **Hela Zouch** - [helazouch](https://github.com/helazouch)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend services
- TMDB for the movie API
- Google Sign-In for authentication

---

## 📞 Support

If you encounter any issues:

1. Check the [Google Sign-In Setup Guide](./GOOGLE_SIGNIN_README.md)
2. Review the [Troubleshooting section](./GOOGLE_SETUP.md#-résolution-des-problèmes)
3. Open an issue on GitHub

---

**Made with ❤️ using Flutter**
