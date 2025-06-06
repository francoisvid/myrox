import { useState, useEffect, useCallback } from 'react';
import { Template } from '@/types';
import { coachesApi, templatesApi } from '@/lib/api';

export const useTemplates = () => {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [loading, setLoading] = useState(true);
  const [isCreating, setIsCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Firebase UID réel
  const FIREBASE_UID = 'FkCwkLcLLYhH2RCOyOs4J0Rl28G2';

  const fetchTemplates = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Récupérer les templates personnels
      const personalTemplates = await coachesApi.getUserPersonalTemplates(FIREBASE_UID);
      setTemplates(personalTemplates);
    } catch (err) {
      console.error('Erreur lors du chargement des templates:', err);
      setError('Impossible de charger les templates');
      
      // Fallback vers des données vides
      setTemplates([]);
    } finally {
      setLoading(false);
    }
  }, [FIREBASE_UID]);

  useEffect(() => {
    fetchTemplates();
  }, [fetchTemplates]);

  // CRUD Functions
  const createTemplate = useCallback(async (templateData: Partial<Template> & { name: string; exercises: any[] }) => {
    try {
      setIsCreating(true);
      setError(null);
      
      console.log('📝 Création template avec exercices:', templateData.exercises);
      
      // Transformer les exercices au format attendu par l'API
      const transformedExercises = templateData.exercises.map((exercise, index) => ({
        exerciseId: exercise.exerciseId,
        order: index, // Réorganiser les ordres
        sets: exercise.sets || 1,
        targetRepetitions: exercise.reps || undefined, // ⭐ Transformation reps -> targetRepetitions
        targetTime: exercise.duration || undefined,    // ⭐ Transformation duration -> targetTime
        targetDistance: exercise.distance || undefined, // ⭐ Transformation distance -> targetDistance
        weight: exercise.weight || undefined,
        restTime: exercise.restTime || 60,
      }));
      
      console.log('🔄 Exercices transformés pour l\'API:', transformedExercises);
      
      // Compléter les données avec des valeurs par défaut (sans exercises car on les envoie séparément)
      const { exercises: _, ...templateDataWithoutExercises } = templateData;
      const completeTemplateData = {
        ...templateDataWithoutExercises,
        exercises: transformedExercises, // Utiliser les exercices transformés
        rounds: templateData.rounds || 1,
        difficulty: templateData.difficulty || 'BEGINNER' as const,
        estimatedTime: templateData.estimatedTime || 30,
        category: templateData.category || 'MIXED' as const,
        isPersonal: templateData.isPersonal !== undefined ? templateData.isPersonal : true,
        isActive: templateData.isActive !== undefined ? templateData.isActive : true,
        creatorId: templateData.creatorId || 'demo-user-id',
      };
      
      const newTemplate = await templatesApi.createTemplate(completeTemplateData as any);
      setTemplates(prev => [newTemplate, ...prev]);
      return newTemplate;
    } catch (err) {
      console.error('Erreur lors de la création du template:', err);
      setError('Impossible de créer le template');
      throw err;
    } finally {
      setIsCreating(false);
    }
  }, []);

  const updateTemplate = useCallback(async (id: string, templateData: Partial<Template>) => {
    try {
      setError(null);
      
      console.log('📝 Mise à jour template avec exercices:', templateData.exercises);
      
      // Transformer les exercices au format attendu par l'API si présents
      let transformedData = { ...templateData };
      if (templateData.exercises) {
        const transformedExercises = templateData.exercises.map((exercise, index) => ({
          exerciseId: exercise.exerciseId,
          order: index, // Réorganiser les ordres
          sets: exercise.sets || 1,
          targetRepetitions: exercise.reps || undefined, // ⭐ Transformation reps -> targetRepetitions
          targetTime: exercise.duration || undefined,    // ⭐ Transformation duration -> targetTime
          targetDistance: exercise.distance || undefined, // ⭐ Transformation distance -> targetDistance
          weight: exercise.weight || undefined,
          restTime: exercise.restTime || 60,
        }));
        
        console.log('🔄 Exercices transformés pour l\'API:', transformedExercises);
        transformedData = { ...templateData, exercises: transformedExercises as any };
      }
      
      const updatedTemplate = await templatesApi.updateTemplate(id, transformedData);
      setTemplates(prev => prev.map(t => t.id === id ? updatedTemplate : t));
      return updatedTemplate;
    } catch (err) {
      console.error('Erreur lors de la mise à jour du template:', err);
      setError('Impossible de mettre à jour le template');
      throw err;
    }
  }, []);

  const deleteTemplate = useCallback(async (id: string) => {
    try {
      setError(null);
      await templatesApi.deleteTemplate(id);
      setTemplates(prev => prev.filter(t => t.id !== id));
    } catch (err) {
      console.error('Erreur lors de la suppression du template:', err);
      setError('Impossible de supprimer le template');
      throw err;
    }
  }, []);

  const getTemplate = useCallback((id: string) => {
    return templates.find(t => t.id === id);
  }, [templates]);

  return {
    templates,
    loading,
    isCreating,
    error,
    refreshTemplates: fetchTemplates,
    createTemplate,
    updateTemplate,
    deleteTemplate,
    getTemplate,
  };
}; 