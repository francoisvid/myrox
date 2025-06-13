'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import SubscriptionStatus from '@/components/coach/SubscriptionStatus';
import InvitationGenerator from '@/components/coach/InvitationGenerator';
import InvitationsList from '@/components/coach/InvitationsList';
import { useSubscriptionStatus } from '@/hooks/useSubscriptionStatus';

export default function InvitationsPage() {
  const { isAuthenticated, loading: authLoading, isCoach } = useAuth();
  const { subscriptionStatus, loading: statusLoading, refetch } = useSubscriptionStatus();
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  // States de chargement
  if (authLoading || statusLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Chargement...</p>
        </div>
      </div>
    );
  }

  // Vérifications d'accès
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">
            Authentification requise
          </h1>
          <p className="text-gray-600">
            Veuillez vous connecter pour accéder à cette page.
          </p>
        </div>
      </div>
    );
  }

  if (!isCoach) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">
            Accès réservé aux coachs
          </h1>
          <p className="text-gray-600">
            Cette page est réservée aux coachs pour gérer leurs invitations.
          </p>
        </div>
      </div>
    );
  }

  const handleInvitationCreated = () => {
    // Actualiser les données
    setRefreshTrigger(prev => prev + 1);
    refetch();
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              Gestion des invitations
            </h1>
            <p className="mt-1 text-sm text-gray-600">
              Générez des codes d&apos;invitation pour vos athlètes et suivez leur utilisation
            </p>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Colonne gauche - Générateur et abonnement */}
          <div className="lg:col-span-1 space-y-6">
            {/* Statut d'abonnement */}
            <SubscriptionStatus />

            {/* Générateur de codes */}
            <InvitationGenerator 
              onInvitationCreated={handleInvitationCreated}
              subscriptionStatus={subscriptionStatus}
            />
          </div>

          {/* Colonne droite - Liste des invitations */}
          <div className="lg:col-span-2">
            <InvitationsList refreshTrigger={refreshTrigger} />
          </div>
        </div>

        {/* Guide d'utilisation */}
        <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="text-lg font-medium text-blue-900 mb-3">
            💡 Comment ça marche ?
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-blue-800">
            <div className="flex items-start space-x-3">
              <span className="flex-shrink-0 w-6 h-6 bg-blue-600 text-white rounded-full flex items-center justify-center text-xs font-bold">
                1
              </span>
              <div>
                <div className="font-medium">Générez un code</div>
                <div>Créez un code d&apos;invitation unique pour votre athlète</div>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <span className="flex-shrink-0 w-6 h-6 bg-blue-600 text-white rounded-full flex items-center justify-center text-xs font-bold">
                2
              </span>
              <div>
                <div className="font-medium">Partagez le code</div>
                <div>Envoyez le code à votre athlète par SMS, email ou verbal</div>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <span className="flex-shrink-0 w-6 h-6 bg-blue-600 text-white rounded-full flex items-center justify-center text-xs font-bold">
                3
              </span>
              <div>
                <div className="font-medium">Liaison automatique</div>
                <div>L&apos;athlète saisit le code dans l&apos;app et vous êtes liés</div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
} 