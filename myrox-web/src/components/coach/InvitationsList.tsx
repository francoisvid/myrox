'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { coachesApi } from '@/lib/api';
import { CoachInvitation } from '@/types';
import { 
  TicketIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon,
  ClipboardDocumentIcon 
} from '@heroicons/react/24/outline';

interface InvitationsListProps {
  refreshTrigger?: number;
}

export default function InvitationsList({ refreshTrigger }: InvitationsListProps) {
  const { coachId } = useAuth();
  const [invitations, setInvitations] = useState<CoachInvitation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const fetchInvitations = async () => {
    if (!coachId) return;

    try {
      setLoading(true);
      setError('');
      const data = await coachesApi.getInvitations(coachId);
      setInvitations(data);
    } catch (err) {
      console.error('Erreur récupération invitations:', err);
      setError('Erreur lors du chargement des invitations');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInvitations();
  }, [coachId, refreshTrigger]);

  const copyCode = async (code: string, id: string) => {
    try {
      await navigator.clipboard.writeText(code);
      setCopiedId(id);
      setTimeout(() => setCopiedId(null), 2000);
    } catch (err) {
      console.error('Erreur copie:', err);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-3">
            {[1, 2, 3].map(i => (
              <div key={i} className="h-16 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="text-center text-red-600">
          <XCircleIcon className="w-8 h-8 mx-auto mb-2" />
          <p>{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="px-4 py-3 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-medium text-gray-900">
            Codes d&apos;invitation
          </h3>
          <span className="text-sm text-gray-500">
            {invitations.length} code{invitations.length > 1 ? 's' : ''}
          </span>
        </div>
      </div>

      <div className="divide-y divide-gray-200">
        {invitations.length === 0 ? (
          <div className="p-6 text-center">
            <TicketIcon className="w-12 h-12 text-gray-400 mx-auto mb-3" />
            <h4 className="text-lg font-medium text-gray-900 mb-2">
              Aucun code d&apos;invitation
            </h4>
            <p className="text-gray-500">
              Générez votre premier code pour inviter des athlètes
            </p>
          </div>
        ) : (
          invitations.map((invitation) => (
            <div key={invitation.id} className="p-4 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3">
                    {/* Code */}
                    <div 
                      className="font-mono text-lg font-bold text-gray-900 bg-gray-100 px-3 py-1 rounded cursor-pointer hover:bg-gray-200 transition-colors"
                      onClick={() => copyCode(invitation.code, invitation.id)}
                      title="Cliquer pour copier"
                    >
                      {invitation.code}
                    </div>

                    {/* Statut */}
                    <div className="flex items-center space-x-1">
                      {invitation.usedAt ? (
                        <>
                          <CheckCircleIcon className="w-5 h-5 text-green-500" />
                          <span className="text-sm text-green-600 font-medium">Utilisé</span>
                        </>
                      ) : invitation.isActive ? (
                        <>
                          <ClockIcon className="w-5 h-5 text-blue-500" />
                          <span className="text-sm text-blue-600 font-medium">Actif</span>
                        </>
                      ) : (
                        <>
                          <XCircleIcon className="w-5 h-5 text-gray-500" />
                          <span className="text-sm text-gray-600 font-medium">Inactif</span>
                        </>
                      )}
                    </div>
                  </div>

                  {/* Description */}
                  {invitation.description && (
                    <p className="text-sm text-gray-600 mt-1">
                      {invitation.description}
                    </p>
                  )}

                  {/* Métadonnées */}
                  <div className="flex items-center space-x-4 mt-2 text-xs text-gray-500">
                    <span>Créé le {formatDate(invitation.createdAt)}</span>
                    {invitation.usedAt && invitation.usedBy && (
                      <span>
                        Utilisé par {invitation.usedBy.displayName || invitation.usedBy.email} 
                        le {formatDate(invitation.usedAt)}
                      </span>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center space-x-2" style={{ position: 'relative' }}>
                  <button
                    onClick={() => copyCode(invitation.code, invitation.id)}
                    className="p-1 text-gray-400 hover:text-gray-600"
                    title="Copier le code"
                  >
                    <ClipboardDocumentIcon className="w-4 h-4" />
                  </button>
                  {copiedId === invitation.id && (
                    <span
                      className="absolute left-1/2 -translate-x-1/2 -top-7 bg-green-50 border border-green-200 text-green-700 text-xs font-semibold px-2 py-1 rounded shadow pointer-events-none"
                      style={{ whiteSpace: 'nowrap', zIndex: 10, margin: 0, padding: '0.25rem 0.5rem' }}
                    >
                      Code copié !
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
} 