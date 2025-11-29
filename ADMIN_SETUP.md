# Guide de Configuration Admin

## Modifications effectuées

### 1. Nouvelles pages admin créées

- **admin_dashboard_screen.dart** : Tableau de bord avec statistiques (nombre de films, utilisateurs actifs, pourcentage de visionnage)
- **admin_users_screen.dart** : Gestion des utilisateurs (activation/désactivation)

### 2. Champ "role" ajouté à la base de données

Tous les nouveaux utilisateurs reçoivent automatiquement :

- `role: 'user'` (par défaut)
- `isActive: true` (par défaut)

### 3. Redirection automatique selon le rôle

- **Admin** → AdminDashboardScreen
- **User** → HomeScreen

## Comment créer un compte administrateur

### Méthode 1 : Via Firebase Console (Recommandé)

1. Connectez-vous à la Firebase Console : https://console.firebase.google.com/
2. Sélectionnez votre projet "Cinema FST Hub"
3. Allez dans **Firestore Database**
4. Trouvez la collection `users`
5. Sélectionnez le document de l'utilisateur que vous voulez promouvoir admin
6. Cliquez sur **Edit document**
7. Modifiez le champ `role` de `user` à `admin`
8. Sauvegardez les modifications

### Méthode 2 : Créer un compte puis modifier dans Firestore

1. **Créez un compte** via l'application (Sign Up)

   - Remplissez tous les champs (prénom, nom, email, date de naissance, mot de passe)
   - Le compte sera créé avec `role: 'user'` par défaut

2. **Modifiez le rôle dans Firebase Console**

   - Allez dans Firestore Database
   - Collection `users` → trouvez votre compte
   - Changez `role: 'user'` → `role: 'admin'`

3. **Déconnectez-vous et reconnectez-vous**
   - L'application vérifie le rôle à chaque connexion
   - Vous serez redirigé vers le dashboard admin

## Structure des données utilisateur dans Firestore

```json
{
  "uid": "abc123...",
  "email": "admin@example.com",
  "firstName": "Admin",
  "lastName": "User",
  "displayName": "Admin User",
  "dateOfBirth": "01/01/1990",
  "photoURL": null,
  "createdAt": "2025-11-29...",
  "lastSignIn": "2025-11-29...",
  "authProvider": "email",
  "role": "admin", // ← Changez ceci pour faire un admin
  "isActive": true
}
```

## Fonctionnalités Admin

### Dashboard Admin

- Nombre total de films
- Nombre d'utilisateurs actifs
- Nombre total d'utilisateurs
- Pourcentage d'utilisateurs actifs
- Pourcentage de visionnage
- Film le plus regardé
- Navigation : Dashboard | Films | Users

### Gestion des Utilisateurs

- Liste de tous les utilisateurs (rôle "user" uniquement)
- Activation/Désactivation des comptes
- Affichage des informations : nom, email
- Boutons : "Activated" (violet) / "Deactivated" (rouge)

## Test de la fonctionnalité

1. **Créez 2 comptes** :

   - Compte 1 : utilisateur normal
   - Compte 2 : administrateur (modifiez le rôle dans Firebase)

2. **Connectez-vous avec le compte utilisateur** :

   - Vous devriez arriver sur HomeScreen (page normale avec films)

3. **Déconnectez-vous et connectez-vous avec le compte admin** :

   - Vous devriez arriver sur AdminDashboardScreen (statistiques)

4. **Testez la gestion des utilisateurs** :
   - Cliquez sur "Users" dans le navbar
   - Vous verrez la liste des utilisateurs
   - Testez les boutons Activated/Deactivated

## Notes importantes

- Les administrateurs ne peuvent pas gérer d'autres administrateurs (filtre `where('role', isEqualTo: 'user')`)
- Le logout fonctionne depuis les pages admin également
- Les statistiques se chargent en temps réel depuis Firestore
- L'état `isActive` permet de désactiver un compte sans le supprimer

## Commande pour tester

```bash
flutter run -d chrome
```

Créez votre premier compte, puis modifiez son rôle dans Firebase Console pour le transformer en admin !
