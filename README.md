# 🏋️ myROX - Fitness & HYROX Tracker

Application complète de coaching fitness spécialisée HYROX avec interface web et API REST.

## 🏗️ Architecture du projet

```
myROX/
├── 📱 myROX/                    # App iOS/macOS (Swift)
├── 🌐 myrox-web/               # Interface web coach (Next.js)
├── 🔧 myROX-api/               # API REST (Fastify + Prisma)
├── 🐳 docker-compose.yml       # Orchestration Docker
└── 📚 Documentation/
```

## 🚀 Démarrage rapide

### Prérequis
- Docker & Docker Compose
- Node.js 18+ (si développement local)

### 1. Cloner et lancer
```bash
git clone <repo-url>
cd myROX

# Démarrer tous les services
docker-compose up -d

# Avec pgAdmin pour l'administration DB
docker-compose --profile admin up -d
```

### 2. Peupler la base de données
```bash
# Ajouter les 42 exercices (8 HYROX + 34 entraînement)
docker-compose exec api node src/scripts/add-exercises.js
```

### 3. Accéder aux services

| Service | URL | Description |
|---------|-----|-------------|
| 🌐 **Interface Web** | http://localhost:3002 | Dashboard coach |
| 🔧 **API** | http://localhost:3001 | Backend REST |
| 📖 **API Docs** | http://localhost:3001/docs | Documentation interactive |
| 🗄️ **pgAdmin** | http://localhost:8080 | Administration PostgreSQL |
| 📊 **PostgreSQL** | localhost:5432 | Base de données |

## 📱 Composants

### 🌐 Interface Web (myrox-web)
- **Framework** : Next.js 15 + React 19
- **Style** : Tailwind CSS
- **Features** : Dashboard coach, statistiques, analytics
- **Port** : 3002

### 🔧 API REST (myROX-api)
- **Framework** : Fastify + Prisma
- **Database** : PostgreSQL 15
- **Auth** : Firebase Authentication
- **Features** : 23 routes, CRUD complet, docs Swagger
- **Port** : 3001

### 📱 App Mobile (myROX)
- **Platform** : iOS/macOS native (SwiftUI)
- **Features** : Tracking workouts, templates, analytics
- **Status** : En cours de développement

## 🔧 Configuration Docker

### Services disponibles
```bash
# Développement complet
docker-compose up

# Avec administration DB
docker-compose --profile admin up

# Production
docker-compose -f docker-compose.prod.yml up
```

### Ports utilisés
| Service | Port | Type |
|---------|------|------|
| PostgreSQL | 5432 | Database |
| API | 3001 | Backend |
| Web | 3002 | Frontend |
| pgAdmin | 8080 | Admin UI |

## 📚 Documentation

### 📋 API (23 routes documentées)
- **[API_ROUTES.md](./myROX-api/API_ROUTES.md)** - Documentation complète
- **[README API](./myROX-api/README.md)** - Guide développeur
- **Swagger** : http://localhost:3001/docs

### 🐳 Docker
- **[DOCKER_SETUP.md](./DOCKER_SETUP.md)** - Configuration Docker
- **[PGADMIN_SETUP.md](./PGADMIN_SETUP.md)** - Guide pgAdmin

### 🌐 Interface Web
- **[README Web](./myrox-web/README.md)** - Documentation frontend

## 💪 Exercices disponibles

**42 exercices** organisés en catégories :

### 🏆 HYROX (8 stations officielles)
- SkiErg, Sled Push, Sled Pull, Burpees Broad Jump
- RowErg, Farmers Carry, Sandbag Lunges, Wall Balls

### 🏃‍♀️ Autres catégories (34 exercices)
- **CARDIO** : Run, Assault Bike, Jump Rope, Sprint Intervals...
- **STRENGTH** : Deadlifts, Thrusters, Snatches, Cleans...
- **FUNCTIONAL** : Squats, Burpees, Box Jumps, Planks...

## 🗄️ Base de données

### Modèles principaux
- **User** : Athletes/utilisateurs
- **Coach** : Coachs/entraîneurs
- **Exercise** : Catalogue d'exercices (42)
- **Template** : Templates d'entraînement
- **Workout** : Séances réalisées
- **PersonalBest** : Records personnels

### Administration
- **pgAdmin** : http://localhost:8080
  - Email : `admin@myrox.dev`
  - Mot de passe : `admin123`

## 🔐 Authentification

- **Firebase Authentication** pour l'authentification
- **Header** : `x-firebase-uid` pour les requêtes API
- **Permissions** : Contrôle d'accès par utilisateur/coach

## 🛠️ Développement

### Hot reload activé
- ✅ **API** : Nodemon + volumes Docker
- ✅ **Web** : Next.js dev server + volumes Docker
- ✅ **DB** : PostgreSQL avec persistance

### Scripts utiles
```bash
# Logs en temps réel
docker-compose logs -f

# Rebuilder les images
docker-compose build

# Reset complet
docker-compose down -v
docker-compose up --build
```

## 📊 Monitoring

### Health checks
- **API** : http://localhost:3001/api/v1/health
- **Ping** : http://localhost:3001/api/v1/ping
- **Web** : http://localhost:3002

### Logs
```bash
docker-compose logs api     # API logs
docker-compose logs web     # Web logs  
docker-compose logs postgres # DB logs
docker-compose logs pgadmin  # pgAdmin logs
```

## 🚀 Prochaines étapes

1. **📱 App iOS** : Finaliser l'application mobile native
2. **🔐 Auth** : Intégrer Firebase Auth complet
3. **📊 Analytics** : Étendre les statistiques coach
4. **🎨 UI/UX** : Améliorer l'interface web
5. **🔄 Sync** : Synchronisation temps réel
6. **🚀 Deploy** : Configuration production

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 License

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

---

**🏋️ Développé avec ❤️ pour la communauté HYROX**
