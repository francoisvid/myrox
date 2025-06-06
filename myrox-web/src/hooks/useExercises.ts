'use client';

import { useState, useEffect, useCallback } from 'react';
import { Exercise } from '@/types';
import { exercisesApi } from '@/lib/api';

export function useExercises() {
  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchExercises = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await exercisesApi.getExercises();
      setExercises(data);
    } catch (err) {
      console.error('Erreur lors du chargement des exercices:', err);
      setError('Impossible de charger les exercices');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchExercises();
  }, [fetchExercises]);

  return {
    exercises,
    loading,
    error,
    refetch: fetchExercises,
  };
} 