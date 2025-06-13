# Configuration Docker - myROX

## Structure unifiée

La configuration Docker a été simplifiée et unifiée :

### Fichiers principaux :
- `docker-compose.yml` : Configuration pour le développement
- `docker-compose.prod.yml` : Configuration pour la production

### Services disponibles :
- **postgres** : Base de données PostgreSQL 15
- **api** : API Backend (Fastify)
- **web** : Frontend Web (Next.js)
- **pgadmin** : Interface d'administration PostgreSQL (optionnel)

## Utilisation

### Développement
```bash
# Démarrer tous les services
docker-compose up -d

# Démarrer avec les logs
docker-compose up

# Démarrer avec pgAdmin
docker-compose --profile admin up -d
```

### Production
```bash
# Démarrer en production
docker-compose -f docker-compose.prod.yml up -d

# Construire et démarrer
docker-compose -f docker-compose.prod.yml up -d --build
```

### Commandes utiles
```bash
# Arrêter tous les services
docker-compose down

# Supprimer les volumes (⚠️ supprime les données)
docker-compose down -v

# Voir les logs
docker-compose logs -f [service_name]

# Reconstruire un service
docker-compose build [service_name]
```

## Ports utilisés

### Développement
- **3000** : Application Web (Next.js)
- **3001** : API Backend (exposé depuis le port 3000 du container)
- **5432** : PostgreSQL
- **8080** : pgAdmin (avec --profile admin)

### Production
- **3000** : Application Web
- **3001** : API Backend
- **5432** : PostgreSQL

## Configuration

### Variables d'environnement
- **POSTGRES_DB** : `myrox_db`
- **POSTGRES_USER** : `myrox_user`
- **POSTGRES_PASSWORD** : `myrox_password`

### Volumes
- `postgres_data` : Données PostgreSQL (développement)
- `postgres_data_prod` : Données PostgreSQL (production)

## Résolution de problèmes

### Port déjà utilisé
```bash
# Vérifier les ports utilisés
lsof -i :3000
lsof -i :3001
lsof -i :5432

# Tuer un processus
kill -9 <PID>
```

### Problèmes de build
```bash
# Nettoyer et reconstruire
docker-compose down
docker system prune -f
docker-compose build --no-cache
docker-compose up -d
```

### Problèmes de base de données
```bash
# Réinitialiser la base de données
docker-compose down -v
docker-compose up -d postgres
# Attendre que postgres soit prêt
docker-compose up -d
```

## Accès aux services

- **Application Web** : http://localhost:3000
- **API Backend** : http://localhost:3001
- **pgAdmin** : http://localhost:8080 (admin@myrox.dev / admin123)

## Architecture réseau

Tous les services utilisent le réseau `myrox-network` pour communiquer entre eux.
Les services peuvent se référencer par leur nom de service (ex: `postgres`, `api`, `web`). 