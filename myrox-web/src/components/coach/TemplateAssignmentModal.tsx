'use client';

import { useState, Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { XMarkIcon, CheckIcon } from '@heroicons/react/24/outline';
import { User, Template } from '@/types';
import { useTemplateAssignment } from '@/hooks/useTemplateAssignment';

interface TemplateAssignmentModalProps {
  isOpen: boolean;
  onClose: () => void;
  selectedAthletes: User[];
  templates: Template[];
  onSuccess: () => void;
}

export default function TemplateAssignmentModal({
  isOpen,
  onClose,
  selectedAthletes,
  templates,
  onSuccess
}: TemplateAssignmentModalProps) {
  const [selectedTemplates, setSelectedTemplates] = useState<string[]>([]);
  const { isAssigning, error, assignTemplateToMultipleUsers, clearError } = useTemplateAssignment();

  const handleTemplateToggle = (templateId: string) => {
    setSelectedTemplates(prev =>
      prev.includes(templateId)
        ? prev.filter(id => id !== templateId)
        : [...prev, templateId]
    );
  };

  const handleAssign = async () => {
    if (selectedTemplates.length === 0 || selectedAthletes.length === 0) return;

    const athleteIds = selectedAthletes.map(athlete => athlete.id);
    let successCount = 0;

    // Assigner chaque template sélectionné à tous les athlètes sélectionnés
    for (const templateId of selectedTemplates) {
      const success = await assignTemplateToMultipleUsers(templateId, athleteIds);
      if (success) successCount++;
    }

    if (successCount === selectedTemplates.length) {
      onSuccess();
    }
  };

  const handleClose = () => {
    setSelectedTemplates([]);
    clearError();
    onClose();
  };

  const getAthleteNames = () => {
    if (selectedAthletes.length <= 2) {
      return selectedAthletes.map(a => a.displayName || a.email).join(' et ');
    }
    return `${selectedAthletes[0].displayName || selectedAthletes[0].email} et ${selectedAthletes.length - 1} autre${selectedAthletes.length > 2 ? 's' : ''}`;
  };

  return (
    <Transition.Root show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={handleClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
        </Transition.Child>

        <div className="fixed inset-0 z-10 overflow-y-auto">
          <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              enterTo="opacity-100 translate-y-0 sm:scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 translate-y-0 sm:scale-100"
              leaveTo="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            >
              <Dialog.Panel className="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-2xl sm:p-6">
                <div className="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
                  <button
                    type="button"
                    className="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                    onClick={handleClose}
                  >
                    <span className="sr-only">Fermer</span>
                    <XMarkIcon className="h-6 w-6" aria-hidden="true" />
                  </button>
                </div>

                <div className="sm:flex sm:items-start">
                  <div className="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left w-full">
                    <Dialog.Title as="h3" className="text-lg font-medium leading-6 text-gray-900">
                      Assigner des templates
                    </Dialog.Title>

                    <div className="mt-4">
                      <p className="text-sm text-gray-500 mb-4">
                        Sélectionnez les templates à assigner à <strong>{getAthleteNames()}</strong>
                      </p>

                      {error && (
                        <div className="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
                          <div className="flex">
                            <div className="ml-3">
                              <h3 className="text-sm font-medium text-red-800">
                                Erreur d'assignation
                              </h3>
                              <div className="mt-2 text-sm text-red-700">
                                {error}
                              </div>
                            </div>
                          </div>
                        </div>
                      )}

                      {/* Liste des templates */}
                      <div className="max-h-96 overflow-y-auto border border-gray-200 rounded-md">
                        {templates.length === 0 ? (
                          <div className="p-8 text-center text-gray-500">
                            <p>Aucun template disponible</p>
                            <p className="text-sm mt-1">Créez d'abord des templates pour pouvoir les assigner.</p>
                          </div>
                        ) : (
                          <div className="divide-y divide-gray-200">
                            {templates.map((template) => (
                              <div
                                key={template.id}
                                className={`p-4 cursor-pointer hover:bg-gray-50 transition-colors ${
                                  selectedTemplates.includes(template.id) ? 'bg-blue-50 border-l-4 border-blue-500' : ''
                                }`}
                                onClick={() => handleTemplateToggle(template.id)}
                              >
                                <div className="flex items-start">
                                  <div className="flex h-5 items-center">
                                    <input
                                      type="checkbox"
                                      checked={selectedTemplates.includes(template.id)}
                                      onChange={() => handleTemplateToggle(template.id)}
                                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                                    />
                                  </div>
                                  <div className="ml-3 flex-1">
                                    <div className="flex items-center justify-between">
                                      <h4 className="text-sm font-medium text-gray-900">
                                        {template.name}
                                      </h4>
                                      <div className="flex gap-2">
                                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                          {template.rounds} round{template.rounds > 1 ? 's' : ''}
                                        </span>
                                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                                          {template.exercises?.length || 0} exercices
                                        </span>
                                      </div>
                                    </div>
                                    {template.description && (
                                      <p className="mt-1 text-sm text-gray-500 line-clamp-2">
                                        {template.description}
                                      </p>
                                    )}
                                    <div className="mt-2 flex items-center gap-3">
                                      <span className="text-xs text-gray-500">
                                        {template.estimatedTime} min
                                      </span>
                                      <span className="text-xs text-gray-500">
                                        {template.category}
                                      </span>
                                      <span className="text-xs text-gray-500">
                                        {template.difficulty}
                                      </span>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>

                      {/* Résumé de l'assignation */}
                      {selectedTemplates.length > 0 && (
                        <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-md">
                          <div className="flex items-center">
                            <CheckIcon className="h-5 w-5 text-green-600 mr-2" />
                            <div className="text-sm">
                              <p className="text-green-800 font-medium">
                                {selectedTemplates.length} template{selectedTemplates.length > 1 ? 's' : ''} sélectionné{selectedTemplates.length > 1 ? 's' : ''}
                              </p>
                              <p className="text-green-700 mt-1">
                                Sera{selectedTemplates.length > 1 ? 'ont' : ''} assigné{selectedTemplates.length > 1 ? 's' : ''} à {selectedAthletes.length} athlète{selectedAthletes.length > 1 ? 's' : ''}
                              </p>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                <div className="mt-5 sm:mt-6 sm:flex sm:flex-row-reverse">
                  <button
                    type="button"
                    disabled={selectedTemplates.length === 0 || isAssigning}
                    onClick={handleAssign}
                    className="inline-flex w-full justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed sm:ml-3 sm:w-auto sm:text-sm"
                  >
                    {isAssigning ? 'Assignation...' : `Assigner ${selectedTemplates.length > 0 ? `(${selectedTemplates.length})` : ''}`}
                  </button>
                  <button
                    type="button"
                    onClick={handleClose}
                    className="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:mt-0 sm:w-auto sm:text-sm"
                  >
                    Annuler
                  </button>
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition.Root>
  );
} 