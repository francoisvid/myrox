'use client';

import { useState, useEffect, useCallback } from 'react';
import { User } from '@/types';
import { usersApi } from '@/lib/api';
import { useCoachId } from './useCoachId';

export const useAthletes = () => {
  const [athletes, setAthletes] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const { firebaseUID, loading: coachLoading } = useCoachId();

  const fetchAthletes = useCallback(async () => {
    if (coachLoading || !firebaseUID) {
      return; // Attendre que le firebaseUID soit disponible
    }
    
    try {
      setLoading(true);
      setError(null);
      
      // Récupérer les athlètes du coach connecté
      const data = await usersApi.getAthletes(firebaseUID);
      setAthletes(data);
      
      console.log('✅ Athlètes récupérés:', data.length);
    } catch (err) {
      console.error('❌ Erreur récupération athlètes:', err);
      setError(err instanceof Error ? err.message : 'Erreur inconnue');
      
      // Ne pas utiliser de données de test en production
      setAthletes([]);
    } finally {
      setLoading(false);
    }
  }, [firebaseUID, coachLoading]);

  useEffect(() => {
    fetchAthletes();
  }, [fetchAthletes]);

  return {
    athletes,
    loading,
    error,
    refetch: fetchAthletes
  };
}; 