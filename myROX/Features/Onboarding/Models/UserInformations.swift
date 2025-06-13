import Foundation

// MARK: - UserInformations Model
struct UserInformations: Codable, Identifiable {
    let id: String
    let userId: String
    var hasCompletedOnboarding: Bool
    
    // Étape 1: Profil HYROX
    var hyroxExperience: HyroxExperience?
    var hasCompetedHyrox: Bool?
    var primaryGoal: HyroxGoal?
    
    // Étape 2: Condition physique
    var currentTrainingFrequency: TrainingFrequency?
    var trainingTypes: [String]
    var fitnessLevel: Int? // 1-10
    var injuriesLimitations: String?
    
    // Étape 3: Équipements & Salle
    var familiarWithHyroxStations: Bool?
    var difficultExercises: [String]
    var hasGymAccess: Bool?
    var gymName: String?
    var gymLocation: String?
    var availableEquipment: [String]
    
    // Étape 4: Planning
    var preferredTrainingFrequency: TrainingFrequency?
    var preferredSessionDuration: SessionDuration?
    var targetCompetitionDate: Date?
    var preferredTrainingTime: TrainingTime?
    
    // Étape 5: Préférences
    var preferredIntensity: TrainingIntensity?
    var prefersStructuredProgram: Bool?
    var wantsNotifications: Bool?
    
    // Timestamps
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?
    
    init() {
        self.id = ""
        self.userId = ""
        self.hasCompletedOnboarding = false
        
        self.hyroxExperience = nil
        self.hasCompetedHyrox = nil
        self.primaryGoal = nil
        
        self.currentTrainingFrequency = nil
        self.trainingTypes = []
        self.fitnessLevel = nil
        self.injuriesLimitations = nil
        
        self.familiarWithHyroxStations = nil
        self.difficultExercises = []
        self.hasGymAccess = nil
        self.gymName = nil
        self.gymLocation = nil
        self.availableEquipment = []
        
        self.preferredTrainingFrequency = nil
        self.preferredSessionDuration = nil
        self.targetCompetitionDate = nil
        self.preferredTrainingTime = nil
        
        self.preferredIntensity = nil
        self.prefersStructuredProgram = nil
        self.wantsNotifications = nil
        
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil
    }
}

// MARK: - Enums

enum HyroxExperience: String, CaseIterable, Codable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"
    
    var displayName: String {
        switch self {
        case .beginner: return "Débutant"
        case .intermediate: return "Intermédiaire"
        case .advanced: return "Avancé"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Première découverte d'HYROX"
        case .intermediate: return "Quelques entraînements ou compétitions"
        case .advanced: return "Expérience confirmée en HYROX"
        }
    }
}

enum HyroxGoal: String, CaseIterable, Codable {
    case firstParticipation = "FIRST_PARTICIPATION"
    case improveTime = "IMPROVE_TIME"
    case professionalCompetition = "PROFESSIONAL_COMPETITION"
    
    var displayName: String {
        switch self {
        case .firstParticipation: return "Première participation"
        case .improveTime: return "Améliorer mon temps"
        case .professionalCompetition: return "Compétition professionnelle"
        }
    }
    
    var description: String {
        switch self {
        case .firstParticipation: return "Découvrir HYROX et réussir ma première course"
        case .improveTime: return "Battre mon record personnel"
        case .professionalCompetition: return "Viser les podiums et qualifications"
        }
    }
}

enum TrainingFrequency: String, CaseIterable, Codable {
    case onceWeek = "ONCE_WEEK"
    case twiceWeek = "TWICE_WEEK"
    case threeWeek = "THREE_WEEK"
    case fourWeek = "FOUR_WEEK"
    case fivePlusWeek = "FIVE_PLUS_WEEK"
    
    var displayName: String {
        switch self {
        case .onceWeek: return "1x / semaine"
        case .twiceWeek: return "2x / semaine"
        case .threeWeek: return "3x / semaine"
        case .fourWeek: return "4x / semaine"
        case .fivePlusWeek: return "5+ / semaine"
        }
    }
}

