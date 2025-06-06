import axios from 'axios';
import { Template, Exercise, User, Workout, DashboardStats, Coach, StatsResponse } from '@/types';
import { config } from '@/lib/config';

// Construire l'URL de base en utilisant la configuration centralisée
const API_BASE_URL = config.api.fullUrl;

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'X-Client-Type': 'web', // Identifier les appels depuis l'interface web
  },
});

// Intercepteur pour ajouter automatiquement le Firebase UID
api.interceptors.request.use((requestConfig) => {
  // Pour l'instant, on utilise l'UID hardcodé. 
  // TODO: Récupérer depuis le context Firebase Auth
  requestConfig.headers['x-firebase-uid'] = config.defaults.firebaseUID;
  return requestConfig;
});

// Templates API
export const templatesApi = {
  // Récupérer tous les templates d'un coach
  getTemplates: async (coachId: string): Promise<Template[]> => {
    const response = await api.get(`/coaches/${coachId}/templates`);
    return response.data;
  },

  // Créer un nouveau template personnel
  createTemplate: async (template: Omit<Template, 'id' | 'createdAt' | 'updatedAt'>): Promise<Template> => {
    const firebaseUID = config.defaults.firebaseUID;
    const response = await api.post(`/users/firebase/${firebaseUID}/personal-templates`, template);
    return response.data;
  },

  // Mettre à jour un template personnel
  updateTemplate: async (id: string, template: Partial<Template>): Promise<Template> => {
    const firebaseUID = config.defaults.firebaseUID;
    const response = await api.put(`/users/firebase/${firebaseUID}/personal-templates/${id}`, template);
    return response.data;
  },

  // Supprimer un template personnel
  deleteTemplate: async (id: string): Promise<void> => {
    const firebaseUID = config.defaults.firebaseUID;
    await api.delete(`/users/firebase/${firebaseUID}/personal-templates/${id}`);
  },

  // Récupérer un template par ID
  getTemplate: async (id: string): Promise<Template | undefined> => {
    // Pour l'instant, on récupère tous les templates et on filtre
    // TODO: Implémenter une route GET spécifique pour un template
    const firebaseUID = config.defaults.firebaseUID;
    const response = await api.get(`/users/firebase/${firebaseUID}/personal-templates`);
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
    const response = await api.get(`/users/firebase/${firebaseUID}/personal-templates`);
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

export default api; 