# 📋 Documentation des Routes API - myROX

## Vue d'ensemble

Cette documentation décrit toutes les routes disponibles dans l'API myROX. L'API est construite avec Fastify et utilise Prisma comme ORM pour PostgreSQL.

**Base URL** : `http://localhost:3001`  
**Documentation interactive** : `http://localhost:3001/docs`  
**Version** : 1.0.0

## 🔐 Authentification

L'API utilise Firebase Authentication. Les requêtes authentifiées doivent inclure le header :
```
x-firebase-uid: <firebase_user_uid>
```

## 📊 Routes disponibles

### 🏠 **Root & Health**

#### `GET /`
- **Description** : Informations générales de l'API
- **Authentification** : Non requise
- **Réponse** :
```json
{
  "message": "🚀 myROX API",
  "version": "1.0.0",
  "environment": "development",
  "endpoints": {
    "health": "/api/v1/health",
    "docs": "/docs",
    "swagger": "/docs/json"
  }
}
```

#### `GET /api/v1/health`
- **Description** : Vérification de l'état de l'API
- **Authentification** : Non requise
- **Réponse** :
```json
{
  "status": "ok",
  "timestamp": "2025-06-06T07:45:06.333Z",
  "version": "1.0.0",
  "uptime": 76,
  "environment": "development",
  "message": "🚀 myROX API is healthy!",
  "checks": {
    "database": "connected",
    "responseTime": "2ms"
  }
}
```

#### `GET /api/v1/ping`
- **Description** : Simple ping pour tester la connectivité
- **Authentification** : Non requise
- **Réponse** :
```json
{
  "message": "pong",
  "timestamp": "2025-06-06T07:45:06.333Z"
}
```

---

### 👤 **Users**

#### `GET /api/v1/users/firebase/:firebaseUID`
- **Description** : Récupérer le profil utilisateur
- **Authentification** : Requise (propre profil uniquement)
- **Paramètres** :
  - `firebaseUID` (string) : UID Firebase de l'utilisateur
- **Réponse** :
```json
{
  "id": "user-uuid",
  "firebaseUID": "firebase-uid",
  "email": "user@example.com",
  "displayName": "John Doe",
  "coachId": "coach-uuid",
  "coach": {
    "id": "coach-uuid",
    "displayName": "Coach Name",
    "specialization": "HYROX"
  },
  "createdAt": "2023-01-15T00:00:00.000Z",
  "updatedAt": "2023-01-15T00:00:00.000Z"
}
```

#### `POST /api/v1/users`
- **Description** : Créer un nouveau profil utilisateur
- **Authentification** : Requise
- **Body** :
```json
{
  "firebaseUID": "firebase-uid",
  "email": "user@example.com",
  "displayName": "John Doe"
}
```

#### `PUT /api/v1/users/firebase/:firebaseUID`
- **Description** : Mettre à jour le profil utilisateur
- **Authentification** : Requise (propre profil uniquement)
- **Body** :
```json
{
  "displayName": "New Name",
  "email": "new@example.com"
}
```

#### `GET /api/v1/users/firebase/:firebaseUID/personal-templates`
- **Description** : Templates personnels de l'utilisateur
- **Authentification** : Requise

#### `GET /api/v1/users/firebase/:firebaseUID/assigned-templates`
- **Description** : Templates assignés par le coach
- **Authentification** : Requise

#### `POST /api/v1/users/firebase/:firebaseUID/personal-templates`
- **Description** : Créer un template personnel
- **Authentification** : Requise

#### `PUT /api/v1/users/firebase/:firebaseUID/personal-templates/:templateId`
- **Description** : Modifier un template personnel
- **Authentification** : Requise

#### `DELETE /api/v1/users/firebase/:firebaseUID/personal-templates/:templateId`
- **Description** : Supprimer un template personnel
- **Authentification** : Requise

---

### 🏃‍♀️ **Workouts**