enum SessionDuration: String, CaseIterable, Codable {
    case thirtyMin = "THIRTY_MIN"
    case fortyFiveMin = "FORTY_FIVE_MIN"
    case oneHour = "ONE_HOUR"
    case oneHourPlus = "ONE_HOUR_PLUS"
    
    var displayName: String {
        switch self {
        case .thirtyMin: return "30 minutes"
        case .fortyFiveMin: return "45 minutes"
        case .oneHour: return "1 heure"
        case .oneHourPlus: return "1h+"
        }
    }
}

enum TrainingTime: String, CaseIterable, Codable {
    case morning = "MORNING"
    case midday = "MIDDAY"
    case evening = "EVENING"
    case flexible = "FLEXIBLE"
    
    var displayName: String {
        switch self {
        case .morning: return "Matin"
        case .midday: return "Midi"
        case .evening: return "Soir"
        case .flexible: return "Flexible"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .midday: return "sun.max"
        case .evening: return "sunset"
        case .flexible: return "clock"
        }
    }
}

enum TrainingIntensity: String, CaseIterable, Codable {
    case shortIntense = "SHORT_INTENSE"
    case longModerate = "LONG_MODERATE"
    case mixed = "MIXED"
    
    var displayName: String {
        switch self {
        case .shortIntense: return "Courtes et intenses"
        case .longModerate: return "Longues et modérées"
        case .mixed: return "Mixte"
        }
    }
    
    var description: String {
        switch self {
        case .shortIntense: return "30-45min à haute intensité"
        case .longModerate: return "1h+ à intensité modérée"
        case .mixed: return "Varier selon les objectifs"
        }
    }
}

// MARK: - Training Types

enum TrainingType: String, CaseIterable {
    case running = "RUNNING"
    case strength = "STRENGTH"
    case crossfit = "CROSSFIT"
    case hyrox = "HYROX"
    case swimming = "SWIMMING"
    case cycling = "CYCLING"
    case yoga = "YOGA"
    case pilates = "PILATES"
    case boxing = "BOXING"
    case climbing = "CLIMBING"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .running: return "Course à pied"
        case .strength: return "Musculation"
        case .crossfit: return "CrossFit"
        case .hyrox: return "Hyrox"
        case .swimming: return "Natation"
        case .cycling: return "Cyclisme"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .boxing: return "Boxe"
        case .climbing: return "Escalade"
        case .other: return "Autre"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .strength: return "dumbbell"
        case .crossfit: return "figure.strengthtraining.traditional"
        case .hyrox: return "figure.indoor.rowing"
        case .swimming: return "figure.pool.swim"
        case .cycling: return "bicycle"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .boxing: return "figure.boxing"
        case .climbing: return "figure.climbing"
        case .other: return "ellipsis"
        }
    }
}

// MARK: - HYROX Equipment

enum HyroxEquipment: String, CaseIterable {
    case skierg = "SKIERG"
    case sled = "SLED"
    case rowerg = "ROWERG"
    case wallBalls = "WALL_BALLS"
    case kettlebells = "KETTLEBELLS"
    case dumbbells = "DUMBBELLS"
    case sandbag = "SANDBAG"
    case boxJump = "BOX_JUMP"
    case pullUpBar = "PULL_UP_BAR"
    case farmers = "FARMERS_CARRY"
    
    var displayName: String {
        switch self {
        case .skierg: return "SkiErg"
        case .sled: return "Traîneau (Push/Pull)"
        case .rowerg: return "Rameur"
        case .wallBalls: return "Wall Balls"
        case .kettlebells: return "Kettlebells"
        case .dumbbells: return "Haltères"
        case .sandbag: return "Sac de sable"
        case .boxJump: return "Box Jump"
        case .pullUpBar: return "Barre de traction"
        case .farmers: return "Farmers Carry"
        }
    }
    
    var isHyroxStation: Bool {
        switch self {
        case .skierg, .sled, .rowerg, .wallBalls, .sandbag, .farmers:
            return true
        default:
            return false
        }
    }
} 
