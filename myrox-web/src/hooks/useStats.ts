'use client';

import { useState, useEffect, useCallback } from 'react';
import { AthleteStats, WorkoutTrend, CategoryStats } from '@/types';
import { coachesApi } from '@/lib/api';

interface UseStatsProps {
  coachId: string;
  period: '7d' | '30d' | '90d';
}

export const useStats = ({ coachId, period }: UseStatsProps) => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [athleteStats, setAthleteStats] = useState<AthleteStats[]>([]);
  const [workoutTrends, setWorkoutTrends] = useState<WorkoutTrend[]>([]);
  const [categoryStats, setCategoryStats] = useState<CategoryStats[]>([]);
  const [summary, setSummary] = useState({
    totalWorkouts: 0,
    avgRating: 0,
    avgCompletionRate: 0,
    activeAthletes: 0,
  });

  const fetchStats = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Fetching stats for coachId:', coachId, 'period:', period);
      
      if (!coachId) {
        setError('CoachId manquant');
        setLoading(false);
        return;
      }

      const stats = await coachesApi.getDetailedStats(coachId, period);
      console.log('✅ Stats received:', stats);
      
      setAthleteStats(stats.athleteStats || []);
      setWorkoutTrends(stats.workoutTrends || []);
      setCategoryStats(stats.categoryStats || []);
      setSummary(stats.summary || {
        totalWorkouts: 0,
        avgRating: 0,
        avgCompletionRate: 0,
        activeAthletes: 0,
      });
      
      console.log('🎯 Stats loaded successfully');
      
    } catch (err) {
      console.error('❌ API Error:', err);
      
      // Ne pas utiliser de données de test : on renvoie des tableaux vides
      setAthleteStats([]);
      setWorkoutTrends([]);
      setCategoryStats([]);
      setSummary({
        totalWorkouts: 0,
        avgRating: 0,
        avgCompletionRate: 0,
        activeAthletes: 0,
      });
      setError(err instanceof Error ? err.message : 'Erreur inconnue');
    } finally {
      setLoading(false);
    }
  }, [coachId, period]);

  useEffect(() => {
    fetchStats();
  }, [fetchStats]);

  return {
    loading,
    error,
    athleteStats,
    workoutTrends,
    categoryStats,
    summary,
    refetch: fetchStats,
  };
}; 