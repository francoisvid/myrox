/* eslint-disable @typescript-eslint/no-explicit-any */
import axios from 'axios';
import { Template, Exercise, User, Workout, DashboardStats, Coach, StatsResponse, CoachInvitation, SubscriptionStatus, InvitationResponse, UseInvitationResponse } from '@/types';
import { config } from '@/lib/config';
import { auth } from '@/lib/firebase';

// Construire l'URL de base en utilisant la configuration centralisée
const API_BASE_URL = config.api.fullUrl;

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'X-Client-Type': 'web', // Identifier les appels depuis l'interface web
  },
});

// Fonction pour créer une instance API avec l'authentification
export const createAuthenticatedApi = (firebaseUID?: string) => {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'X-Client-Type': 'web',
  };
  if (firebaseUID) {
    headers['x-firebase-uid'] = firebaseUID;
  }

  return axios.create({
    baseURL: API_BASE_URL,
    headers,
  });
};

// Intercepteur pour ajouter l'UID si disponible dans la requête
/* eslint-disable @typescript-eslint/no-explicit-any */
api.interceptors.request.use((config) => {
  // Exécuter côté client uniquement
  if (typeof window !== 'undefined' && auth?.currentUser?.uid) {
    if (!config.headers) {
      (config as any).headers = {};
    }
    if (!(config.headers as any)['x-firebase-uid']) {
      (config.headers as any)['x-firebase-uid'] = auth.currentUser.uid;
    }
  }
  return config;
});

// Templates API
export const templatesApi = {
  // Récupérer tous les templates d'un coach
  getTemplates: async (coachId: string): Promise<Template[]> => {
    const response = await api.get(`/coaches/${coachId}/templates`);
    return response.data;
  },

  // Créer un nouveau template personnel
  createTemplate: async (template: Omit<Template, 'id' | 'createdAt' | 'updatedAt'>, firebaseUID?: string): Promise<Template> => {
    const uid = firebaseUID;
    const authenticatedApi = createAuthenticatedApi(uid);
    const response = await authenticatedApi.post(`/users/firebase/${uid}/personal-templates`, template);
    return response.data;
  },

  // Mettre à jour un template personnel
  updateTemplate: async (id: string, template: Partial<Template>, firebaseUID?: string): Promise<Template> => {
    const uid = firebaseUID;
    const authenticatedApi = createAuthenticatedApi(uid);
    const response = await authenticatedApi.put(`/users/firebase/${uid}/personal-templates/${id}`, template);
    return response.data;
  },

  // Supprimer un template personnel
  deleteTemplate: async (id: string, firebaseUID?: string): Promise<void> => {
    const uid = firebaseUID;
    const authenticatedApi = createAuthenticatedApi(uid);
    await authenticatedApi.delete(`/users/firebase/${uid}/personal-templates/${id}`);
  },

  // Récupérer un template par ID
  getTemplate: async (id: string, firebaseUID?: string): Promise<Template | undefined> => {
    const uid = firebaseUID;
    const authenticatedApi = createAuthenticatedApi(uid);
    const response = await authenticatedApi.get(`/users/firebase/${uid}/personal-templates`);
    return response.data.find((t: Template) => t.id === id);
  },

  // Assigner un template à des utilisateurs (pour les coachs)
  assignTemplate: async (templateId: string, userIds: string[]): Promise<void> => {
    await api.post(`/templates/${templateId}/assign`, { userIds });
  },

  // Désassigner un template d'un utilisateur (pour les coachs)
  unassignTemplate: async (templateId: string, userId: string): Promise<void> => {
    await api.delete(`/templates/${templateId}/assign/${userId}`);
  },
};

// Exercises API
export const exercisesApi = {
  // Récupérer tous les exercices
  getExercises: async (): Promise<Exercise[]> => {
    console.log('🔍 Récupération des exercices depuis:', `${API_BASE_URL}/exercises`);
    const response = await api.get('/exercises');
    console.log('✅ Exercices récupérés:', response.data?.length || 0);
    return response.data;
  },

  // Récupérer un exercice par ID
  getExercise: async (id: string): Promise<Exercise> => {
    console.log('🔍 Récupération exercice:', `${API_BASE_URL}/exercises/${id}`);
    const response = await api.get(`/exercises/${id}`);
    return response.data;
  },

  // Créer un nouvel exercice
  createExercise: async (exercise: Omit<Exercise, 'id' | 'createdAt' | 'updatedAt'>): Promise<Exercise> => {
    const response = await api.post('/exercises', exercise);
    return response.data;
  },
};

