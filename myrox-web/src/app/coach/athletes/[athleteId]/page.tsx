'use client';

import { useParams } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useCoachId } from '@/hooks/useCoachId';
import { usersApi } from '@/lib/api';
import { User } from '@/types';
import Link from 'next/link';
import {
  HYROX_EXPERIENCE_LABELS,
  HYROX_GOAL_LABELS,
  TRAINING_FREQUENCY_LABELS,
  SESSION_DURATION_LABELS,
  TRAINING_TIME_LABELS,
  TRAINING_INTENSITY_LABELS,
} from '@/constants/onboardingLabels';

export default function AthleteDetailPage() {
  const params = useParams();
  const athleteId = (params?.athleteId || params?.id) as string | undefined;
  const { coachId } = useCoachId();

  const [athlete, setAthlete] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAthlete = async () => {
      if (!coachId || !athleteId) return;
      try {
        setLoading(true);
        const data = await usersApi.getAthleteDetail(coachId, athleteId);
        setAthlete(data);
      } catch (err) {
        console.error('❌ Erreur récupération athlète:', err);
        setError("Impossible de charger les informations de l'athlète.");
      } finally {
        setLoading(false);
      }
    };

    fetchAthlete();
  }, [coachId, athleteId]);

  if (loading) {
    return <div className="p-8">Chargement des informations…</div>;
  }

  if (error) {
    return (
      <div className="p-8">
        <p className="text-red-600 mb-4">{error}</p>
        <Link href="/coach/athletes" className="text-blue-600 underline">
          ← Retour à la liste
        </Link>
      </div>
    );
  }

  if (!athlete) return null;

  const info = athlete.userInformations;
  console.log(info);
  return (
    <div className="max-w-3xl mx-auto py-8">
      <h1 className="text-3xl font-bold mb-4">
        {athlete.displayName || athlete.email}
      </h1>

      <div className="space-y-2 text-gray-700">
        <p>
          <strong>Email :</strong> {athlete.email}
        </p>
        <p>
          <strong>Membre depuis :</strong>{' '}
          {new Date(athlete.createdAt).toLocaleDateString('fr-FR')}
        </p>
      </div>

      {info && (
        <div className="mt-8">
          <h2 className="text-2xl font-semibold mb-4">Profil &amp; Onboarding</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {Object.entries({
              "A complété l'onboarding": info.hasCompletedOnboarding ? 'Oui' : 'Non',
              'Expérience HYROX': info.hyroxExperience ? HYROX_EXPERIENCE_LABELS[info.hyroxExperience] : '—',
              'A déjà participé à HYROX': info.hasCompetedHyrox !== undefined ? (info.hasCompetedHyrox ? 'Oui' : 'Non') : '—',
              'Objectif principal': info.primaryGoal ? HYROX_GOAL_LABELS[info.primaryGoal] : '—',
              'Fréquence actuelle': info.currentTrainingFrequency ? TRAINING_FREQUENCY_LABELS[info.currentTrainingFrequency] : '—',
              "Types d'entraînement": info.trainingTypes?.length ? info.trainingTypes.join(', ') : '—',
              'Niveau de forme': info.fitnessLevel !== undefined ? info.fitnessLevel.toString() : '—',
              'Blessures / limitations': info.injuriesLimitations || '—',
              "À l'aise avec stations HYROX": info.familiarWithHyroxStations !== undefined ? (info.familiarWithHyroxStations ? 'Oui' : 'Non') : '—',
              'Exercices difficiles': info.difficultExercises?.length ? info.difficultExercises.join(', ') : '—',
              'Accès à une salle': info.hasGymAccess !== undefined ? (info.hasGymAccess ? 'Oui' : 'Non') : '—',
              'Nom de la salle': info.gymName || '—',
              'Localisation salle': info.gymLocation || '—',
              'Équipement dispo': info.availableEquipment?.length ? info.availableEquipment.join(', ') : '—',
              'Fréquence souhaitée': info.preferredTrainingFrequency ? TRAINING_FREQUENCY_LABELS[info.preferredTrainingFrequency] : '—',
              'Durée séance souhaitée': info.preferredSessionDuration ? SESSION_DURATION_LABELS[info.preferredSessionDuration] : '—',
              'Compétition cible': info.targetCompetitionDate ? new Date(info.targetCompetitionDate).toLocaleDateString('fr-FR') : '—',
              "Heure d'entraînement préférée": info.preferredTrainingTime ? TRAINING_TIME_LABELS[info.preferredTrainingTime] : '—',
              'Intensité préférée': info.preferredIntensity ? TRAINING_INTENSITY_LABELS[info.preferredIntensity] : '—',
              'Programme structuré ?': info.prefersStructuredProgram !== undefined ? (info.prefersStructuredProgram ? 'Oui' : 'Non') : '—',
              'Notifications ?': info.wantsNotifications !== undefined ? (info.wantsNotifications ? 'Oui' : 'Non') : '—',
              'Créé le': info.createdAt ? new Date(info.createdAt).toLocaleDateString('fr-FR') : '—',
              'Mis à jour le': info.updatedAt ? new Date(info.updatedAt).toLocaleDateString('fr-FR') : '—',
              'Onboarding complété le': info.completedAt ? new Date(info.completedAt).toLocaleDateString('fr-FR') : '—',
            }).map(([label, value]) => (
              <div key={label} className="bg-white rounded-lg shadow p-4">
                <p className="text-sm text-gray-500">{label}</p>
                <p className="font-medium text-gray-900 break-words">{value}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      <Link
        href="/coach/athletes"
        className="text-blue-600 underline mt-6 inline-block"
      >
        ← Retour à la liste
      </Link>
    </div>
  );
} 