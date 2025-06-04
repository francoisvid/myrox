# myROX API 🚀

API Backend pour l'application myROX - Plateforme de fitness et d'entraînement HYROX.

## 🏗️ Architecture

- **API** : Fastify + Node.js
- **Base de données** : PostgreSQL (avec Prisma - à implémenter)
- **Authentification** : Firebase UID Trust (dev) / Firebase Admin SDK (prod)
- **Documentation** : Swagger UI automatique

## 📦 Installation

1. **Cloner et installer les dépendances**
```bash
cd myROX-api
npm install
```

2. **Configuration environnement**
```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer les variables si nécessaire
nano .env
```

3. **Démarrer le serveur**
```bash
# Mode développement avec auto-reload
npm run dev

# Mode production
npm start
```

## 🚀 Démarrage Rapide

```bash
npm run dev
```

L'API sera accessible sur :
- **Serveur** : http://localhost:3000
- **Documentation** : http://localhost:3000/docs
- **Health Check** : http://localhost:3000/api/v1/health

## 📍 Endpoints Principaux

### Health & Monitoring
- `GET /api/v1/health` - Vérification de l'état de l'API
- `GET /api/v1/ping` - Ping simple

### Gestion Utilisateurs
- `GET /api/v1/users/firebase/{uid}` - Profil utilisateur
- `POST /api/v1/users` - Créer un utilisateur
- `PUT /api/v1/users/firebase/{uid}` - Mettre à jour profil

### Informations Coach (Lecture seule)
- `GET /api/v1/coaches/{id}` - Informations publiques du coach

### Templates d'Entraînement
- `GET /api/v1/users/firebase/{uid}/personal-templates` - Templates créés par l'utilisateur
- `GET /api/v1/users/firebase/{uid}/assigned-templates` - Templates assignés par le coach

### Workouts & Statistiques
- `GET /api/v1/users/firebase/{uid}/workouts` - Historique des entraînements
- `GET /api/v1/users/firebase/{uid}/stats` - Statistiques personnelles

## 🔐 Authentification

L'API utilise Firebase UID pour l'authentification :

```bash
# Headers requis pour les routes protégées
curl -H "x-firebase-uid: YOUR_FIREBASE_UID" \
     -H "x-firebase-email: user@example.com" \
     http://localhost:3000/api/v1/users/firebase/YOUR_FIREBASE_UID
```

### Routes Publiques (sans auth)
- `/` - Page d'accueil
- `/api/v1/health` - Health check
- `/api/v1/ping` - Ping
- `/docs` - Documentation Swagger

## 🧪 Test de l'API

### 1. Health Check
```bash
curl http://localhost:3000/api/v1/health
```

### 2. Tester un profil utilisateur
```bash
curl -H "x-firebase-uid: test-user-123" \
     -H "x-firebase-email: test@myrox.app" \
     http://localhost:3000/api/v1/users/firebase/test-user-123
```

### 3. Créer un utilisateur
```bash
curl -X POST \
     -H "Content-Type: application/json" \
     -H "x-firebase-uid: new-user-456" \
     -H "x-firebase-email: newuser@myrox.app" \
     -d '{"firebaseUID":"new-user-456","email":"newuser@myrox.app","displayName":"Nouvel Athlète"}' \
     http://localhost:3000/api/v1/users
```

### 4. Infos d'un coach
```bash
curl -H "x-firebase-uid: any-user" \
     http://localhost:3000/api/v1/coaches/coach-123
```

## 📂 Structure du Projet

```
myROX-api/
├── server.js              # Point d'entrée principal
├── package.json           # Dépendances npm
├── .env.example          # Variables d'environnement exemple
├── README.md             # Cette documentation
└── src/
    ├── middleware/
    │   └── auth.js        # Middleware d'authentification Firebase
    └── routes/
        ├── health.js      # Routes de monitoring
        ├── users.js       # Gestion des utilisateurs
        └── coaches.js     # Informations des coachs
```

## 🔧 Configuration

### Variables d'Environnement

```bash
PORT=3000                   # Port du serveur
NODE_ENV=development        # Environnement (development/production)
DATABASE_URL="postgresql://user:password@localhost:5432/myrox_db"

# Firebase Admin SDK (pour production)
# FIREBASE_PROJECT_ID=your-project-id
# FIREBASE_PRIVATE_KEY="your-private-key"
# FIREBASE_CLIENT_EMAIL=your-client-email
```

### Mode Développement vs Production

**Développement** : L'API fait confiance aux Firebase UIDs envoyés dans les headers (approche "Trust UID").

**Production** : Utilisation du Firebase Admin SDK pour valider les tokens Firebase Auth.

## 🚧 TODO - Prochaines Étapes

1. **Base de Données**
   - [ ] Configurer Prisma ORM
   - [ ] Créer le schéma de base de données
   - [ ] Remplacer les mocks par de vraies requêtes

2. **Authentification Production**
   - [ ] Intégrer Firebase Admin SDK
   - [ ] Validation des tokens JWT Firebase

3. **Endpoints Complets**
   - [ ] CRUD complet pour templates
   - [ ] CRUD complet pour workouts
   - [ ] Gestion des relations coach/athlete

4. **Interface Web Coach**
   - [ ] Créer l'application web pour les coachs
   - [ ] Dashboard coach avec analytics
   - [ ] Gestion des athletes et assignation de templates

## 📖 Documentation

La documentation interactive Swagger est disponible sur `/docs` quand le serveur tourne.

## 🤝 Intégration iOS

Cette API est conçue pour fonctionner avec l'app iOS myROX :
- Les endpoints correspondent exactement à `APIEndpoints.swift`
- L'authentification via Firebase UID est compatible
- Séparation claire entre fonctionnalités athlete (iOS) et coach (Web)

## 📞 Support

Pour toute question sur l'API :
- Consulter la documentation Swagger : `/docs`
- Vérifier les logs du serveur en mode développement
- Tester les endpoints avec les exemples ci-dessus 