#### `GET /api/v1/users/firebase/:firebaseUID/workouts`
- **Description** : Récupérer tous les workouts d'un utilisateur
- **Authentification** : Requise (propre profil uniquement)
- **Query Parameters** :
  - `includeIncomplete` (boolean, default: false) : Inclure les workouts non terminés
  - `limit` (number, default: 50) : Nombre limite de résultats
  - `offset` (number, default: 0) : Décalage pour la pagination
- **Réponse** :
```json
[
  {
    "id": "workout-uuid",
    "name": "HYROX Training",
    "startedAt": "2023-01-15T10:00:00.000Z",
    "completedAt": "2023-01-15T11:30:00.000Z",
    "totalDuration": 5400,
    "notes": "Great session!",
    "rating": 4,
    "templateId": "template-uuid",
    "template": {
      "id": "template-uuid",
      "name": "HYROX Prep"
    },
    "exercises": [
      {
        "id": "exercise-uuid",
        "order": 1,
        "sets": 3,
        "repsCompleted": 100,
        "durationCompleted": 300,
        "distanceCompleted": 1000,
        "weightUsed": 20,
        "restTime": 60,
        "notes": "Felt good",
        "completedAt": "2023-01-15T10:15:00.000Z",
        "exercise": {
          "id": "ex-uuid",
          "name": "SkiErg",
          "category": "HYROX_STATION"
        }
      }
    ]
  }
]
```

#### `POST /api/v1/users/firebase/:firebaseUID/workouts`
- **Description** : Créer un nouveau workout
- **Authentification** : Requise
- **Body** :
```json
{
  "templateId": "template-uuid",
  "name": "My Workout",
  "exercises": [
    {
      "exerciseId": "exercise-uuid",
      "order": 1,
      "sets": 3,
      "targetReps": 100,
      "targetDuration": 300,
      "targetDistance": 1000,
      "targetWeight": 20,
      "restTime": 60
    }
  ]
}
```

#### `PUT /api/v1/users/firebase/:firebaseUID/workouts/:workoutId`
- **Description** : Mettre à jour un workout existant
- **Authentification** : Requise

#### `DELETE /api/v1/users/firebase/:firebaseUID/workouts/:workoutId`
- **Description** : Supprimer un workout
- **Authentification** : Requise

#### `GET /api/v1/users/firebase/:firebaseUID/personal-bests`
- **Description** : Récupérer les records personnels
- **Authentification** : Requise

#### `POST /api/v1/users/firebase/:firebaseUID/personal-bests`
- **Description** : Créer un nouveau record personnel
- **Authentification** : Requise

#### `PUT /api/v1/users/firebase/:firebaseUID/personal-bests/:personalBestId`
- **Description** : Mettre à jour un record personnel
- **Authentification** : Requise

#### `DELETE /api/v1/users/firebase/:firebaseUID/personal-bests/:personalBestId`
- **Description** : Supprimer un record personnel
- **Authentification** : Requise

---

### 💪 **Exercises**

#### `GET /api/v1/exercises`
- **Description** : Liste de tous les exercices disponibles
- **Authentification** : Non requise
- **Réponse** :
```json
[
  {
    "id": "exercise-uuid",
    "name": "SkiErg",
    "description": "Machine SkiErg",
    "category": "HYROX_STATION",
    "equipment": ["SkiErg"],
    "instructions": "Maintenez un rythme régulier avec engagement de tout le corps",
    "isHyroxExercise": true
  }
]
```

#### `GET /api/v1/exercises/:id`
- **Description** : Récupérer un exercice spécifique
- **Authentification** : Non requise
- **Paramètres** :
  - `id` (string) : ID de l'exercice
- **Réponse** : Objet exercice (voir format ci-dessus)

---

### 👨‍🏫 **Coaches**

