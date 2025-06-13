# myROX API 🚀

API REST pour l'application myROX - Fitness & HYROX tracker.

## 🛠️ Stack Technique

- **Runtime**: Node.js 18
- **Framework**: Fastify
- **Base de données**: PostgreSQL 15
- **ORM**: Prisma
- **Authentification**: Firebase Auth
- **Conteneurisation**: Docker & Docker Compose

## 🚀 Démarrage Rapide avec Docker

### Prérequis
- Docker & Docker Compose installés
- Git

### 1. Cloner et installer
```bash
git clone <repo-url>
cd myROX-api
npm install
```

### 2. Configuration
```bash
# Copier le fichier d'environnement
cp .env.example .env

# Éditer les variables si nécessaire
nano .env
```

### 3. Lancer avec Docker
```bash
# Construire et démarrer tous les services
npm run docker:dev

# Ou avec docker-compose directement
docker-compose up --build
```

### 4. Initialiser la base de données
```bash
# Génerer le client Prisma
npm run db:generate

# Appliquer le schéma
npm run db:push

# Seed avec des données de test
npm run db:seed
```

## 🐳 Services Docker

Le `docker-compose.yml` lance 3 services :

### 📊 PostgreSQL (`postgres`)
- **Port**: 5432
- **Database**: `myrox_db`
- **User**: `myrox_user`
- **Password**: `myrox_password`

### 🚀 API myROX (`api`) 
- **Port**: 3000
- **URL**: http://localhost:3000
- **Hot Reload**: Activé avec volumes

### 🔧 pgAdmin (`pgadmin`) - Optionnel
- **Port**: 8080
- **URL**: http://localhost:8080
- **Email**: admin@myrox.local
- **Password**: admin123

```bash
# Démarrer avec pgAdmin
docker-compose --profile admin up
```

## 📜 Scripts NPM

### Docker
```bash
npm run docker:build    # Construire les images
npm run docker:up       # Démarrer en arrière-plan
npm run docker:down     # Arrêter tous les services  
npm run docker:dev      # Développement (logs visibles)
npm run docker:logs     # Voir les logs de l'API
```

### Base de données
```bash
npm run db:generate     # Générer le client Prisma
npm run db:push         # Appliquer le schéma
npm run db:migrate      # Créer une migration
npm run db:seed         # Insérer des données de test
npm run db:studio       # Interface Prisma Studio
```

### Développement
```bash
npm run dev            # Démarrer en mode développement
npm start              # Démarrer en production
npm test               # Lancer les tests
```

## 🔌 Endpoints API

L'API expose **23 routes** organisées en 5 modules principaux :

### 📊 Résumé des Routes

| Module | Routes | Description |
|--------|---------|-------------|
| **Health** | 2 | Monitoring et health checks |
| **Users** | 8 | Gestion des profils utilisateurs et templates |
| **Workouts** | 8 | CRUD workouts et records personnels |
| **Exercises** | 2 | Catalogue des exercices (42 disponibles) |
| **Coaches** | 5 | Profils et statistiques des coachs |

### 🏥 Health & Monitoring
```http
GET /                    # Infos générales API
GET /api/v1/health      # Health check complet  
GET /api/v1/ping        # Ping simple
```

### 👤 Users
```http
GET    /api/v1/users/firebase/{firebaseUID}                             # Profil utilisateur
POST   /api/v1/users                                                    # Créer utilisateur
PUT    /api/v1/users/firebase/{firebaseUID}                             # Modifier profil
GET    /api/v1/users/firebase/{firebaseUID}/personal-templates          # Templates personnels
GET    /api/v1/users/firebase/{firebaseUID}/assigned-templates          # Templates assignés
POST   /api/v1/users/firebase/{firebaseUID}/personal-templates          # Créer template
PUT    /api/v1/users/firebase/{firebaseUID}/personal-templates/{id}     # Modifier template
DELETE /api/v1/users/firebase/{firebaseUID}/personal-templates/{id}     # Supprimer template
```

