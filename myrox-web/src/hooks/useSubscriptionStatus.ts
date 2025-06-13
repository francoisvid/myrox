'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { coachesApi } from '@/lib/api';
import { SubscriptionStatus } from '@/types';

export const useSubscriptionStatus = () => {
  const { coachId } = useAuth();
  const [subscriptionStatus, setSubscriptionStatus] = useState<SubscriptionStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSubscriptionStatus = async () => {
    if (!coachId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const status = await coachesApi.getSubscriptionStatus(coachId);
      setSubscriptionStatus(status);
    } catch (err) {
      console.error('Erreur récupération statut abonnement:', err);
      setError('Impossible de charger le statut de l\'abonnement');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSubscriptionStatus();
  }, [coachId]);

  const refetch = () => {
    fetchSubscriptionStatus();
  };

  return {
    subscriptionStatus,
    loading,
    error,
    refetch
  };
}; 