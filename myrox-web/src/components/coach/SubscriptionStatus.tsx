'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { coachesApi } from '@/lib/api';
import { 
  CreditCardIcon, 
  UserGroupIcon, 
  TicketIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon 
} from '@heroicons/react/24/outline';
import Link from 'next/link';

interface SubscriptionStatus {
  plan: string;
  maxAthletes: number;
  maxInvitations: number;
  currentAthletes: number;
  activeInvitations: number;
  isActive: boolean;
  expiresAt?: string;
  canCreateInvitation: boolean;
  canAddAthlete: boolean;
}

export default function SubscriptionStatus() {
  const { coachId } = useAuth();
  const [status, setStatus] = useState<SubscriptionStatus | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (coachId) {
      fetchSubscriptionStatus();
    }
  }, [coachId]);

  const fetchSubscriptionStatus = async () => {
    if (!coachId) {
      setLoading(false);
      return;
    }
    
    try {
      const data = await coachesApi.getSubscriptionStatus(coachId);
      setStatus(data);
    } catch (error) {
      console.error('Erreur récupération statut:', error);
    } finally {
      setLoading(false);
    }
  };

  const getPlanName = (plan: string) => {
    const plans = {
      FREE: 'Gratuit',
      STARTER: 'Débutant', 
      PROFESSIONAL: 'Professionnel',
      ENTERPRISE: 'Entreprise'
    };
    return plans[plan as keyof typeof plans] || plan;
  };

  const getPlanColor = (plan: string) => {
    const colors = {
      FREE: 'bg-gray-100 text-gray-800',
      STARTER: 'bg-blue-100 text-blue-800',
      PROFESSIONAL: 'bg-purple-100 text-purple-800',
      ENTERPRISE: 'bg-gold-100 text-gold-800'
    };
    return colors[plan as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  const getUsageColor = (current: number, max: number) => {
    if (max === -1) return 'text-green-600'; // Illimité
    const percentage = (current / max) * 100;
    if (percentage >= 90) return 'text-red-600';
    if (percentage >= 75) return 'text-yellow-600';
    return 'text-green-600';
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-4">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 rounded w-1/3 mb-2"></div>
          <div className="h-8 bg-gray-200 rounded"></div>
        </div>
      </div>
    );
  }

  if (!status) {
    return (
      <div className="bg-white rounded-lg shadow p-4">
        <div className="text-center text-gray-500">
          Impossible de charger le statut de l'abonnement
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow">
      {/* Header */}
      <div className="px-4 py-3 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-medium text-gray-900">
            Mon Abonnement
          </h3>
          <div className="flex items-center space-x-2">
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${getPlanColor(status.plan)}`}>
              {getPlanName(status.plan)}
            </span>
            {status.isActive ? (
              <CheckCircleIcon className="w-5 h-5 text-green-500" />
            ) : (
              <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
            )}
          </div>
        </div>
      </div>

      {/* Métriques */}
      <div className="p-4 space-y-4">
        {/* Athlètes */}
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <UserGroupIcon className="w-5 h-5 text-blue-500" />
            <span className="text-sm font-medium text-gray-700">Athlètes</span>
          </div>
          <div className="text-right">
            <div className={`text-sm font-medium ${getUsageColor(status.currentAthletes, status.maxAthletes)}`}>
              {status.currentAthletes} / {status.maxAthletes === -1 ? '∞' : status.maxAthletes}
            </div>
            {status.maxAthletes !== -1 && (
              <div className="w-32 bg-gray-200 rounded-full h-2 mt-1">
                <div 
                  className={`h-2 rounded-full ${
                    status.currentAthletes >= status.maxAthletes ? 'bg-red-500' : 'bg-blue-500'
                  }`}
                  style={{ width: `${Math.min((status.currentAthletes / status.maxAthletes) * 100, 100)}%` }}
                ></div>
              </div>
            )}
          </div>
        </div>

        {/* Invitations */}
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <TicketIcon className="w-5 h-5 text-purple-500" />
                         <span className="text-sm font-medium text-gray-700">Codes actifs</span>
          </div>
          <div className="text-right">
            <div className={`text-sm font-medium ${getUsageColor(status.activeInvitations, status.maxInvitations)}`}>
              {status.activeInvitations} / {status.maxInvitations === -1 ? '∞' : status.maxInvitations}
            </div>
            {status.maxInvitations !== -1 && (
              <div className="w-32 bg-gray-200 rounded-full h-2 mt-1">
                <div 
                  className={`h-2 rounded-full ${
                    status.activeInvitations >= status.maxInvitations ? 'bg-red-500' : 'bg-purple-500'
                  }`}
                  style={{ width: `${Math.min((status.activeInvitations / status.maxInvitations) * 100, 100)}%` }}
                ></div>
              </div>
            )}
          </div>
        </div>

        {/* Statut */}
        {!status.isActive && (
          <div className="bg-red-50 border border-red-200 rounded-md p-3">
            <div className="flex items-center space-x-2">
              <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
              <span className="text-sm text-red-700">
                Abonnement expiré - Renouvelez pour continuer
              </span>
            </div>
          </div>
        )}

        {/* Limitations actives */}
        {(!status.canCreateInvitation || !status.canAddAthlete) && status.isActive && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-md p-3">
            <div className="text-sm text-yellow-700">
              <div className="font-medium mb-1">Limites atteintes :</div>
              <ul className="space-y-1">
                {!status.canCreateInvitation && (
                  <li>• Codes d&apos;invitation maximum ({status.maxInvitations})</li>
                )}
                {!status.canAddAthlete && (
                  <li>• Athlètes maximum ({status.maxAthletes})</li>
                )}
              </ul>
            </div>
          </div>
        )}

        {/* Expiration */}
        {status.expiresAt && (
          <div className="text-xs text-gray-500">
            Expire le {new Date(status.expiresAt).toLocaleDateString('fr-FR')}
          </div>
        )}
      </div>

      {/* Actions */}
      {status.plan !== 'ENTERPRISE' && (
        <div className="px-4 py-3 border-t border-gray-200">
          <button className="flex items-center space-x-2 text-sm text-blue-600 hover:text-blue-800">
            <CreditCardIcon className="w-4 h-4" />
            <Link href="/coach/subscription">Passer à un plan supérieur</Link>
          </button>
        </div>
      )}
    </div>
  );
} 