# Configuration Docker myROX

## Vue d'ensemble

La configuration Docker a été réorganisée pour être plus cohérente et pratique. Tous les fichiers docker-compose sont maintenant à la racine du projet pour une orchestration centralisée.

## Structure des fichiers

```
myROX/
├── docker-compose.yml          # Configuration par défaut (développement)
├── docker-compose.dev.yml      # Configuration développement explicite
├── docker-compose.prod.yml     # Configuration production
├── myROX-api/
│   ├── Dockerfile             # Production API
│   └── Dockerfile.dev         # Développement API
└── myrox-web/
    ├── Dockerfile             # Production Web
    └── Dockerfile.dev         # Développement Web (avec hot reload)
```

## Ports utilisés

| Service    | Port de développement | Port de production | Description |
|------------|----------------------|-------------------|-------------|
| PostgreSQL | 5432                 | 5432              | Base de données |
| API        | 3001                 | 3001              | Backend Fastify |
| Web        | 3002                 | 3002              | Frontend Next.js |
| **pgAdmin** | **8080**            | -                 | **Interface d'admin DB** |

## Utilisation

### Développement (avec hot reload)

```bash
# Démarrer tous les services en mode développement
docker-compose up

# Ou explicitement avec le fichier dev
docker-compose -f docker-compose.dev.yml up

# Démarrer avec pgAdmin pour l'administration de la DB
docker-compose --profile admin up

# Ou ajouter pgAdmin à un setup existant
docker-compose --profile admin up pgadmin -d
```

### Production

```bash
# Démarrer en mode production
docker-compose -f docker-compose.prod.yml up
```

### Services individuels

```bash
# Démarrer seulement la base de données
docker-compose up postgres

# Démarrer API + DB
docker-compose up postgres api

# Démarrer tout sauf pgAdmin
docker-compose up postgres api web
```

## Fonctionnalités

### Hot Reload

- **API** : Utilise des volumes montés avec `Dockerfile.dev` et `nodemon`
- **Web** : Utilise des volumes montés avec `Dockerfile.dev` et Next.js dev server

### Healthchecks

Tous les services ont des healthchecks configurés :
- PostgreSQL : Vérifie la connexion à la DB
- API : Vérifie l'endpoint `/api/v1/health`
- Web : Vérifie l'accès à la page d'accueil

### Réseau

Tous les services utilisent le réseau `myrox-network` pour communiquer entre eux.

## Variables d'environnement

### API
- `PORT=3000` (interne au container)
- `NODE_ENV=development|production`
- `DATABASE_URL=postgresql://myrox_user:myrox_password@postgres:5432/myrox_db`

### Web
- `NODE_ENV=development|production`
- `NEXT_PUBLIC_API_URL=http://localhost:3001` (accessible depuis le navigateur)

### PostgreSQL
- `POSTGRES_DB=myrox_db`
- `POSTGRES_USER=myrox_user`
- `POSTGRES_PASSWORD=myrox_password`

### pgAdmin
- **URL** : http://localhost:8080
- **Email** : admin@myrox.dev
- **Mot de passe** : admin123
- **Guide complet** : [PGADMIN_SETUP.md](./PGADMIN_SETUP.md)

## Commandes utiles

```bash
# Voir les logs d'un service spécifique
docker-compose logs -f web

# Reconstruire les images
docker-compose build

# Arrêter et supprimer tous les containers
docker-compose down

# Arrêter et supprimer + volumes
docker-compose down -v

# Entrer dans un container
docker-compose exec web sh
docker-compose exec api sh
```

## Changements apportés

1. **Centralisation** : Docker-compose déplacé à la racine
2. **Ports cohérents** : API accessible sur 3001, Web sur 3002
3. **Hot reload** : Nouveau `Dockerfile.dev` pour le web avec volumes montés
4. **Séparation dev/prod** : Configurations distinctes pour chaque environnement
5. **Réseaux** : Communication inter-services simplifiée 