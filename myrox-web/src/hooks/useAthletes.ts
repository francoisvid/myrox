'use client';

import { useState, useEffect, useCallback } from 'react';
import { User } from '@/types';
import { usersApi } from '@/lib/api';
import { config } from '@/lib/config';

export const useAthletes = () => {
  const [athletes, setAthletes] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAthletes = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Récupérer les athlètes du coach actuel
      const coachId = config.defaults.coachId;
      const data = await usersApi.getAthletes(coachId);
      setAthletes(data);
      
      console.log('✅ Athlètes récupérés:', data.length);
    } catch (err) {
      console.error('❌ Erreur récupération athlètes:', err);
      setError(err instanceof Error ? err.message : 'Erreur inconnue');
      
      // Mock data pour le développement
      const mockAthletes: User[] = [
        {
          id: '1',
          firebaseUID: 'user1',
          displayName: 'Jean Dupont',
          email: 'jean.dupont@example.com',
          createdAt: '2024-01-15T00:00:00.000Z',
          updatedAt: '2024-01-15T00:00:00.000Z',
          coachId: config.defaults.coachId
        },
        {
          id: '2',
          firebaseUID: 'user2',
          displayName: 'Marie Martin',
          email: 'marie.martin@example.com',
          createdAt: '2024-01-20T00:00:00.000Z',
          updatedAt: '2024-01-20T00:00:00.000Z',
          coachId: config.defaults.coachId
        },
        {
          id: '3',
          firebaseUID: 'user3',
          displayName: 'Pierre Durand',
          email: 'pierre.durand@example.com',
          createdAt: '2024-01-25T00:00:00.000Z',
          updatedAt: '2024-01-25T00:00:00.000Z',
          coachId: config.defaults.coachId
        }
      ];
      
      setAthletes(mockAthletes);
      console.log('⚠️ Utilisation des données de test');
    } finally {
      setLoading(false);
    }
  }, []);

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