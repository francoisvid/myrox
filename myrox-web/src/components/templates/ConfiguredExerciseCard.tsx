'use client';

import { TrashIcon, PencilIcon } from '@heroicons/react/24/outline';
import { TemplateExercise } from '@/types';

interface ConfiguredExerciseCardProps {
  templateExercise: TemplateExercise;
  position: number;
  onEdit: (templateExercise: TemplateExercise) => void;
  onRemove: (templateExercise: TemplateExercise) => void;
}

export default function ConfiguredExerciseCard({
  templateExercise,
  position,
  onEdit,
  onRemove
}: ConfiguredExerciseCardProps) {
  const getParametersBadges = () => {
    const badges = [];

    if (templateExercise.sets && templateExercise.sets > 1) {
      badges.push(
        <span key="sets" className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
          <span className="mr-1">🔢</span>
          {templateExercise.sets} séries
        </span>
      );
    }

    if (templateExercise.distance && templateExercise.distance > 0) {
      badges.push(
        <span key="distance" className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
          <span className="mr-1">📏</span>
          {templateExercise.distance}m
        </span>
      );
    }

    if (templateExercise.reps && templateExercise.reps > 0) {
      badges.push(
        <span key="reps" className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
          <span className="mr-1">🔄</span>
          {templateExercise.reps} reps
        </span>
      );
    }

    if (templateExercise.duration && templateExercise.duration > 0) {
      badges.push(
        <span key="duration" className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
          <span className="mr-1">⏱️</span>
          {templateExercise.duration}s
        </span>
      );
    }

    if (templateExercise.weight && templateExercise.weight > 0) {
      badges.push(
        <span key="weight" className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
          <span className="mr-1">🏋️</span>
          {templateExercise.weight}kg
        </span>
      );
    }

    // Si aucun paramètre spécifique, montrer "temps libre"
    if (badges.length === 0 || (badges.length === 1 && badges[0].key === 'sets')) {
      badges.push(
        <span key="time-only" className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
          <span className="mr-1">⏰</span>
          Temps libre
        </span>
      );
    }

    return badges;
  };

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start space-x-4">
        {/* Position */}
        <div className="flex-shrink-0">
          <div className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
            {position}
          </div>
        </div>

        {/* Contenu principal */}
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <h3 className="text-lg font-semibold text-gray-900 mb-1">
                {templateExercise.exercise?.name || `Exercice ${templateExercise.exerciseId}`}
              </h3>
              
              {/* Badges des paramètres */}
              <div className="flex flex-wrap gap-2 mb-2">
                {getParametersBadges()}
              </div>

              {/* Temps de repos */}
              {templateExercise.restTime && templateExercise.restTime > 0 && (
                <div className="text-sm text-gray-600 mb-2">
                  <span className="inline-flex items-center">
                    <span className="mr-1">😴</span>
                    Repos : {templateExercise.restTime}s
                  </span>
                </div>
              )}

              {/* Notes */}
              {templateExercise.notes && (
                <div className="text-sm text-gray-600 bg-gray-50 rounded p-2 mt-2">
                  <span className="font-medium">Note :</span> {templateExercise.notes}
                </div>
              )}

              {/* Catégorie et badge HYROX */}
              <div className="flex items-center space-x-2 mt-2">
                {templateExercise.exercise?.category && (
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                    {templateExercise.exercise.category}
                  </span>
                )}
                {templateExercise.exercise?.isHyroxExercise && (
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                    🏆 HYROX
                  </span>
                )}
              </div>
            </div>

            {/* Actions */}
            <div className="flex space-x-2 ml-4">
              <button
                onClick={() => onEdit(templateExercise)}
                className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-md transition-colors"
                title="Modifier l'exercice"
              >
                <PencilIcon className="h-4 w-4" />
              </button>
              <button
                onClick={() => onRemove(templateExercise)}
                className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-md transition-colors"
                title="Supprimer l'exercice"
              >
                <TrashIcon className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 