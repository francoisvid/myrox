'use client';

import Link from 'next/link';
import { ClockIcon, AdjustmentsHorizontalIcon, PencilIcon, TrashIcon } from '@heroicons/react/24/outline';
import { useTemplates } from '@/hooks/useTemplates';

export default function TemplatesPage() {
  const { templates, loading, error, deleteTemplate } = useTemplates();

  const handleDelete = async (templateId: string) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer ce modèle ?')) {
      return;
    }

    try {
      await deleteTemplate(templateId);
      alert('Modèle supprimé avec succès !');
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
      alert('Erreur lors de la suppression du modèle');
    }
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'BEGINNER':
        return 'bg-green-100 text-green-800';
      case 'INTERMEDIATE':
        return 'bg-yellow-100 text-yellow-800';
      case 'ADVANCED':
        return 'bg-orange-100 text-orange-800';
      case 'EXPERT':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getDifficultyLabel = (difficulty: string) => {
    switch (difficulty) {
      case 'BEGINNER':
        return 'Débutant';
      case 'INTERMEDIATE':
        return 'Intermédiaire';
      case 'ADVANCED':
        return 'Avancé';
      case 'EXPERT':
        return 'Expert';
      default:
        return difficulty;
    }
  };

  const getCategoryLabel = (category: string) => {
    switch (category) {
      case 'HYROX':
        return 'HYROX';
      case 'STRENGTH':
        return 'Musculation';
      case 'CARDIO':
        return 'Cardio';
      case 'FUNCTIONAL':
        return 'Fonctionnel';
      case 'FLEXIBILITY':
        return 'Souplesse';
      case 'MIXED':
        return 'Mixte';
      default:
        return category;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Chargement des modèles...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-xl mb-4">❌ Erreur</div>
          <p className="text-gray-600">{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row justify-between">
            <div className="flex-1 min-w-0">
              <h1 className="text-3xl font-bold text-gray-900">
                Modèle d'entraînement
              </h1>
              <p className="mt-1 text-sm text-gray-500">
                Gérez les modèles d'entraînement pour vos athlètes.
              </p>
            </div>
            <div className="flex items-center justify-between mt-4 md:mt-0 md:justify-end w-full md:w-auto space-x-4">
              <span className="text-sm text-gray-500">
                {templates.length} modèle{templates.length > 1 ? 's' : ''}
              </span>
              <Link
                href="/templates/new"
                className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              >
                Nouveau modèle
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto py-6 px-6 sm:px-6 lg:px-8">
        {templates.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-gray-400 text-6xl mb-4">📝</div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">Aucun modèle trouvé</h3>
            <p className="text-gray-500">Créez votre premier modèle d'entraînement !</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {templates.map((template) => (
              <div key={template.id} className="bg-white rounded-lg shadow hover:shadow-md transition-shadow duration-200">

                <div className="p-6">
                  {/* En-tête du template */}
                  {/* Actions */}
                  <div className="flex justify-end space-x-2 mb-2 ">
                    <Link
                      href={`/templates/${template.id}/edit`}
                      className="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded"
                      title="Modifier"
                    >
                      <PencilIcon className="w-4 h-4" />
                    </Link>
                    <button
                      onClick={() => handleDelete(template.id)}
                      className="p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded"
                      title="Supprimer"
                    >
                      <TrashIcon className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="flex justify-between items-start mb-4">
                    <h3 className="text-lg font-semibold text-gray-900 truncate">
                      {template.name}
                    </h3>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getDifficultyColor(template.difficulty)}`}>
                      {getDifficultyLabel(template.difficulty)}
                    </span>
                  </div>

                  {/* Description */}
                  {template.description && (
                    <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                      {template.description}
                    </p>
                  )}

                  {/* Méta-informations */}
                  <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                    <div className="flex items-center">
                      <ClockIcon className="h-4 w-4 mr-1" />
                      {template.estimatedTime} min
                    </div>
                    <div className="flex items-center">
                      <AdjustmentsHorizontalIcon className="h-4 w-4 mr-1" />
                      {template.rounds} round{template.rounds > 1 ? 's' : ''}
                    </div>
                  </div>

                  {/* Catégorie */}
                  <div className="mb-4">
                    <span className="inline-block bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">
                      {getCategoryLabel(template.category)}
                    </span>
                  </div>

                  {/* Exercices */}
                  <div className="border-t pt-4 min-h-[170px]">
                    <h4 className="font-medium text-gray-900 mb-2">
                      Exercices ({template.exercises?.length || 0})
                    </h4>
                    <div className="space-y-2">
                      {template.exercises?.slice(0, 4).map((exercise, index) => (
                        <div key={exercise.id} className="flex items-center justify-between">
                          <div className="flex-1">
                            <span className="text-sm text-gray-600">
                              {index + 1}. {exercise.exercise?.name || 'Exercice'}
                            </span>
                          </div>
                          <div className="flex gap-1 ml-2">
                            {exercise.distance && exercise.distance > 0 && (
                              <span className="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                                📏 {exercise.distance}m
                              </span>
                            )}
                            {exercise.reps && exercise.reps > 0 && (
                              <span className="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                                🔄 {exercise.reps}
                              </span>
                            )}
                            {(!exercise.distance || exercise.distance === 0) && (!exercise.reps || exercise.reps === 0) && (
                              <span className="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800">
                                ⏰ temps
                              </span>
                            )}
                          </div>
                        </div>
                      ))}
                      {template.exercises && template.exercises.length > 4 && (
                        <div className="text-sm text-gray-500">
                          ... et {template.exercises.length - 3} autre{template.exercises.length - 3 > 1 ? 's' : ''}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Date de création */}
                  <div className="mt-4 pt-4 border-t text-xs text-gray-400 justify-end flex">
                    Créé le {new Date(template.createdAt).toLocaleDateString('fr-FR')}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
