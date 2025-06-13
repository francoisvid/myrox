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
        throw new Error('CoachId is required');
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
      
      // Fallback vers les données mock si l'API n'est pas disponible
      const mockAthleteStats: AthleteStats[] = [
        {
          athleteId: 'athlete-1',
          athleteName: 'Marie Dupont (Mock)',
          totalWorkouts: 15,
          avgRating: 4.3,
          totalTime: 720,
          completionRate: 87,
        },
        {
          athleteId: 'athlete-2',
          athleteName: 'Jean Martin (Mock)',
          totalWorkouts: 22,
          avgRating: 4.1,
          totalTime: 980,
          completionRate: 91,
        },
      ];

      const mockWorkoutTrends: WorkoutTrend[] = [
        { date: '2024-01-01', count: 3, avgRating: 4.1 },
        { date: '2024-01-02', count: 5, avgRating: 4.3 },
        { date: '2024-01-03', count: 2, avgRating: 4.0 },
        { date: '2024-01-04', count: 6, avgRating: 4.4 },
        { date: '2024-01-05', count: 4, avgRating: 4.2 },
        { date: '2024-01-06', count: 3, avgRating: 4.1 },
        { date: '2024-01-07', count: 7, avgRating: 4.5 },
      ];

      const mockCategoryStats: CategoryStats[] = [
        { name: 'HYROX', value: 35, color: '#3B82F6' },
        { name: 'Musculation', value: 28, color: '#10B981' },
        { name: 'Cardio', value: 20, color: '#F59E0B' },
        { name: 'Fonctionnel', value: 12, color: '#EF4444' },
        { name: 'Mixte', value: 5, color: '#8B5CF6' },
      ];

      setAthleteStats(mockAthleteStats);
      setWorkoutTrends(mockWorkoutTrends);
      setCategoryStats(mockCategoryStats);
      
      const totalWorkouts = mockAthleteStats.reduce((sum, athlete) => sum + athlete.totalWorkouts, 0);
      const avgRating = mockAthleteStats.reduce((sum, athlete) => sum + athlete.avgRating, 0) / mockAthleteStats.length;
      const avgCompletionRate = mockAthleteStats.reduce((sum, athlete) => sum + athlete.completionRate, 0) / mockAthleteStats.length;
      
      setSummary({
        totalWorkouts,
        avgRating,
        avgCompletionRate,
        activeAthletes: mockAthleteStats.length,
      });
      
      setError(`Mode hors-ligne : ${err instanceof Error ? err.message : 'Erreur inconnue'}`);
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