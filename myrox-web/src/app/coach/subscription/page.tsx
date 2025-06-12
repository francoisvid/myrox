'use client';

import { useAuth } from '@/hooks/useAuth';
import { useSubscriptionStatus } from '@/hooks/useSubscriptionStatus';
import SubscriptionPlans from '@/components/coach/SubscriptionPlans';
import SubscriptionStatus from '@/components/coach/SubscriptionStatus';

export default function SubscriptionPage() {
  const { isAuthenticated, loading: authLoading, isCoach } = useAuth();
  const { subscriptionStatus, loading: statusLoading } = useSubscriptionStatus();

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
            Cette page est réservée aux coachs pour gérer leur abonnement.
          </p>
        </div>
      </div>
    );
  }

  const handleSelectPlan = (planId: string) => {
    console.log('Plan sélectionné:', planId);
    // Ici on pourrait intégrer Stripe ou un autre système de paiement
    
    // Pour le moment, rediriger vers une page de contact ou de paiement
    if (planId === 'ENTERPRISE') {
      window.location.href = 'mailto:contact@myrox.fr?subject=Demande plan Entreprise';
    } else {
      // Rediriger vers une page de paiement (à implémenter)
      alert(`Redirection vers le paiement pour le plan ${planId} (à implémenter)`);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              Gestion de l&apos;abonnement
            </h1>
            <p className="mt-1 text-sm text-gray-600">
              Choisissez le plan qui correspond à vos besoins de coaching
            </p>
          </div>
        </div>
      </header>

      {/* Statut actuel */}
      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="mb-8">
          <SubscriptionStatus />
        </div>

        {/* Plans disponibles */}
        <SubscriptionPlans 
          currentPlan={subscriptionStatus?.plan}
          onSelectPlan={handleSelectPlan}
        />

        {/* FAQ Section */}
        <div className="mt-16 bg-white rounded-lg shadow">
          <div className="px-6 py-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">
              Questions fréquentes
            </h2>
            
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Puis-je changer de plan à tout moment ?
                </h3>
                <p className="text-gray-600">
                  Oui, vous pouvez passer à un plan supérieur à tout moment. 
                  La facturation sera ajustée au prorata de la période restante.
                </p>
              </div>
              
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Que se passe-t-il si je dépasse les limites de mon plan ?
                </h3>
                <p className="text-gray-600">
                  Vous recevrez une notification vous invitant à passer au plan supérieur. 
                  Vos données restent accessibles mais certaines fonctionnalités peuvent être limitées.
                </p>
              </div>
              
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Y a-t-il une période d&apos;essai ?
                </h3>
                <p className="text-gray-600">
                  Oui, tous les plans payants incluent une période d&apos;essai gratuite de 14 jours. 
                  Aucun engagement, annulation possible à tout moment.
                </p>
              </div>
              
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Le support est-il inclus ?
                </h3>
                <p className="text-gray-600">
                  Oui, tous les plans incluent un support. Le niveau varie selon votre plan : 
                  communautaire pour le plan gratuit, email pour Starter, prioritaire pour Pro, 
                  et dédié pour Entreprise.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 