#### `GET /api/v1/coaches/:id`
- **Description** : Informations publiques d'un coach
- **Authentification** : Non requise
- **Paramètres** :
  - `id` (string) : ID du coach
- **Réponse** :
```json
{
  "id": "coach-uuid",
  "name": "Coach Expert",
  "email": "coach@myrox.app",
  "bio": "Coach certifié HYROX avec 5 ans d'expérience",
  "certifications": [
    "HYROX Master Trainer",
    "CrossFit Level 2",
    "Nutrition Sportive"
  ],
  "profilePicture": "https://example.com/image.jpg",
  "createdAt": "2023-01-15T00:00:00.000Z",
  "isActive": true
}
```

#### `GET /api/v1/coaches/:id/athletes`
- **Description** : Liste des athlètes d'un coach (Web uniquement)
- **Authentification** : Requise
- **Note** : Cette route retourne une erreur 403 pour l'app mobile

#### `GET /api/v1/coaches/:id/stats/detailed`
- **Description** : Statistiques détaillées du coach
- **Authentification** : Requise
- **Query Parameters** :
  - `period` (enum: '7d', '30d', '90d', default: '30d') : Période d'analyse
- **Réponse** :
```json
{
  "athleteStats": [
    {
      "athleteId": "athlete-uuid",
      "athleteName": "Athlete Name",
      "totalWorkouts": 15,
      "avgRating": 4.3,
      "totalTime": 720,
      "completionRate": 87
    }
  ],
  "workoutTrends": [
    {
      "date": "2024-01-01",
      "count": 3,
      "avgRating": 4.1
    }
  ],
  "categoryStats": [
    {
      "name": "HYROX",
      "value": 35,
      "color": "#3B82F6"
    }
  ],
  "summary": {
    "totalWorkouts": 150,
    "avgRating": 4.2,
    "avgCompletionRate": 88,
    "activeAthletes": 12
  }
}
```

#### `GET /api/v1/coaches/:id/templates`
- **Description** : Templates créés par le coach
- **Authentification** : Requise

#### `GET /api/v1/coaches/:id/statistics`
- **Description** : Statistiques générales du coach
- **Authentification** : Requise

---

## 📂 Catégories d'exercices

Les exercices sont organisés selon ces catégories :

- **HYROX_STATION** : 8 stations officielles HYROX
- **CARDIO** : Exercices cardiovasculaires
- **STRENGTH** : Exercices de force
- **FUNCTIONAL** : Exercices fonctionnels
- **RUNNING** : Course à pied
- **CORE** : Renforcement du core
- **PLYOMETRIC** : Exercices pliométriques

## 🏆 Exercices HYROX officiels

Les 8 stations officielles HYROX disponibles :

1. **SkiErg** - Machine SkiErg
2. **Sled Push** - Poussée de traîneau
3. **Sled Pull** - Traction de traîneau
4. **Burpees Broad Jump** - Burpees avec saut en longueur
5. **RowErg** - Rameur
6. **Farmers Carry** - Transport de poids
7. **Sandbag Lunges** - Fentes avec sac de sable
8. **Wall Balls** - Wall balls

## 🔒 Sécurité & Permissions

- Les utilisateurs ne peuvent accéder qu'à leurs propres données
- Les coaches ont accès aux données de leurs athlètes
- Certaines routes sont restreintes à l'interface web uniquement
- L'authentification Firebase est requise pour toutes les opérations sensibles

## 📊 Codes de statut HTTP

- **200** : Succès
- **201** : Créé avec succès
- **400** : Requête invalide
- **401** : Non authentifié
- **403** : Accès interdit
- **404** : Ressource non trouvée
- **409** : Conflit (ressource déjà existante)
- **500** : Erreur serveur interne

## 🐛 Gestion des erreurs

Format standard des erreurs :
```json
{
  "success": false,
  "error": "Message d'erreur",
  "statusCode": 400,
  "timestamp": "2025-06-06T07:45:06.333Z"
}
``` 