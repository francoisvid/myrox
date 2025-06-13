# 🗄️ Guide pgAdmin - myROX

## Accès pgAdmin

pgAdmin est l'interface web d'administration PostgreSQL pour explorer et gérer la base de données myROX.

**🔗 URL** : http://localhost:8080  
**📧 Email** : admin@myrox.dev  
**🔑 Mot de passe** : admin123

## 🚀 Démarrage pgAdmin

### Option 1 : Démarrer avec tous les services + pgAdmin
```bash
# Démarrer tout avec pgAdmin
docker-compose --profile admin up

# Ou en arrière-plan
docker-compose --profile admin up -d
```

### Option 2 : Ajouter pgAdmin à un setup existant
```bash
# Si les autres services tournent déjà
docker-compose --profile admin up pgadmin -d
```

### Option 3 : Arrêter pgAdmin
```bash
# Arrêter seulement pgAdmin
docker-compose stop pgadmin

# Arrêter et supprimer
docker-compose rm -f pgadmin
```

## 🔧 Configuration de la connexion DB

### 1. Accéder à pgAdmin
1. Aller sur http://localhost:8080
2. Se connecter avec :
   - **Email** : `admin@myrox.dev`
   - **Mot de passe** : `admin123`

### 2. Ajouter le serveur PostgreSQL

1. **Clic droit** sur "Servers" → "Register" → "Server..."

2. **Onglet General** :
   - **Name** : `myROX Database`

3. **Onglet Connection** :
   - **Host name/address** : `postgres` (nom du service Docker)
   - **Port** : `5432`
   - **Maintenance database** : `myrox_db`
   - **Username** : `myrox_user`
   - **Password** : `myrox_password`
   - ✅ **Save password** : Coché

4. **Cliquer sur "Save"**

### 3. Explorer la base de données

Une fois connecté, vous verrez :
```
myROX Database
├── Databases
│   └── myrox_db
│       ├── Schemas
│       │   └── public
│       │       ├── Tables
│       │       │   ├── User
│       │       │   ├── Coach  
│       │       │   ├── Exercise (42 entrées)
│       │       │   ├── Template
│       │       │   ├── Workout
│       │       │   └── PersonalBest
│       │       └── Functions
```

## 📊 Requêtes utiles

### Voir tous les exercices
```sql
SELECT name, category, "isHyroxExercise" 
FROM "Exercise" 
ORDER BY category, name;
```

### Compter par catégorie
```sql
SELECT category, COUNT(*) as count
FROM "Exercise" 
GROUP BY category 
ORDER BY count DESC;
```

### Exercices HYROX officiels
```sql
SELECT name, description, equipment
FROM "Exercise" 
WHERE "isHyroxExercise" = true
ORDER BY name;
```

### Voir la structure des tables
```sql
-- Tables existantes
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Colonnes d'une table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'Exercise' 
  AND table_schema = 'public';
```

## 🔍 Fonctionnalités pgAdmin utiles

### **Query Tool** 
- Exécuter des requêtes SQL personnalisées
- Voir les plans d'exécution
- Exporter les résultats

### **Table Viewer**
- Voir/modifier les données directement
- Filtrer et trier
- Ajouter/supprimer des enregistrements

### **Monitoring**
- Statistiques des performances
- Sessions actives
- Logs PostgreSQL

### **Backup/Restore**
- Sauvegarder la base de données
- Restaurer des sauvegardes
- Import/Export de données

## 🚨 Sécurité

### Développement vs Production

**En développement** (actuellement) :
- Credentials simples pour faciliter le debug
- pgAdmin accessible publiquement sur le port 8080

**En production** :
- ⚠️ **NE PAS** utiliser ces credentials
- Utiliser un mot de passe fort
- Restreindre l'accès réseau
- Utiliser HTTPS
- Configuration avec variables d'environnement

### Variables d'environnement sécurisées

Pour la production, utiliser :
```yaml
pgadmin:
  environment:
    PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL}
    PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD}
    PGADMIN_CONFIG_SERVER_MODE: 'True'
```

## 🛠️ Troubleshooting

### pgAdmin ne démarre pas
```bash
# Vérifier les logs
docker-compose logs pgadmin

# Redémarrer le service
docker-compose restart pgadmin
```

### Cannot connect to server
- Vérifier que PostgreSQL est bien démarré : `docker-compose logs postgres`
- Utiliser le nom du service Docker : `postgres` (pas `localhost`)
- Vérifier les credentials : `myrox_user` / `myrox_password`

### Port 8080 déjà utilisé
```bash
# Changer le port dans docker-compose.yml
ports:
  - "8081:80"  # Utiliser 8081 au lieu de 8080
```

## 📝 Scripts d'administration

### Export de données
```bash
# Export de tous les exercices
docker exec myrox-postgres pg_dump -U myrox_user -d myrox_db -t Exercise --data-only > exercises_backup.sql
```

### Import de données
```bash
# Import d'un backup
docker exec -i myrox-postgres psql -U myrox_user -d myrox_db < exercises_backup.sql
```

### Reset de la base
```bash
# ATTENTION : Supprime toutes les données !
docker-compose exec api npx prisma db push --force-reset
docker-compose exec api node src/scripts/add-exercises.js
``` 