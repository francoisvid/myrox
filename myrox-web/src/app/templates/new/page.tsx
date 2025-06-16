'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTemplates } from '@/hooks/useTemplates';
import { useExercises } from '@/hooks/useExercises';
import { PlusIcon, MinusIcon } from '@heroicons/react/24/outline';
import { Exercise, TemplateExercise } from '@/types';
import ExerciseSelector from '@/components/templates/ExerciseSelector';
import ExerciseConfiguration from '@/components/templates/ExerciseConfiguration';
import ConfiguredExerciseCard from '@/components/templates/ConfiguredExerciseCard';

export default function CreateTemplatePage() {
  const router = useRouter();
  const { createTemplate, isCreating } = useTemplates();
  const { exercises, loading: exercisesLoading } = useExercises();

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [rounds, setRounds] = useState(1);
  const [selectedExercises, setSelectedExercises] = useState<TemplateExercise[]>([]);
  const [showExerciseSelector, setShowExerciseSelector] = useState(false);
  const [showExerciseConfig, setShowExerciseConfig] = useState(false);
  const [selectedExerciseForConfig, setSelectedExerciseForConfig] = useState<Exercise | null>(null);
  const [editingExercise, setEditingExercise] = useState<TemplateExercise | null>(null);

  const handleCreateTemplate = async () => {
    if (!name.trim() || selectedExercises.length === 0) {
      alert('Veuillez remplir le nom et ajouter au moins un exercice');
      return;
    }

    try {
      await createTemplate({
        name: name.trim(),
        description: description.trim() || undefined,
        rounds,
        exercises: selectedExercises,
        coachId: undefined, // Template personnel
      });

      router.push('/templates');
    } catch (error) {
      console.error('Erreur lors de la création:', error);
      alert('Erreur lors de la création du template');
    }
  };

  const handleExerciseSelect = (exercise: Exercise) => {
    setSelectedExerciseForConfig(exercise);
    setShowExerciseSelector(false);
    setShowExerciseConfig(true);
  };

  const handleExerciseConfigSave = (exerciseConfig: Omit<TemplateExercise, 'id' | 'templateId'>) => {
    if (editingExercise) {
      // Mode édition
      const updated = selectedExercises.map(ex =>
        ex.id === editingExercise.id
          ? {
              ...exerciseConfig,
              id: ex.id,
              templateId: ex.templateId,
              order: ex.order
            }
          : ex
      );
      setSelectedExercises(updated);
      setEditingExercise(null);
    } else {
      // Mode ajout
      const newExercise: TemplateExercise = {
        ...exerciseConfig,
        id: `temp-${Date.now()}`,
        templateId: '',
        order: selectedExercises.length,
      };
      setSelectedExercises([...selectedExercises, newExercise]);
    }

    setShowExerciseConfig(false);
    setSelectedExerciseForConfig(null);
  };

  const handleExerciseEdit = (templateExercise: TemplateExercise) => {
    setEditingExercise(templateExercise);
    setSelectedExerciseForConfig(templateExercise.exercise!);
    setShowExerciseConfig(true);
  };

  const handleExerciseRemove = (templateExercise: TemplateExercise) => {
    const updated = selectedExercises.filter(ex => ex.id !== templateExercise.id);
    // Réorganiser les ordres
    const reordered = updated.map((ex, i) => ({ ...ex, order: i }));
    setSelectedExercises(reordered);
  };

  const handleCancel = () => {
    setShowExerciseConfig(false);
    setShowExerciseSelector(false);
    setSelectedExerciseForConfig(null);
    setEditingExercise(null);
  };

  if (exercisesLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Chargement des exercices...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex flex-col space-x-4">
              <Link href="/templates" className="mb-3 text-blue-600 hover:text-blue-800">
                ← Retour aux templates
              </Link>
              <h1 className="text-3xl font-bold text-gray-900">Nouveau Template</h1>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <div className="bg-white shadow-sm rounded-lg">
          <div className="px-6 py-4 border-b border-gray-200">
            <p className="text-sm text-gray-600">
              Configurez votre template d'entraînement personnalisé avec {exercises.length} exercices disponibles
            </p>
          </div>

          <div className="p-6 space-y-6">
            {/* Informations de base */}
            <div className="flex flex-col justify-between items-center gap-4 sm:flex-row">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nom du template *
                </label>
                <input
                  type="text"
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  placeholder="Ex: HYROX Complet"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nombre de rounds
                </label>
                <div className="flex items-center space-x-3">
                  <button
                    type="button"
                    onClick={() => setRounds(Math.max(1, rounds - 1))}
                    className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-gray-600 hover:bg-gray-300 disabled:opacity-50"
                    disabled={rounds <= 1}
                  >
                    <MinusIcon className="h-4 w-4" />
                  </button>
                  <span className="text-xl font-bold text-blue-600 w-12 text-center">{rounds}</span>
                  <button
                    type="button"
                    onClick={() => setRounds(rounds + 1)}
                    className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-gray-600 hover:bg-gray-300"
                  >
                    <PlusIcon className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>

            <div>
              <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                Description
              </label>
              <textarea
                id="description"
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="Description de l'entraînement..."
              />
            </div>

            {/* Exercices configurés */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-medium text-gray-900">
                  Exercices configurés ({selectedExercises.length})
                </h3>
                <button
                  type="button"
                  onClick={() => setShowExerciseSelector(true)}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                >
                  <PlusIcon className="h-4 w-4 mr-2" />
                  Ajouter un exercice
                </button>
              </div>

              {selectedExercises.length === 0 ? (
                <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
                  <div className="text-6xl mb-4">🏋️‍♂️</div>
                  <h3 className="text-lg font-medium text-gray-900 mb-2">Aucun exercice configuré</h3>
                  <p className="text-gray-500 mb-4">Ajoutez des exercices avec leurs paramètres pour créer votre template</p>
                  <button
                    type="button"
                    onClick={() => setShowExerciseSelector(true)}
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    <PlusIcon className="h-4 w-4 mr-2" />
                    Commencer
                  </button>
                </div>
              ) : (
                <div className="space-y-4">
                  {selectedExercises
                    .sort((a, b) => a.order - b.order)
                    .map((templateExercise, index) => (
                      <ConfiguredExerciseCard
                        key={templateExercise.id}
                        templateExercise={templateExercise}
                        position={index + 1}
                        onEdit={handleExerciseEdit}
                        onRemove={handleExerciseRemove}
                      />
                    ))
                  }
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="flex justify-end space-x-3 pt-6 border-t border-gray-200">
              <button
                type="button"
                onClick={() => router.push('/templates')}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Annuler
              </button>
              <button
                type="button"
                onClick={handleCreateTemplate}
                disabled={isCreating || !name.trim() || selectedExercises.length === 0}
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isCreating ? 'Création...' : 'Créer le template'}
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* Modales */}
      {showExerciseSelector && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={handleCancel} />
            <div className="relative bg-white rounded-lg p-6 max-w-4xl w-full max-h-[80vh] overflow-hidden">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold text-gray-900">Choisir un exercice</h2>
                <button
                  onClick={handleCancel}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
              <div className="overflow-y-auto max-h-[60vh]">
                <ExerciseSelector
                  exercises={exercises}
                  onExerciseSelect={handleExerciseSelect}
                />
              </div>
            </div>
          </div>
        </div>
      )}

      {showExerciseConfig && selectedExerciseForConfig && (
        <ExerciseConfiguration
          exercise={selectedExerciseForConfig}
          existingConfig={editingExercise ? {
            order: editingExercise.order,
            exerciseId: editingExercise.exerciseId,
            sets: editingExercise.sets,
            reps: editingExercise.reps,
            duration: editingExercise.duration,
            distance: editingExercise.distance,
            weight: editingExercise.weight,
            restTime: editingExercise.restTime,
            notes: editingExercise.notes,
            exercise: editingExercise.exercise,
          } : undefined}
          onSave={handleExerciseConfigSave}
          onCancel={handleCancel}
        />
      )}
    </div>
  );
}
