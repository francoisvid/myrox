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

### Health Check
```http
GET /api/v1/health
```

### Utilisateurs
```http
GET /api/v1/users/firebase/{firebaseUID}
POST /api/v1/users
```

### Templates
```http
GET /api/v1/users/firebase/{firebaseUID}/personal-templates
GET /api/v1/users/firebase/{firebaseUID}/assigned-templates
```

### Documentation complète
- **Swagger UI**: http://localhost:3000/docs
- **JSON Schema**: http://localhost:3000/docs/json

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