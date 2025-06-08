'use client';

import { useState } from 'react';
import Link from 'next/link';
import { 
  MagnifyingGlassIcon, 
  UserGroupIcon, 
  PlusIcon,
  ChartBarIcon,
  DocumentPlusIcon 
} from '@heroicons/react/24/outline';
import { useAthletes } from '@/hooks/useAthletes';
import { useTemplates } from '@/hooks/useTemplates';
import { User, Template } from '@/types';
import TemplateAssignmentModal from '@/components/coach/TemplateAssignmentModal';
import TemplateAssignmentManager from '@/components/coach/TemplateAssignmentManager';
import { config } from '@/lib/config';

export default function AthletesPage() {
  const { athletes, loading: athletesLoading, error: athletesError, refetch } = useAthletes();
  const { templates, loading: templatesLoading } = useTemplates();
  
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAthletes, setSelectedAthletes] = useState<string[]>([]);
  const [showAssignmentModal, setShowAssignmentModal] = useState(false);
  const [activeTab, setActiveTab] = useState<'athletes' | 'assignments'>('athletes');

  // Filtrer les athlètes selon la recherche
  const filteredAthletes = athletes.filter(athlete =>
    athlete.displayName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    athlete.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleSelectAthlete = (athleteId: string) => {
    setSelectedAthletes(prev => 
      prev.includes(athleteId) 
        ? prev.filter(id => id !== athleteId)
        : [...prev, athleteId]
    );
  };

  const handleSelectAll = () => {
    if (selectedAthletes.length === filteredAthletes.length) {
      setSelectedAthletes([]);
    } else {
      setSelectedAthletes(filteredAthletes.map(athlete => athlete.id));
    }
  };

  const openAssignmentModal = () => {
    if (selectedAthletes.length > 0) {
      setShowAssignmentModal(true);
    }
  };

  const handleAssignmentSuccess = () => {
    setShowAssignmentModal(false);
    setSelectedAthletes([]);
    refetch();
  };

  if (athletesLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Chargement des athlètes...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div className="md:flex md:items-center md:justify-between">
            <div className="flex-1 min-w-0">
              <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
                Mes Athlètes
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                Gérez vos athlètes et assignez-leur des templates d'entraînement
              </p>
            </div>
            {activeTab === 'athletes' && (
              <div className="mt-4 flex md:mt-0 md:ml-4">
                <button
                  onClick={openAssignmentModal}
                  disabled={selectedAthletes.length === 0}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <DocumentPlusIcon className="h-4 w-4 mr-2" />
                  Assigner Templates ({selectedAthletes.length})
                </button>
              </div>
            )}
          </div>
          
          {/* Navigation par onglets */}
          <div className="mt-6">
            <div className="border-b border-gray-200">
              <nav className="-mb-px flex space-x-8">
                <button
                  onClick={() => setActiveTab('athletes')}
                  className={`py-2 px-1 border-b-2 font-medium text-sm ${
                    activeTab === 'athletes'
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  <UserGroupIcon className="h-5 w-5 mr-2 inline" />
                  Athlètes ({athletes.length})
                </button>
                <button
                  onClick={() => setActiveTab('assignments')}
                  className={`py-2 px-1 border-b-2 font-medium text-sm ${
                    activeTab === 'assignments'
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  <DocumentPlusIcon className="h-5 w-5 mr-2 inline" />
                  Assignations
                </button>
              </nav>
            </div>
          </div>
        </div>
      </div>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {activeTab === 'athletes' && (
          <>
            {/* Statistiques */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <UserGroupIcon className="h-6 w-6 text-blue-600" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Total Athlètes
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {athletes.length}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <DocumentPlusIcon className="h-6 w-6 text-green-600" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Templates Disponibles
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {templates.length}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <ChartBarIcon className="h-6 w-6 text-purple-600" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Sélectionnés
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {selectedAthletes.length}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Recherche et filtres */}
        <div className="bg-white shadow rounded-lg mb-6">
          <div className="p-6">
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="flex-1">
                <div className="relative">
                  <input
                    type="text"
                    placeholder="Rechercher un athlète..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>
              <button
                onClick={handleSelectAll}
                className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
              >
                {selectedAthletes.length === filteredAthletes.length ? 'Tout désélectionner' : 'Tout sélectionner'}
              </button>
            </div>
          </div>
        </div>

        {/* Liste des athlètes */}
        <div className="bg-white shadow rounded-lg overflow-hidden">
          {athletesError && (
            <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-4">
              <div className="flex">
                <div className="ml-3">
                  <p className="text-sm text-yellow-700">
                    {athletesError} (Données de test affichées)
                  </p>
                </div>
              </div>
            </div>
          )}

          {filteredAthletes.length === 0 ? (
            <div className="text-center py-12">
              <UserGroupIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">Aucun athlète trouvé</h3>
              <p className="mt-1 text-sm text-gray-500">
                {searchTerm ? 'Aucun athlète ne correspond à votre recherche.' : 'Vous n\'avez pas encore d\'athlètes.'}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      <input
                        type="checkbox"
                        checked={selectedAthletes.length === filteredAthletes.length && filteredAthletes.length > 0}
                        onChange={handleSelectAll}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                      />
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Athlète
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Email
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Membre depuis
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredAthletes.map((athlete) => (
                    <tr key={athlete.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <input
                          type="checkbox"
                          checked={selectedAthletes.includes(athlete.id)}
                          onChange={() => handleSelectAthlete(athlete.id)}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="flex-shrink-0 h-10 w-10">
                            <div className="h-10 w-10 rounded-full bg-blue-500 flex items-center justify-center">
                              <span className="text-sm font-medium text-white">
                                {athlete.displayName?.charAt(0).toUpperCase() || athlete.email?.charAt(0).toUpperCase() || 'A'}
                              </span>
                            </div>
                          </div>
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900">
                              {athlete.displayName || 'Nom non défini'}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {athlete.email}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(athlete.createdAt).toLocaleDateString('fr-FR')}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <Link
                          href={`/coach/athletes/${athlete.id}`}
                          className="text-blue-600 hover:text-blue-900"
                        >
                          Voir détails
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
          </>
        )}

        {activeTab === 'assignments' && (
          <TemplateAssignmentManager 
            coachId={config.defaults.coachId}
            onUpdate={() => {
              // Optionnel: recharger les données si nécessaire
            }}
          />
        )}
      </main>

      {/* Modal d'assignation */}
      {showAssignmentModal && (
        <TemplateAssignmentModal
          isOpen={showAssignmentModal}
          onClose={() => setShowAssignmentModal(false)}
          selectedAthletes={selectedAthletes.map(id => athletes.find(a => a.id === id)!).filter(Boolean)}
          templates={templates}
          onSuccess={handleAssignmentSuccess}
        />
      )}
    </div>
  );
} 