# 🔐 Configuration Google Sign-In pour Cinema FST Hub

## 🎯 État actuel

✅ **Code implémenté** : Les méthodes Google Sign-In sont intégrées dans l'application  
⚠️ **Configuration nécessaire** : Vous devez configurer le Client ID Google pour activer l'authentification

---

## 📋 Guide de configuration complet

### Étape 1 : Activer Google Sign-In dans Firebase

1. **Allez sur Firebase Console**

   - Ouvrez [Firebase Console](https://console.firebase.google.com/)
   - Sélectionnez votre projet **cinema-fst-hub**

2. **Activez Google Authentication**
   - Cliquez sur **Authentication** dans le menu latéral
   - Allez dans l'onglet **Sign-in method**
   - Trouvez **Google** dans la liste des providers
   - Cliquez sur **Google** puis sur **Enable**
   - Ajoutez votre email de support (obligatoire)
   - Cliquez sur **Save**

### Étape 2 : Obtenir votre Google Client ID pour le Web

1. **Dans Firebase Console**

   - Restez dans **Authentication** > **Sign-in method**
   - Cliquez sur **Google** (déjà activé)
   - Vous verrez une section **Web SDK configuration**
   - **Copiez le Web client ID** (il ressemble à : `123456789-abcdefg.apps.googleusercontent.com`)

2. **Alternative : Via Google Cloud Console**
   - Allez sur [Google Cloud Console](https://console.cloud.google.com/)
   - Sélectionnez le projet **cinema-fst-hub**
   - Allez dans **APIs & Services** > **Credentials**
   - Vous verrez un **OAuth 2.0 Client ID** de type **Web application**
   - Copiez le **Client ID**

### Étape 3 : Configurer le Client ID dans votre application

**Méthode A : Configuration via variable d'environnement (Recommandée)**

**Méthode A : Configuration via variable d'environnement (Recommandée)**

Lancez votre application avec le Client ID :

```bash
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID_ICI
```

**Méthode B : Configuration directe dans le code**

Modifiez `lib/services/auth_service.dart` ligne 8-14 :

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: 'VOTRE_CLIENT_ID_ICI.apps.googleusercontent.com',
);
```

### Étape 4 : Mettre à jour web/index.html

Ouvrez `web/index.html` et remplacez `YOUR_GOOGLE_CLIENT_ID` par votre vrai Client ID :

```html
<meta
  name="google-signin-client_id"
  content="123456789-abcdefg.apps.googleusercontent.com"
/>
```

### Étape 5 : Configurer les origines autorisées

1. **Dans Google Cloud Console**
   - Allez dans **APIs & Services** > **Credentials**
   - Cliquez sur votre **OAuth 2.0 Client ID** (Web application)
2. **Ajoutez les origines autorisées**
   - **Authorized JavaScript origins:**
     ```
     http://localhost:63213
     http://localhost:63214
     http://localhost:63215
     http://localhost
     http://127.0.0.1
     ```
3. **Ajoutez les URI de redirection autorisées**

   - **Authorized redirect URIs:**
     ```
     http://localhost:63213/__/auth/handler
     http://localhost:63214/__/auth/handler
     http://localhost:63215/__/auth/handler
     http://localhost/__/auth/handler
     ```

4. Cliquez sur **Save**

### Étape 6 : Tester l'authentification

1. **Lancez l'application :**

   ```bash
   # Avec variable d'environnement
   flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID

   # Ou simplement
   flutter run -d chrome
   ```

2. **Testez la connexion :**
   - Cliquez sur le bouton **Continue with Google** sur l'écran de connexion
   - Sélectionnez votre compte Google
   - Autorisez l'application
   - Vous devriez être redirigé vers l'écran d'accueil

---

## 🔧 Configuration Android (Optionnel)

### Étape 1 : Télécharger google-services.json

1. Dans Firebase Console > **Project Settings**
2. Sous **Your apps**, sélectionnez votre app Android
3. Téléchargez `google-services.json`
4. Placez-le dans `android/app/`

### Étape 2 : Ajouter le plugin Google Services

Modifiez `android/build.gradle.kts` :

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Ajoutez cette ligne
}
```

### Étape 3 : Obtenir le SHA-1

```bash
cd android
./gradlew signingReport
```

Copiez le SHA-1 et ajoutez-le dans Firebase Console > Project Settings > Your apps > Android app

---

## 🍎 Configuration iOS (Optionnel)

### Étape 1 : Télécharger GoogleService-Info.plist

1. Dans Firebase Console > **Project Settings**
2. Sous **Your apps**, sélectionnez votre app iOS
3. Téléchargez `GoogleService-Info.plist`
4. Placez-le dans `ios/Runner/`

### Étape 2 : Configurer Info.plist

Ajoutez dans `ios/Runner/Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.VOTRE_CLIENT_ID_REVERSE</string>
        </array>
    </dict>
</array>
```

---

## 📱 Utilisation dans le code

### Méthodes disponibles

```dart
// Connexion avec Google
final authService = AuthService();
try {
  final user = await authService.signInWithGoogle();
  print('Connecté : ${user?.displayName}');
} catch (e) {
  print('Erreur : $e');
}

// Inscription avec Google (même processus)
final user = await authService.signUpWithGoogle();

// Déconnexion
await authService.signOut();
```

### Gestion des erreurs

L'application gère automatiquement :

- ✅ Annulation par l'utilisateur
- ✅ Erreurs réseau
- ✅ Erreurs d'authentification Firebase
- ✅ Comptes désactivés
- ✅ Création automatique du profil utilisateur dans Firestore

---

## 🐛 Résolution des problèmes

### Erreur : "Google Sign-In is not yet configured"

**Solution :** Vous devez configurer le Client ID. Suivez l'Étape 3 ci-dessus.

### Erreur : "popup_closed_by_user"

**Solution :** Normal, l'utilisateur a fermé la fenêtre Google. Ce n'est pas une erreur critique.

### Erreur : "redirect_uri_mismatch"

**Solution :** Ajoutez l'URI dans Google Cloud Console > Credentials > Authorized redirect URIs.

### Erreur : "origin_mismatch"

**Solution :** Ajoutez l'origine dans Google Cloud Console > Credentials > Authorized JavaScript origins.

### L'authentification fonctionne mais l'utilisateur n'est pas créé

**Vérifiez :**

- Les règles Firestore permettent l'écriture dans la collection `users`
- Le compte Firebase n'a pas atteint sa limite d'utilisateurs

---

## 📚 Ressources utiles

- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Documentation Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Documentation Firebase Auth Flutter](https://firebase.flutter.dev/docs/auth/overview)

---

## ✅ Checklist de configuration

- [ ] Google Sign-In activé dans Firebase Console
- [ ] Client ID copié depuis Firebase
- [ ] Client ID ajouté dans `auth_service.dart` ou via `--dart-define`
- [ ] `web/index.html` mis à jour avec le Client ID
- [ ] Origines JavaScript autorisées dans Google Cloud Console
- [ ] URI de redirection autorisées dans Google Cloud Console
- [ ] Application testée avec succès

---

## 📝 Notes importantes

- ⚠️ Le Client ID est **différent** pour chaque plateforme (Web, Android, iOS)
- 🌐 Pour le web, utilisez le **Web client ID** de Firebase
- 📱 Pour Android/iOS, les configurations sont automatiques avec les fichiers JSON/plist
- 🔒 Ne partagez JAMAIS votre Client ID dans un dépôt public
- ✨ Les utilisateurs Google sont automatiquement créés dans Firestore
- 🎯 Le rôle par défaut est `user` (peut être changé manuellement dans Firestore)
- 🌐 L'authentification Google web nécessite une connexion internet
- 👤 Les utilisateurs peuvent annuler le processus d'authentification
- 💾 Les données utilisateur sont automatiquement sauvegardées dans Firestore
- 🚪 La déconnexion supprime à la fois la session Firebase et Google

---

## 🚀 Commandes rapides

```bash
# Installer les dépendances
flutter pub get

# Lancer en mode web avec Client ID
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID

# Lancer en mode debug
flutter run -d chrome

# Build pour production
flutter build web --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID
```

---

## 📂 Fichiers modifiés

- ✅ `lib/services/auth_service.dart` : Méthodes Google Sign-In/Sign-Up
- ✅ `lib/screens/sign_in_screen.dart` : Bouton Google Sign-In
- ✅ `lib/screens/sign_up_screen.dart` : Bouton Google Sign-Up
- ✅ `pubspec.yaml` : Dépendance `google_sign_in: ^6.2.1`
- ⚠️ `web/index.html` : À mettre à jour avec votre Client ID
- ⚠️ `lib/services/auth_service.dart` : À mettre à jour avec votre Client ID (ligne 10)

---

**Dernière mise à jour :** Décembre 2025  
**Version :** 1.0.0
