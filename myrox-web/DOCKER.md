# Guide Docker - myROX Coach Dashboard

## 🚀 Démarrage Rapide

### Application Web Uniquement
```bash
# Démarrage automatique avec script
./start.sh

# Ou manuellement
docker-compose up -d
```
**URL**: http://localhost:3002

### Stack Complète (DB + API + Web)
```bash
docker-compose -f docker-compose.full.yml up -d
```

## 📋 Commandes Utiles

### Gestion des Containers
```bash
# Voir l'état des containers
docker-compose ps

# Voir les logs
docker-compose logs -f web
docker-compose logs -f api
docker-compose logs -f postgres

# Redémarrer un service
docker-compose restart web

# Arrêter tous les services
docker-compose down

# Arrêter et supprimer les volumes
docker-compose down -v
```

### Build et Développement
```bash
# Rebuild les images
docker-compose build

# Rebuild et démarrer
docker-compose up --build

# Rebuild une image spécifique
docker-compose build web

# Mode développement avec logs
docker-compose up
```

### Debugging
```bash
# Accéder au container en cours d'exécution
docker exec -it myrox-web sh
docker exec -it myrox-api sh
docker exec -it myrox-postgres psql -U myrox_user -d myrox

# Voir les ressources utilisées
docker stats

# Inspecter un container
docker inspect myrox-web
```

### Nettoyage
```bash
# Supprimer les containers arrêtés
docker container prune

# Supprimer les images non utilisées
docker image prune

# Supprimer les volumes non utilisés
docker volume prune

# Nettoyage complet
docker system prune -a
```

## 🔧 Configuration

### Variables d'Environnement
- `NEXT_PUBLIC_API_URL`: URL de l'API backend
- `NODE_ENV`: Environnement (development/production)
- `DATABASE_URL`: URL de connexion PostgreSQL

### Ports Utilisés
- **3002**: Application Web (Next.js)
- **3001**: API Backend (Node.js)
- **5433**: Base de données PostgreSQL

### Volumes
- `postgres_data`: Données persistantes PostgreSQL

## 🐛 Résolution de Problèmes

### Port déjà utilisé
```bash
# Trouver le processus utilisant le port
lsof -ti:3002

# Tuer le processus
kill -9 <PID>

# Ou changer le port dans docker-compose.yml
```

### Container ne démarre pas
```bash
# Voir les logs détaillés
docker-compose logs web

# Vérifier l'état
docker-compose ps

# Rebuild l'image
docker-compose build web
```

### Problèmes de réseau
```bash
# Recréer le réseau
docker-compose down
docker network prune
docker-compose up -d
```

### Base de données
```bash
# Réinitialiser la base de données
docker-compose down -v
docker-compose -f docker-compose.full.yml up -d postgres

# Accéder à PostgreSQL
docker exec -it myrox-postgres psql -U myrox_user -d myrox
```

## 📊 Monitoring

### Santé des Services
```bash
# Vérifier la santé de l'application
curl -I http://localhost:3002

# Vérifier l'API (si disponible)
curl -I http://localhost:3001/health

# Vérifier PostgreSQL
docker exec myrox-postgres pg_isready -U myrox_user
```

### Logs en Temps Réel
```bash
# Tous les services
docker-compose logs -f

# Service spécifique
docker-compose logs -f web

# Dernières lignes
docker-compose logs --tail=50 web
```

## 🚀 Déploiement

### Production
```bash
# Build optimisé
docker-compose -f docker-compose.full.yml build

# Démarrage en production
docker-compose -f docker-compose.full.yml up -d

# Vérification
docker-compose -f docker-compose.full.yml ps
```

### Sauvegarde
```bash
# Sauvegarde de la base de données
docker exec myrox-postgres pg_dump -U myrox_user myrox > backup.sql

# Restauration
docker exec -i myrox-postgres psql -U myrox_user -d myrox < backup.sql
``` 