'use client';

import { useState, useEffect } from 'react';

// Hook temporaire pour l'authentification
// TODO: Remplacer par Firebase Auth
export const useAuth = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  
  // ID de coach réel de Francois
  // TODO: Récupérer depuis Firebase Auth
  const coachId = 'ba031335-1c73-4a3a-b296-f4d19a6a18f7';

  useEffect(() => {
    // Simulation d'une vérification d'auth
    const timer = setTimeout(() => {
      setIsAuthenticated(true);
      setLoading(false);
    }, 100);

    return () => clearTimeout(timer);
  }, []);

  return {
    isAuthenticated,
    loading,
    coachId,
    // Fonctions temporaires
    login: () => setIsAuthenticated(true),
    logout: () => setIsAuthenticated(false),
  };
}; 