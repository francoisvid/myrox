# 🌐 Network - Documentation

Ce dossier contient tous les éléments nécessaires pour communiquer avec l'API myROX.

## 📁 Structure

```
Network/
├── APIService.swift          # 🔧 Service principal pour les appels API
├── APIEndpoints.swift        # 🗺️  Définition des routes et endpoints
├── Models/                   # 📦 Modèles de données API
│   ├── APITypes.swift        # 🔨 Types communs (erreurs, HTTP, utilitaires)
│   ├── APIRequests.swift     # 📤 Modèles pour les requêtes vers l'API
│   ├── APIExercise.swift     # 🏋️‍♀️ Modèles exercices (réponses API)
│   ├── APITemplate.swift     # 📋 Modèles templates (réponses API) 
│   └── APIUser.swift         # 👤 Modèles utilisateurs (réponses API)
└── README.md                 # 📖 Cette documentation
```

## 🔧 APIService.swift

**Service principal** pour toutes les communications avec l'API.

- ✅ **Configuration automatique** local/production
- ✅ **Authentification Firebase** automatique
- ✅ **Gestion d'erreurs** centralisée
- ✅ **Logging debug** en développement
- ✅ **Méthodes génériques** pour tous types de requêtes

### Utilisation basique :
```swift
// GET simple
let exercises = try await APIService.shared.fetchExercises()

// POST avec body
let template = try await APIService.shared.createPersonalTemplate(
    firebaseUID: "...", 
    CreateTemplateRequest(...)
)
```

## 🗺️ APIEndpoints.swift

**Définition centralisée** de tous les endpoints API.

### Types d'endpoints :
- 🏥 **Health** : Vérification santé API
- 👤 **Users** : Gestion profils utilisateurs  
- 📋 **Templates** : Templates personnels/assignés
- 🏋️‍♀️ **Workouts** : Séances d'entraînement
- 📊 **Stats** : Statistiques personnelles
- 💪 **Exercises** : Catalogue d'exercices

### Utilisation :
```swift
// Endpoint simple
let endpoint = APIEndpoints.exercises

// Endpoint avec paramètre
let endpoint = APIEndpoints.userProfile(firebaseUID: "...")

// Helper pour utilisateur connecté
let userEndpoints = APIEndpoints.forCurrentUser()
let templates = try await APIService.shared.get(
    userEndpoints?.personalTemplates, 
    responseType: [APITemplate].self
)
```

## 📦 Models/

### 🔨 APITypes.swift
Types fondamentaux pour l'API :
- `HTTPMethod` : GET, POST, PUT, DELETE
- `APIError` : Toutes les erreurs possibles
- `HealthResponse` : Réponse health check
- `PaginatedResponse<T>` : Réponses paginées
- Utilitaires pour dates ISO8601

### 📤 APIRequests.swift
Modèles pour **envoyer des données** à l'API :
- `CreateTemplateRequest` : Créer un template
- `CreateUserRequest` : Créer un utilisateur
- `UpdateUserRequest` : Modifier un utilisateur
- `CreateWorkoutRequest` : Créer une séance

### 📥 Modèles de réponses
Modèles pour **recevoir des données** de l'API :

#### 🏋️‍♀️ APIExercise.swift
- `APIExercise` : Exercice depuis l'API
- `ExerciseListResponse` : Liste d'exercices
- Extensions pour affichage iOS (icônes, badges, etc.)

#### 📋 APITemplate.swift  
- `APITemplate` : Template depuis l'API
- `APITemplateExercise` : Exercice dans un template
- `TemplateListResponse` : Liste de templates
- Extensions pour formatage (temps, difficulté, etc.)

#### 👤 APIUser.swift
- `APIUser` : Utilisateur depuis l'API
- `APICoach` : Coach (lecture seule)
- `UserListResponse` : Liste d'utilisateurs
- Extensions pour affichage (statut, ancienneté, etc.)

## 🔄 Flux de données

```
iOS App ←→ APIService ←→ APIEndpoints ←→ Fastify API ←→ PostgreSQL
         ↕️                                    
    Models (Request/Response)                  
```

## 🛠️ Configuration

### Environnements automatiques :
- **Debug** : `http://localhost:3000/api/v1`
- **Release** : `https://myrox.api.vdl-creation.fr/api/v1`

### Authentification :
- Header `x-firebase-uid` : UID Firebase automatique
- Header `x-firebase-email` : Email pour debug

## 🚨 Gestion d'erreurs

Toutes les erreurs sont centralisées dans `APIError` :

```swift
do {
    let data = try await APIService.shared.fetchExercises()
} catch let error as APIError {
    switch error {
    case .unauthorized:
        // Rediriger vers login
    case .networkError(let underlyingError):
        // Problème réseau
    case .decodingError(let underlyingError):
        // Problème de parsing JSON
    default:
        // Autres erreurs
    }
}
```

## 🔧 Extension facile

Pour ajouter un nouvel endpoint :

1. **Ajouter dans `APIEndpoints.swift`** :
```swift
case newFeature(id: String)

// Dans path:
case .newFeature(let id):
    return "/new-feature/\(id)"
```

2. **Créer les modèles** dans `Models/` :
```swift
struct NewFeatureRequest: Codable { ... }
struct NewFeatureResponse: Codable { ... }
```

3. **Ajouter la méthode dans `APIService.swift`** :
```swift
func fetchNewFeature(id: String) async throws -> NewFeatureResponse {
    return try await get(.newFeature(id: id), responseType: NewFeatureResponse.self)
}
```

---

**🎯 Organisation claire, maintenable et extensible !** 