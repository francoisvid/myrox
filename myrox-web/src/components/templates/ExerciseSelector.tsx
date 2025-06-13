'use client';

import { useState } from 'react';
import { MagnifyingGlassIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { Exercise } from '@/types';

interface ExerciseSelectorProps {
  exercises: Exercise[];
  onExerciseSelect: (exercise: Exercise) => void;
}

const categoryIcons = {
  HYROX_STATION: '🏆',
  CARDIO: '❤️',
  STRENGTH: '💪',
  FUNCTIONAL: '🔄',
  RUNNING: '🏃',
  CORE: '🎯',
  PLYOMETRIC: '⚡',
} as const;

const categoryLabels = {
  HYROX_STATION: 'HYROX',
  CARDIO: 'Cardio',
  STRENGTH: 'Force',
  FUNCTIONAL: 'Fonctionnel',
  RUNNING: 'Course',
  CORE: 'Core',
  PLYOMETRIC: 'Pliométrie',
} as const;

export default function ExerciseSelector({ exercises, onExerciseSelect }: ExerciseSelectorProps) {
  const [searchText, setSearchText] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('Tous');

  const categories = ['Tous', ...Object.keys(categoryLabels)];

  const filteredExercises = exercises.filter(exercise => {
    // Filtre par catégorie
    if (selectedCategory !== 'Tous' && exercise.category !== selectedCategory) {
      return false;
    }

    // Filtre par recherche
    if (searchText) {
      const searchLower = searchText.toLowerCase();
      return (
        exercise.name.toLowerCase().includes(searchLower) ||
        exercise.description?.toLowerCase().includes(searchLower) ||
        exercise.category.toLowerCase().includes(searchLower)
      );
    }

    return true;
  }).sort((a, b) => a.name.localeCompare(b.name));

  return (
    <div className="space-y-4">
      {/* Barre de recherche */}
      <div className="relative">
        <input
          type="text"
          placeholder="Rechercher un exercice..."
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          className="block w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
        />
        {searchText && (
          <div className="absolute inset-y-0 right-0 pr-3 flex items-center">
            <button
              onClick={() => setSearchText('')}
              className="text-gray-400 hover:text-gray-600"
            >
              <XMarkIcon className="h-5 w-5" />
            </button>
          </div>
        )}
      </div>

      {/* Filtres par catégorie */}
      <div className="flex flex-wrap gap-2">
        {categories.map((category) => (
          <button
            key={category}
            onClick={() => setSelectedCategory(category)}
            className={`inline-flex items-center px-3 py-2 rounded-full text-sm font-medium transition-colors ${
              selectedCategory === category
                ? 'bg-blue-100 text-blue-800 border border-blue-200'
                : 'bg-gray-100 text-gray-700 border border-gray-200 hover:bg-gray-200'
            }`}
          >
            {category !== 'Tous' && (
              <span className="mr-1">
                {categoryIcons[category as keyof typeof categoryIcons]}
              </span>
            )}
            {category === 'Tous' ? 'Tous' : categoryLabels[category as keyof typeof categoryLabels]}
          </button>
        ))}
      </div>

      {/* Liste des exercices */}
      <div className="space-y-2 max-h-96 overflow-y-auto">
        {filteredExercises.length === 0 ? (
          <div className="text-center py-8">
            <MagnifyingGlassIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Aucun exercice trouvé</h3>
            <p className="mt-1 text-sm text-gray-500">
              Essayez de modifier votre recherche ou sélectionner une autre catégorie.
            </p>
          </div>
        ) : (
          filteredExercises.map((exercise) => (
            <div
              key={exercise.id}
              onClick={() => onExerciseSelect(exercise)}
              className="border border-gray-200 rounded-lg p-4 hover:border-blue-300 hover:bg-blue-50 cursor-pointer transition-all duration-200"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center space-x-2">
                    <h3 className="text-sm font-medium text-gray-900 truncate">
                      {exercise.name}
                    </h3>
                    {exercise.isHyroxExercise && (
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800">
                        HYROX
                      </span>
                    )}
                  </div>
                  
                  {exercise.description && (
                    <p className="mt-1 text-sm text-gray-500 line-clamp-2">
                      {exercise.description}
                    </p>
                  )}
                  
                  <div className="mt-2 flex items-center space-x-4 text-xs text-gray-500">
                    <span className="inline-flex items-center">
                      <span className="mr-1">
                        {categoryIcons[exercise.category as keyof typeof categoryIcons] || '📋'}
                      </span>
                      {categoryLabels[exercise.category as keyof typeof categoryLabels] || exercise.category}
                    </span>
                    
                    {exercise.equipment && exercise.equipment.length > 0 && (
                      <span>
                        🛠️ {exercise.equipment.join(', ')}
                      </span>
                    )}
                  </div>
                </div>
                
                <div className="ml-4 flex-shrink-0">
                  <button className="text-blue-600 hover:text-blue-800 font-medium text-sm">
                    Sélectionner
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
} 