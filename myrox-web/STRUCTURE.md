# 📁 Structure du Projet myROX Web

## 🏗️ Architecture Next.js 15 (App Router)

```
src/
├── app/                          # App Router (Next.js 13+)
│   ├── layout.tsx               # Layout racine
│   ├── page.tsx                 # Page d'accueil
│   ├── globals.css              # Styles globaux
│   │
│   ├── api/                     # API Routes (Next.js)
│   │   └── auth/
│   │       ├── register/
│   │       │   └── route.ts     # POST /api/auth/register
│   │       └── user-type/
│   │           └── [firebaseUID]/
│   │               └── route.ts # GET /api/auth/user-type/[id]
│   │
│   ├── coach/                   # Pages coach
│   │   ├── athletes/
│   │   ├── invitations/
│   │   └── subscription/
│   │
│   ├── templates/               # Pages templates
│   │   ├── new/
│   │   └── [id]/
│   │
│   ├── login/                   # Page de connexion
│   ├── register/                # Page d'inscription
│   └── stats/                   # Page de statistiques
│
├── components/                   # Composants réutilisables
│   ├── index.ts                 # Exports centralisés
│   │
│   ├── layout/                  # Composants de mise en page
│   │   ├── Navigation.tsx       # Navigation principale
│   │   └── PageLayout.tsx       # Layout de page
│   │
│   ├── coach/                   # Composants spécifiques coach
│   │   ├── TemplateAssignmentManager.tsx
│   │   ├── TemplateAssignmentModal.tsx
│   │   ├── InvitationGenerator.tsx
│   │   ├── InvitationsList.tsx
│   │   ├── SubscriptionStatus.tsx
│   │   └── SubscriptionPlans.tsx
│   │
│   ├── templates/               # Composants templates
│   │   ├── ExerciseConfiguration.tsx
│   │   ├── ExerciseSelector.tsx
│   │   └── ConfiguredExerciseCard.tsx
│   │
│   └── ui/                      # Composants UI génériques (futur)
│
├── hooks/                       # Hooks React personnalisés
│   ├── useAuth.ts              # Authentification
│   ├── useAthletes.ts          # Gestion des athlètes
│   ├── useTemplates.ts         # Gestion des templates
│   ├── useExercises.ts         # Gestion des exercices
│   └── useCoachId.ts           # ID du coach connecté
│
├── lib/                        # Utilitaires et configuration
│   ├── api.ts                  # Client API
│   ├── config.ts               # Configuration
│   └── firebase.ts             # Configuration Firebase
│
└── types/                      # Types TypeScript
    └── index.ts                # Définitions de types
```

## 🚀 Optimisations Implémentées

### Navigation Instantanée
- ✅ Prefetching automatique des routes
- ✅ Skeleton loading pendant l'authentification
- ✅ Transitions fluides avec `useTransition`
- ✅ Chargement progressif des données

### Structure des Composants
- ✅ Organisation par domaine fonctionnel
- ✅ Exports centralisés via `index.ts`
- ✅ Séparation layout/business/UI

### API Routes (Next.js)
- ✅ Structure standard App Router
- ✅ Routes dynamiques avec `[param]`
- ✅ Fichiers `route.ts` pour chaque endpoint

## 📝 Conventions

### Imports
```typescript
// Préférer les imports depuis l'index
import { Navigation, PageLayout } from '@/components';

// Ou imports directs si nécessaire
import Navigation from '@/components/layout/Navigation';
```

### Composants
- **PascalCase** pour les noms de fichiers
- **Exports par défaut** pour les composants principaux
- **Props interfaces** définies dans le même fichier

### API Routes
- **Fichiers `route.ts`** pour chaque endpoint
- **Dossiers** pour organiser les routes
- **Paramètres dynamiques** avec `[param]` 