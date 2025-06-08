'use client';

import { useState, useEffect } from 'react';
import { User, Template } from '@/types';
import { useTemplateAssignment } from '@/hooks/useTemplateAssignment';
import { coachesApi, templatesApi } from '@/lib/api';
import { config } from '@/lib/config';
import { TrashIcon, UserGroupIcon, DocumentTextIcon } from '@heroicons/react/24/outline';

interface AssignedTemplate {
  template: Template;
  assignedUsers: User[];
}

interface TemplateAssignmentManagerProps {
  coachId: string;
  onUpdate?: () => void;
}

export default function TemplateAssignmentManager({ coachId, onUpdate }: TemplateAssignmentManagerProps) {
  const [assignedTemplates, setAssignedTemplates] = useState<AssignedTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { unassignTemplate, isAssigning } = useTemplateAssignment();

  const loadAssignments = async () => {
    try {
      setLoading(true);
      setError(null);

      // Récupérer tous les templates du coach
      const templates = await templatesApi.getTemplates(coachId);
      
      console.log('🔍 Templates récupérés:', templates.length);
      
      // Pour chaque template, récupérer les assignations
      const assignedTemplatesData: AssignedTemplate[] = [];
      
      for (const template of templates) {
        try {
          const response = await fetch(`${config.api.baseUrl}/api/v1/templates/${template.id}/assignments`, {
            headers: {
              'x-firebase-uid': config.defaults.firebaseUID,
              'X-Client-Type': 'web'
            }
          });
          
          console.log(`🔍 Template ${template.name}: Response status ${response.status}`);
          
          if (response.ok) {
            const assignedUsers = await response.json();
            if (assignedUsers.length > 0) {
              assignedTemplatesData.push({
                template,
                assignedUsers: assignedUsers.map((user: any) => ({
                  id: user.userId,
                  email: user.email,
                  displayName: user.displayName,
                  assignedAt: user.assignedAt
                }))
              });
            }
          }
        } catch (err) {
          console.warn(`Erreur lors de la récupération des assignations pour ${template.name}:`, err);
        }
      }

      setAssignedTemplates(assignedTemplatesData);
    } catch (err) {
      console.error('Erreur lors du chargement des assignations:', err);
      setError('Erreur lors du chargement des assignations');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAssignments();
  }, [coachId]);

  const handleUnassign = async (templateId: string, userId: string, userName: string, templateName: string) => {
    if (!confirm(`Êtes-vous sûr de vouloir désassigner le template "${templateName}" de ${userName} ?`)) {
      return;
    }

    const success = await unassignTemplate(templateId, userId);
    if (success) {
      await loadAssignments(); // Recharger les données
      onUpdate?.();
    }
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty?.toLowerCase()) {
      case 'facile': return 'bg-green-100 text-green-800';
      case 'moyen': return 'bg-yellow-100 text-yellow-800';
      case 'difficile': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category?.toUpperCase()) {
      case 'HYROX': return '🏃‍♂️';
      case 'CARDIO': return '❤️';
      case 'STRENGTH': return '💪';
      case 'FUNCTIONAL': return '⚡';
      default: return '📋';
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2 text-gray-600">Chargement des assignations...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-md p-4">
        <div className="text-red-800 font-medium">Erreur</div>
        <div className="text-red-700 text-sm mt-1">{error}</div>
        <button
          onClick={loadAssignments}
          className="mt-2 text-sm text-red-600 hover:text-red-800 underline"
        >
          Réessayer
        </button>
      </div>
    );
  }

  if (assignedTemplates.length === 0) {
    return (
      <div className="text-center py-12">
        <DocumentTextIcon className="mx-auto h-12 w-12 text-gray-400" />
        <h3 className="mt-2 text-sm font-medium text-gray-900">Aucune assignation</h3>
        <p className="mt-1 text-sm text-gray-500">
          Vous n'avez encore assigné aucun template à vos athlètes.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900 flex items-center">
            <UserGroupIcon className="h-5 w-5 mr-2 text-blue-600" />
            Gestion des Assignations
          </h3>
          <p className="mt-1 text-sm text-gray-500">
            Gérez les templates assignés à vos athlètes.
          </p>
        </div>
      </div>

      <div className="space-y-4">
        {assignedTemplates.map(({ template, assignedUsers }) => (
          <div key={template.id} className="bg-white shadow rounded-lg overflow-hidden">
            <div className="px-4 py-5 sm:px-6 bg-gray-50 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <span className="text-2xl mr-3">{getCategoryIcon(template.category)}</span>
                  <div>
                    <h4 className="text-lg font-medium text-gray-900">{template.name}</h4>
                    <div className="flex items-center space-x-3 mt-1">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getDifficultyColor(template.difficulty)}`}>
                        {template.difficulty}
                      </span>
                                             <span className="text-sm text-gray-500">
                         {template.exercises?.length || 0} exercice{(template.exercises?.length || 0) > 1 ? 's' : ''}
                       </span>
                       <span className="text-sm text-gray-500">
                         ~{template.estimatedTime || 0}min
                       </span>
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-sm font-medium text-gray-900">
                    {assignedUsers.length} athlète{assignedUsers.length > 1 ? 's' : ''}
                  </span>
                </div>
              </div>
            </div>

            <div className="px-4 py-4">
              <div className="space-y-2">
                {assignedUsers.map((user) => (
                  <div
                    key={user.id}
                    className="flex items-center justify-between py-2 px-3 bg-gray-50 rounded-md"
                  >
                    <div className="flex items-center">
                      <div className="h-8 w-8 bg-blue-100 rounded-full flex items-center justify-center">
                                               <span className="text-sm font-medium text-blue-600">
                         {(user.displayName || user.email || 'U').charAt(0).toUpperCase()}
                       </span>
                      </div>
                                             <div className="ml-3">
                         <div className="text-sm font-medium text-gray-900">
                           {user.displayName || 'Utilisateur'}
                         </div>
                         <div className="text-sm text-gray-500">{user.email || ''}</div>
                       </div>
                     </div>
                     <button
                       onClick={() => handleUnassign(template.id, user.id, user.displayName || user.email || 'Utilisateur', template.name)}
                      disabled={isAssigning}
                      className="inline-flex items-center px-3 py-1 border border-red-300 shadow-sm text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
                    >
                      <TrashIcon className="h-4 w-4 mr-1" />
                      Désassigner
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
} 