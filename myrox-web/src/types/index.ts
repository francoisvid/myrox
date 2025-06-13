export interface User {
  id: string;
  firebaseUID: string;
  email?: string;
  displayName?: string;
  createdAt: string;
  updatedAt: string;
  coachId?: string;
}

export interface Coach {
  id: string;
  firebaseUID: string;
  displayName: string;
  email?: string;
  specialization?: string;
  bio?: string;
  profilePicture?: string;
  certifications: string[];
  isActive: boolean;
  
  // Système d'abonnement
  subscriptionPlan: 'FREE' | 'STARTER' | 'PROFESSIONAL' | 'ENTERPRISE';
  maxAthletes: number;
  maxInvitations: number;
  isSubscriptionActive: boolean;
  subscriptionExpiresAt?: string;
  trialEndsAt?: string;
  
  createdAt: string;
  updatedAt: string;
  userId: string;
}

export interface Template {
  id: string;
  name: string;
  rounds: number;
  description?: string;
  difficulty: 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED' | 'EXPERT';
  estimatedTime: number;
  category: 'HYROX' | 'STRENGTH' | 'CARDIO' | 'FUNCTIONAL' | 'FLEXIBILITY' | 'MIXED';
  isPersonal: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  creatorId: string;
  coachId?: string;
  exercises?: TemplateExercise[];
  assignedUsers?: User[];
}

export interface Exercise {
  id: string;
  name: string;
  description?: string;
  category: 'RUNNING' | 'STRENGTH' | 'FUNCTIONAL' | 'CARDIO' | 'FLEXIBILITY' | 'HYROX_STATION';
  equipment: string[];
  instructions?: string;
  videoUrl?: string;
  isHyroxExercise: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface TemplateExercise {
  id: string;
  order: number;
  sets?: number;
  reps?: number;
  duration?: number;
  distance?: number;
  weight?: number;
  restTime?: number;
  notes?: string;
  templateId: string;
  exerciseId: string;
  exercise?: Exercise;
}

export interface Workout {
  id: string;
  name?: string;
  startedAt: string;
  completedAt?: string;
  totalDuration?: number;
  notes?: string;
  rating?: number;
  createdAt: string;
  updatedAt: string;
  userId: string;
  templateId?: string;
  user?: User;
  template?: Template;
  exercises?: WorkoutExercise[];
}

export interface WorkoutExercise {
  id: string;
  order: number;
  sets?: number;
  repsCompleted?: number;
  durationCompleted?: number;
  distanceCompleted?: number;
  weightUsed?: number;
  restTime?: number;
  notes?: string;
  completedAt?: string;
  workoutId: string;
  exerciseId: string;
  exercise?: Exercise;
}

export interface PersonalBest {
  id: string;
  exerciseType: string;
  value: number;
  unit: string;
  achievedAt: string;
  createdAt: string;
  userId: string;
  workoutId?: string;
}

export interface DashboardStats {
  totalAthletes: number;
  totalTemplates: number;
  activeWorkouts: number;
  completedWorkouts: number;
  avgWorkoutRating: number;
}

// Types pour les statistiques avancées
export interface AthleteStats {
  athleteId: string;
  athleteName: string;
  totalWorkouts: number;
  avgRating: number;
  totalTime: number;
  completionRate: number;
}

export interface WorkoutTrend {
  date: string;
  count: number;
  avgRating: number;
}

export interface CategoryStats {
  name: string;
  value: number;
  color: string;
}

export interface StatsResponse {
  athleteStats: AthleteStats[];
  workoutTrends: WorkoutTrend[];
  categoryStats: CategoryStats[];
  summary: {
    totalWorkouts: number;
    avgRating: number;
    avgCompletionRate: number;
    activeAthletes: number;
  };
}

// Types pour le système d'invitation
export interface CoachInvitation {
  id: string;
  code: string;
  coachId: string;
  description?: string;
  isActive: boolean;
  usedByUserId?: string;
  usedBy?: User;
  usedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SubscriptionStatus {
  plan: 'FREE' | 'STARTER' | 'PROFESSIONAL' | 'ENTERPRISE';
  maxAthletes: number;
  maxInvitations: number;
  currentAthletes: number;
  activeInvitations: number;
  isActive: boolean;
  expiresAt?: string;
  canCreateInvitation: boolean;
  canAddAthlete: boolean;
}

export interface InvitationResponse {
  id: string;
  code: string;
  description: string;
  createdAt: string;
}

export interface UseInvitationResponse {
  success: boolean;
  message: string;
  coach: {
    id: string;
    displayName: string;
    specialization?: string;
  };
} 