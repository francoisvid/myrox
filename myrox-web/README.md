# myROX Coach Dashboard

Dashboard web pour les coachs myROX, permettant de gérer les templates d'entraînement, assigner des workouts aux athlètes et analyser leurs performances.

## 🚀 Fonctionnalités

- **Gestion des Templates** : Créer, modifier et supprimer des templates d'entraînement
- **Assignation** : Assigner des templates à un ou plusieurs athlètes
- **Statistiques** : Visualiser les performances des athlètes avec des graphiques interactifs
- **Dashboard** : Vue d'ensemble des métriques importantes
- **Responsive Design** : Interface moderne et adaptative

## 🛠️ Technologies

- **Frontend** : Next.js 14, React, TypeScript
- **Styling** : Tailwind CSS
- **Icons** : Heroicons
- **Charts** : Recharts
- **HTTP Client** : Axios
- **Containerisation** : Docker & Docker Compose

## 📋 Prérequis

- Node.js 18+
- npm ou yarn
- Docker et Docker Compose (pour la containerisation)

## 🏃‍♂️ Installation et Démarrage

### Développement local

1. **Cloner le repository**
   ```bash
   git clone <repo-url>
   cd myrox-web
   ```

2. **Installer les dépendances**
   ```bash
   npm install
   ```

3. **Configurer les variables d'environnement**
   ```bash
   cp env.example .env.local
   ```
   Modifier `.env.local` avec vos configurations :
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:3001
   ```

4. **Démarrer le serveur de développement**
   ```bash
   npm run dev
   ```

   L'application sera accessible sur [http://localhost:3000](http://localhost:3000)

### Avec Docker Compose

#### Démarrage rapide (Application web uniquement)
```bash
# Utiliser le script de démarrage
./start.sh

# Ou manuellement
docker-compose up -d
```
L'application sera accessible sur [http://localhost:3002](http://localhost:3002)

#### Stack complète (Base de données + API + Web)
```bash
docker-compose -f docker-compose.full.yml up -d
```

Cela va démarrer :
- Base de données PostgreSQL (port 5433)
- API Backend (port 3001)
- Application Web (port 3002)

#### Arrêter les services
```bash
docker-compose down
```

## 📁 Structure du Projet

```
myrox-web/
├── src/
│   ├── app/                    # Pages Next.js (App Router)
│   │   ├── page.tsx           # Dashboard principal
│   │   ├── templates/         # Gestion des templates
│   │   │   ├── page.tsx      # Liste des templates
│   │   │   └── new/
│   │   │       └── page.tsx  # Création de template
│   │   └── stats/
│   │       └── page.tsx      # Page des statistiques
│   ├── lib/
│   │   └── api.ts            # Services API
│   └── types/
│       └── index.ts          # Types TypeScript
├── Dockerfile                # Configuration Docker
├── docker-compose.yml       # Orchestration des services
└── next.config.js           # Configuration Next.js
```

## 🎯 Pages Principales

### Dashboard (`/`)
- Vue d'ensemble des métriques clés
- Cartes d'actions rapides
- Navigation vers les autres sections

### Gestion des Templates (`/templates`)
- Liste de tous les templates créés
- Actions : créer, modifier, supprimer, assigner
- Modal d'assignation aux athlètes

### Création de Template (`/templates/new`)
- Formulaire complet de création
- Ajout d'exercices avec paramètres détaillés
- Réorganisation des exercices

### Statistiques (`/stats`)
- Graphiques de performance par athlète
- Tendances des workouts
- Répartition par catégories
- Tableau détaillé des métriques

## 🔌 API Integration

L'application communique avec l'API myROX via les endpoints suivants :

- `GET /coaches/{id}/templates` - Récupérer les templates
- `POST /templates` - Créer un template
- `PUT /templates/{id}` - Modifier un template
- `DELETE /templates/{id}` - Supprimer un template
- `POST /templates/{id}/assign` - Assigner un template
- `GET /coaches/{id}/athletes` - Récupérer les athlètes
- `GET /coaches/{id}/stats` - Récupérer les statistiques

## 🎨 Design System

L'application utilise une palette de couleurs cohérente :
- **Primaire** : Bleu (#3B82F6)
- **Succès** : Vert (#10B981)
- **Attention** : Jaune (#F59E0B)
- **Danger** : Rouge (#EF4444)
- **Neutre** : Gris (#6B7280)

## 🔧 Commandes Utiles

```bash
# Démarrage en développement
npm run dev

# Build de production
npm run build

# Démarrage en production
npm start

# Linter
npm run lint

# Build Docker
docker build -t myrox-web .

# Run avec Docker
docker run -p 3000:3000 myrox-web
```

## 🚀 Déploiement

### Avec Docker

1. **Build de l'image**
   ```bash
   docker build -t myrox-web .
   ```

2. **Run du container**
   ```bash
   docker run -d -p 3000:3000 --name myrox-web-container myrox-web
   ```

### Avec Docker Compose (Recommandé)

```bash
docker-compose up -d
```

## 🛡️ Sécurité

- Variables d'environnement pour la configuration
- CORS configuré pour l'API
- Images Docker optimisées avec utilisateur non-root

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## 📝 License

Ce projet est sous licence privée.

## 📞 Support

Pour toute question ou support, contactez l'équipe de développement myROX.
