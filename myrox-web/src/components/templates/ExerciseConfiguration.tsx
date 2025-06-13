'use client';

import { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import { Exercise, TemplateExercise } from '@/types';

interface ExerciseConfigurationProps {
  exercise: Exercise;
  onSave: (exerciseConfig: Omit<TemplateExercise, 'id' | 'templateId'>) => void;
  onCancel: () => void;
  existingConfig?: Omit<TemplateExercise, 'id' | 'templateId'>;
}

export default function ExerciseConfiguration({ 
  exercise, 
  onSave, 
  onCancel, 
  existingConfig 
}: ExerciseConfigurationProps) {
  const [config, setConfig] = useState({
    distance: existingConfig?.distance || 0,
    reps: existingConfig?.reps || 0,
    duration: existingConfig?.duration || 0,
    weight: existingConfig?.weight || 0,
    restTime: existingConfig?.restTime || null, // Null par défaut
    notes: existingConfig?.notes || '',
  });

  const [activeParams, setActiveParams] = useState({
    hasDistance: !!(existingConfig?.distance && existingConfig.distance > 0),
    hasReps: !!(existingConfig?.reps && existingConfig.reps > 0),
    hasDuration: !!(existingConfig?.duration && existingConfig.duration > 0),
    hasWeight: !!(existingConfig?.weight && existingConfig.weight > 0),
  });

  // Valeurs par défaut basées sur l'exercice
  const getDefaultValue = (param: 'distance' | 'reps' | 'duration') => {
    switch (param) {
      case 'distance':
        if (exercise.category === 'RUNNING') return 1000;
        if (exercise.name.toLowerCase().includes('ski')) return 250;
        if (exercise.name.toLowerCase().includes('row')) return 250;
        return 500;
      case 'reps':
        if (exercise.category === 'STRENGTH') return 10;
        if (exercise.category === 'FUNCTIONAL') return 20;
        return 15;
      case 'duration':
        return 60;
      default:
        return 0;
    }
  };

  useEffect(() => {
    // Auto-activer les paramètres basés sur la catégorie d'exercice
    if (!existingConfig) {
      const newActiveParams = { ...activeParams };
      
      if (['RUNNING', 'HYROX_STATION'].includes(exercise.category) && 
          exercise.name.toLowerCase().includes('run')) {
        newActiveParams.hasDistance = true;
        setConfig(prev => ({ ...prev, distance: getDefaultValue('distance') }));
      }
      
      if (['STRENGTH', 'FUNCTIONAL'].includes(exercise.category)) {
        newActiveParams.hasReps = true;
        setConfig(prev => ({ ...prev, reps: getDefaultValue('reps') }));
      }

      setActiveParams(newActiveParams);
    }
  }, [exercise]);

  const toggleParameter = (param: keyof typeof activeParams) => {
    const newActiveParams = { ...activeParams, [param]: !activeParams[param] };
    setActiveParams(newActiveParams);

    if (newActiveParams[param]) {
      // Activer le paramètre avec une valeur par défaut
      const paramName = param.replace('has', '').toLowerCase() as 'distance' | 'reps' | 'duration' | 'weight';
      if (paramName !== 'weight') {
        setConfig(prev => ({ 
          ...prev, 
          [paramName]: getDefaultValue(paramName as 'distance' | 'reps' | 'duration')
        }));
      } else {
        setConfig(prev => ({ ...prev, weight: 20 }));
      }
    } else {
      // Désactiver le paramètre
      const paramName = param.replace('has', '').toLowerCase();
      setConfig(prev => ({ ...prev, [paramName]: 0 }));
    }
  };

  const handleSave = () => {
    const order = 0; // Sera recalculé par le parent
    
    console.log('💾 Sauvegarde de la configuration exercice:', {
      exerciseName: exercise.name,
      hasReps: activeParams.hasReps,
      repsValue: config.reps,
      hasDistance: activeParams.hasDistance, 
      distanceValue: config.distance,
      hasDuration: activeParams.hasDuration,
      durationValue: config.duration,
      hasWeight: activeParams.hasWeight,
      weightValue: config.weight
    });
    
    const exerciseConfig: Omit<TemplateExercise, 'id' | 'templateId'> = {
      order,
      exerciseId: exercise.id,
      sets: 1, // Valeur fixe, pas d'interface pour modifier
      reps: activeParams.hasReps && config.reps > 0 ? config.reps : undefined,
      duration: activeParams.hasDuration && config.duration > 0 ? config.duration : undefined,
      distance: activeParams.hasDistance && config.distance > 0 ? config.distance : undefined,
      weight: activeParams.hasWeight && config.weight > 0 ? config.weight : undefined,
      restTime: config.restTime || undefined,
      notes: config.notes || undefined,
      exercise: exercise,
    };

    console.log('✅ Configuration finale:', exerciseConfig);
    onSave(exerciseConfig);
  };

  const getPreview = () => {
    const parts: string[] = [exercise.name];
    
    if (activeParams.hasDistance && config.distance > 0) {
      parts.push(`${config.distance}m`);
    }
    if (activeParams.hasReps && config.reps > 0) {
      parts.push(`${config.reps} reps`);
    }
    if (activeParams.hasDuration && config.duration > 0) {
      parts.push(`${config.duration}s`);
    }
    if (activeParams.hasWeight && config.weight > 0) {
      parts.push(`${config.weight}kg`);
    }
    if (!activeParams.hasDistance && !activeParams.hasReps && !activeParams.hasDuration) {
      parts.push('temps libre');
    }

    return parts.join(' • ');
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={onCancel} />
        
        <div className="relative bg-white rounded-lg p-6 max-w-lg w-full shadow-xl">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Configurer l'exercice</h3>
              <h4 className="text-xl font-bold text-blue-600 mt-1">{exercise.name}</h4>
            </div>
            <button onClick={onCancel} className="text-gray-400 hover:text-gray-600">
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          <div className="space-y-4">

            <div>
              <label className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={activeParams.hasReps}
                  onChange={(e) => toggleParameter('hasReps')}
                  className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm font-medium text-gray-700">Répétitions</span>
              </label>
              {activeParams.hasReps && (
                <input
                  type="number"
                  value={config.reps}
                  onChange={(e) => setConfig(prev => ({ ...prev, reps: Number(e.target.value) }))}
                  className="mt-2 w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  min="0"
                />
              )}
            </div>

            <div>
              <label className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={activeParams.hasDistance}
                  onChange={(e) => toggleParameter('hasDistance')}
                  className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm font-medium text-gray-700">Distance (m)</span>
              </label>
              {activeParams.hasDistance && (
                <input
                  type="number"
                  value={config.distance}
                  onChange={(e) => setConfig(prev => ({ ...prev, distance: Number(e.target.value) }))}
                  className="mt-2 w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  min="0"
                />
              )}
            </div>

            <div>
              <label className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={activeParams.hasDuration}
                  onChange={(e) => toggleParameter('hasDuration')}
                  className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm font-medium text-gray-700">Durée (s)</span>
              </label>
              {activeParams.hasDuration && (
                <input
                  type="number"
                  value={config.duration}
                  onChange={(e) => setConfig(prev => ({ ...prev, duration: Number(e.target.value) }))}
                  className="mt-2 w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  min="0"
                />
              )}
            </div>

            <div>
              <label className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={activeParams.hasWeight}
                  onChange={(e) => toggleParameter('hasWeight')}
                  className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm font-medium text-gray-700">Poids (kg)</span>
              </label>
              {activeParams.hasWeight && (
                <input
                  type="number"
                  value={config.weight}
                  onChange={(e) => setConfig(prev => ({ ...prev, weight: Number(e.target.value) }))}
                  className="mt-2 w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  min="0"
                />
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Temps de repos (s)</label>
              <input
                type="number"
                value={config.restTime || ''}
                onChange={(e) => setConfig(prev => ({ 
                  ...prev, 
                  restTime: e.target.value === '' ? null : Number(e.target.value) 
                }))}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                min="0"
                placeholder="Temps de repos en secondes"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Notes (optionnel)</label>
              <textarea
                value={config.notes}
                onChange={(e) => setConfig(prev => ({ ...prev, notes: e.target.value }))}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                rows={3}
                placeholder="Ajoutez des notes pour cet exercice..."
              />
            </div>

            <div className="p-3 bg-gray-50 rounded-md">
              <p className="text-sm font-medium text-gray-700 mb-1">Aperçu :</p>
              <p className="text-sm text-gray-600">{getPreview()}</p>
            </div>

            <div className="flex space-x-3 pt-4">
              <button
                onClick={onCancel}
                className="flex-1 bg-gray-200 text-gray-800 py-2 px-4 rounded-md hover:bg-gray-300"
              >
                Annuler
              </button>
              <button
                onClick={handleSave}
                className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700"
              >
                Ajouter
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 