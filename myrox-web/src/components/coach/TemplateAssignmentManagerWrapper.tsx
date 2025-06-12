'use client';

import { useCoachId } from '@/hooks/useCoachId';
import TemplateAssignmentManager from './TemplateAssignmentManager';

interface TemplateAssignmentManagerWrapperProps {
  onUpdate?: () => void;
}

export default function TemplateAssignmentManagerWrapper({ onUpdate }: TemplateAssignmentManagerWrapperProps) {
  const { coachId, loading } = useCoachId();

  if (loading) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2 text-gray-600">Chargement...</span>
      </div>
    );
  }

  if (!coachId) {
    return (
      <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4">
        <div className="text-yellow-800 font-medium">Accès restreint</div>
        <div className="text-yellow-700 text-sm mt-1">
          Vous devez être connecté en tant que coach pour accéder à cette fonctionnalité.
        </div>
      </div>
    );
  }

  return (
    <TemplateAssignmentManager 
      coachId={coachId}
      onUpdate={onUpdate}
    />
  );
} 