// Users API
export const usersApi = {
  // Récupérer tous les athlètes d'un coach
  getAthletes: async (coachId: string): Promise<User[]> => {
    const response = await api.get(`/coaches/${coachId}/athletes`);
    return response.data;
  },

  // Récupérer un utilisateur par ID
  getUser: async (id: string): Promise<User> => {
    const response = await api.get(`/users/${id}`);
    return response.data;
  },

  // Récupérer les workouts d'un utilisateur
  getUserWorkouts: async (userId: string): Promise<Workout[]> => {
    const response = await api.get(`/users/${userId}/workouts`);
    return response.data;
  },

  // Récupérer le détail d'un athlète (vérification coach)
  getAthleteDetail: async (coachId: string, athleteId: string): Promise<User> => {
    const response = await api.get(`/coaches/${coachId}/athletes/${athleteId}`);
    return response.data;
  },
};

// Coaches API
export const coachesApi = {
  // Récupérer un coach par ID
  getCoach: async (id: string): Promise<Coach> => {
    const response = await api.get(`/coaches/${id}`);
    return response.data;
  },

  // Récupérer les stats du dashboard d'un coach
  getDashboardStats: async (coachId: string): Promise<DashboardStats> => {
    const response = await api.get(`/coaches/${coachId}/stats`);
    return response.data;
  },

  // Récupérer les statistiques détaillées
  getDetailedStats: async (coachId: string, period: '7d' | '30d' | '90d' = '30d'): Promise<StatsResponse> => {
    const response = await api.get(`/coaches/${coachId}/stats/detailed?period=${period}`);
    return response.data;
  },

  // Récupérer les templates d'un coach
  getTemplates: async (coachId: string): Promise<Template[]> => {
    const response = await api.get(`/coaches/${coachId}/templates`);
    return response.data;
  },

  // Récupérer les templates personnels d'un utilisateur (pour la vue coach)
  getUserPersonalTemplates: async (firebaseUID: string): Promise<Template[]> => {
    const authenticatedApi = createAuthenticatedApi(firebaseUID);
    const response = await authenticatedApi.get(`/users/firebase/${firebaseUID}/personal-templates`);
    return response.data;
  },

  // Récupérer le statut d'abonnement
  getSubscriptionStatus: async (coachId: string): Promise<SubscriptionStatus> => {
    const response = await api.get(`/coaches/${coachId}/subscription-status`);
    return response.data;
  },

  // Générer un code d'invitation
  generateInvitation: async (coachId: string, description?: string): Promise<InvitationResponse> => {
    const response = await api.post(`/coaches/${coachId}/invitations`, { description });
    return response.data;
  },

  // Récupérer les invitations d'un coach
  getInvitations: async (coachId: string): Promise<CoachInvitation[]> => {
    const response = await api.get(`/coaches/${coachId}/invitations`);
    return response.data;
  },
};

// Workouts API
export const workoutsApi = {
  // Récupérer tous les workouts d'un coach (via ses athlètes)
  getCoachWorkouts: async (coachId: string): Promise<Workout[]> => {
    const response = await api.get(`/coaches/${coachId}/workouts`);
    return response.data;
  },

  // Récupérer un workout par ID
  getWorkout: async (id: string): Promise<Workout> => {
    const response = await api.get(`/workouts/${id}`);
    return response.data;
  },
};

// Auth API
export const authApi = {
  // Utiliser un code d'invitation
  useInvitation: async (code: string, firebaseUID: string): Promise<UseInvitationResponse> => {
    const authenticatedApi = createAuthenticatedApi(firebaseUID);
    const response = await authenticatedApi.post('/auth/use-invitation', { code, firebaseUID });
    return response.data;
  },
};

export default api;