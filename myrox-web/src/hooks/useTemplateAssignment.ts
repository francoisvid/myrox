'use client';

import { useState, useCallback } from 'react';
import { templatesApi } from '@/lib/api';

export const useTemplateAssignment = () => {
  const [isAssigning, setIsAssigning] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const assignTemplate = useCallback(async (templateId: string, userIds: string[]) => {
    try {
      setIsAssigning(true);
      setError(null);
      
      console.log('🎯 Assignation template:', { templateId, userIds });
      await templatesApi.assignTemplate(templateId, userIds);
      
      console.log('✅ Template assigné avec succès');
      return true;
    } catch (err) {
      console.error('❌ Erreur assignation template:', err);
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'assignation');
      return false;
    } finally {
      setIsAssigning(false);
    }
  }, []);

  const unassignTemplate = useCallback(async (templateId: string, userId: string) => {
    try {
      setIsAssigning(true);
      setError(null);
      
      console.log('🎯 Désassignation template:', { templateId, userId });
      await templatesApi.unassignTemplate(templateId, userId);
      
      console.log('✅ Template désassigné avec succès');
      return true;
    } catch (err) {
      console.error('❌ Erreur désassignation template:', err);
      setError(err instanceof Error ? err.message : 'Erreur lors de la désassignation');
      return false;
    } finally {
      setIsAssigning(false);
    }
  }, []);

  const assignTemplateToMultipleUsers = useCallback(async (templateId: string, userIds: string[]) => {
    return await assignTemplate(templateId, userIds);
  }, [assignTemplate]);

  const assignMultipleTemplatesToUser = useCallback(async (templateIds: string[], userId: string) => {
    try {
      setIsAssigning(true);
      setError(null);
      
      const results = await Promise.allSettled(
        templateIds.map(templateId => templatesApi.assignTemplate(templateId, [userId]))
      );
      
      const failures = results.filter(result => result.status === 'rejected');
      
      if (failures.length > 0) {
        throw new Error(`${failures.length} assignation(s) ont échoué`);
      }
      
      console.log('✅ Tous les templates ont été assignés');
      return true;
    } catch (err) {
      console.error('❌ Erreur assignation multiple:', err);
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'assignation multiple');
      return false;
    } finally {
      setIsAssigning(false);
    }
  }, []);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  return {
    isAssigning,
    error,
    assignTemplate,
    unassignTemplate,
    assignTemplateToMultipleUsers,
    assignMultipleTemplatesToUser,
    clearError
  };
}; 