# 🔥 Configuration Index Firestore - Favoris

## Erreur rencontrée

```
The query requires an index. You can create it here: https://console.firebase.google.com/...
```

## Solution Rapide

### Option 1 : Cliquer sur le lien (Recommandé)

1. Copiez le lien complet qui apparaît dans l'erreur
2. Collez-le dans votre navigateur
3. Cliquez sur **"Create Index"**
4. Attendez 2-3 minutes que l'index se crée
5. Relancez l'application

### Option 2 : Créer manuellement

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet **"cinema-fst-hub"**
3. Dans le menu de gauche : **Firestore Database** > **Indexes**
4. Cliquez sur **"Create Index"**
5. Configurez :
   - **Collection ID**: `favorites`
   - **Fields to index**:
     - Field: `userId` - Order: Ascending
     - Field: `addedAt` - Order: Descending
   - **Query scope**: Collection
6. Cliquez sur **"Create"**
7. Attendez que le status passe à **"Enabled"** (2-3 minutes)

## Après création de l'index

Une fois l'index créé, décommentez cette ligne dans `favorite_service.dart` :

```dart
// Ligne 70 environ
return _favoritesCollection
    .where('userId', isEqualTo: userId)
    .orderBy('addedAt', descending: true) // ← Décommenter cette ligne
    .snapshots()
```

Et supprimez le tri côté client (lignes 79-85).

## Solution temporaire actuelle

✅ L'application fonctionne SANS l'index

- Les favoris sont triés côté client
- Moins performant mais fonctionnel
- Une fois l'index créé, mettez à jour le code pour plus de performance

## Vérification

Pour vérifier si l'index est créé :

1. Firebase Console > Firestore > Indexes
2. Cherchez un index pour la collection `favorites`
3. Status doit être **"Enabled"**

---

**Note**: L'index est nécessaire pour les requêtes combinant `.where()` + `.orderBy()` sur des champs différents.
