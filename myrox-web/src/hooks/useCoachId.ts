'use client';

import { useAuth } from './useAuth';
import config from '@/lib/config';

/**
 * Hook pour récupérer l'ID du coach connecté
 * Retourne l'ID du coach si l'utilisateur est connecté et est un coach,
 * sinon retourne la valeur par défaut pour les tests
 */
export const useCoachId = () => {
  const { user, loading, isAuthenticated, isCoach } = useAuth();
  
  // Si chargement en cours, retourner undefined
  if (loading) {
    return {
      coachId: undefined,
      firebaseUID: undefined,
      loading: true,
      isCoach: false
    };
  }
  
  // Si utilisateur connecté et est un coach
  if (isAuthenticated && isCoach && user?.coach?.id && user?.user?.firebaseUID) {
    return {
      coachId: user.coach.id,
      firebaseUID: user.user.firebaseUID,
      loading: false,
      isCoach: true
    };
  }
  
  // Valeurs par défaut pour les tests ou utilisateurs non connectés
  return {
    coachId: config.defaults.coachId,
    firebaseUID: config.defaults.firebaseUID,
    loading: false,
    isCoach: false
  };
};

export default useCoachId; 