### 🏃‍♀️ Workouts & Records
```http
GET    /api/v1/users/firebase/{firebaseUID}/workouts                    # Liste workouts
POST   /api/v1/users/firebase/{firebaseUID}/workouts                    # Créer workout
PUT    /api/v1/users/firebase/{firebaseUID}/workouts/{id}               # Modifier workout
DELETE /api/v1/users/firebase/{firebaseUID}/workouts/{id}               # Supprimer workout
GET    /api/v1/users/firebase/{firebaseUID}/personal-bests              # Records personnels
POST   /api/v1/users/firebase/{firebaseUID}/personal-bests              # Créer record
PUT    /api/v1/users/firebase/{firebaseUID}/personal-bests/{id}         # Modifier record
DELETE /api/v1/users/firebase/{firebaseUID}/personal-bests/{id}         # Supprimer record
```

### 💪 Exercises (42 exercices disponibles)
```http
GET /api/v1/exercises     # Liste complète des exercices
GET /api/v1/exercises/{id} # Exercice spécifique
```

**Catégories disponibles :**
- **HYROX_STATION** (8 exercices) : SkiErg, Sled Push/Pull, Burpees Broad Jump, RowErg, Farmers Carry, Sandbag Lunges, Wall Balls
- **CARDIO** (8 exercices) : Run, Assault Bike, Jump Rope, Sprint Intervals, etc.
- **STRENGTH** (12 exercices) : Deadlifts, Thrusters, Snatches, etc.
- **FUNCTIONAL** (14 exercices) : Squats, Burpees, Box Jumps, etc.

### 👨‍🏫 Coaches
```http
GET /api/v1/coaches/{id}                      # Profil public coach
GET /api/v1/coaches/{id}/athletes             # Athletes du coach (Web only)
GET /api/v1/coaches/{id}/stats/detailed       # Statistiques détaillées
GET /api/v1/coaches/{id}/templates            # Templates créés
GET /api/v1/coaches/{id}/statistics           # Stats générales
```

### 📚 Documentation Interactive
- **🔗 API Documentation complète** : [API_ROUTES.md](./API_ROUTES.md)
- **🖥️ Swagger UI** : http://localhost:3001/docs
- **📄 JSON Schema** : http://localhost:3001/docs/json

## 🗄️ Structure de la Base

### Modèles Principaux
- **User**: Utilisateurs (athletes)
- **Coach**: Coachs/Entraîneurs
- **Template**: Templates d'entraînement
- **Exercise**: Exercices individuels
- **Workout**: Séances d'entraînement réalisées
- **PersonalBest**: Records personnels

### Relations
- Un Coach peut avoir plusieurs Athletes
- Un User peut avoir des Templates personnels et assignés
- Les Templates contiennent des Exercises
- Les Workouts trackent les performances

## 🛠️ Développement Local (sans Docker)

```bash
# Installer les dépendances
npm install

# Démarrer PostgreSQL localement
# Modifier DATABASE_URL dans .env

# Générer le client Prisma
npm run db:generate

# Appliquer le schéma
npm run db:push

# Seed
npm run db:seed

# Démarrer l'API
npm run dev
```

## 🔐 Authentification

L'API utilise Firebase Auth avec le modèle "Trust UID" :
- Les requêtes incluent le header `X-Firebase-UID`
- L'API fait confiance à cet UID en développement
- En production, utiliser le Firebase Admin SDK

## 📝 Logs et Debug

```bash
# Voir les logs en temps réel
npm run docker:logs

# Logs spécifiques
docker-compose logs postgres
docker-compose logs pgadmin

# Exec dans un container
docker exec -it myrox-api sh
docker exec -it myrox-postgres psql -U myrox_user -d myrox_db
```

## 🚀 Déploiement

### Production
```bash
# Build pour production
docker build -f Dockerfile -t myrox-api:latest .

# Avec docker-compose
NODE_ENV=production docker-compose -f docker-compose.prod.yml up -d
```

### Variables d'environnement Production
- `DATABASE_URL`: URL PostgreSQL de production
- `FIREBASE_PROJECT_ID`: ID du projet Firebase
- `NODE_ENV=production`

## 🤝 Intégration iOS

L'app iOS communique avec cette API via :
- **APIService.swift**: Client HTTP
- **Headers**: `X-Firebase-UID` pour l'auth
- **Cache local**: SwiftData pour le mode offline

---

**Happy coding! 🏃‍♂️💪** 