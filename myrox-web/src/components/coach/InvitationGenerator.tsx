'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { coachesApi } from '@/lib/api';
import { 
  PlusIcon, 
  ClipboardDocumentIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon 
} from '@heroicons/react/24/outline';

interface InvitationGeneratorProps {
  onInvitationCreated?: () => void;
  subscriptionStatus?: {
    canCreateInvitation: boolean;
    activeInvitations: number;
    maxInvitations: number;
    plan: string;
  };
}

export default function InvitationGenerator({ onInvitationCreated, subscriptionStatus }: InvitationGeneratorProps) {
  const { coachId } = useAuth();
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const [generatedCode, setGeneratedCode] = useState('');
  const [copied, setCopied] = useState(false);

  const handleGenerate = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!coachId) {
      setError('Coach ID manquant');
      return;
    }

    // Vérifier les limites côté client
    if (subscriptionStatus && !subscriptionStatus.canCreateInvitation) {
      setError(`Limite atteinte: ${subscriptionStatus.activeInvitations}/${subscriptionStatus.maxInvitations} codes actifs`);
      return;
    }

    try {
      setLoading(true);
      setError('');
      setSuccess('');

      const invitation = await coachesApi.generateInvitation(
        coachId, 
        description.trim() || 'Code d\'invitation'
      );

      setGeneratedCode(invitation.code);
      setSuccess(`Code généré: ${invitation.code}`);
      setDescription('');
      
      if (onInvitationCreated) {
        onInvitationCreated();
      }

    } catch (err: unknown) {
      console.error('Erreur génération code:', err);
      
      if (err.response?.status === 403) {
        const errorData = err.response.data;
        setError(errorData.details?.message || errorData.error || 'Limite atteinte');
      } else {
        setError('Erreur lors de la génération du code');
      }
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = async () => {
    if (generatedCode) {
      try {
        await navigator.clipboard.writeText(generatedCode);
        setCopied(true);
        setSuccess('Code copié dans le presse-papiers !');
        setTimeout(() => {
          setCopied(false);
          setSuccess('');
        }, 3000);
      } catch (err) {
        console.error('Erreur copie:', err);
      }
    }
  };

  const canGenerate = subscriptionStatus?.canCreateInvitation ?? true;

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="px-4 py-3 border-b border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">
          Générer un code d'invitation
        </h3>
        {subscriptionStatus && (
          <p className="text-sm text-gray-500 mt-1">
            {subscriptionStatus.activeInvitations}/{subscriptionStatus.maxInvitations === -1 ? '∞' : subscriptionStatus.maxInvitations} codes actifs
          </p>
        )}
      </div>

      <div className="p-4">
        {/* Limitations */}
        {!canGenerate && (
          <div className="mb-4 bg-yellow-50 border border-yellow-200 rounded-md p-3">
            <div className="flex items-start space-x-2">
              <ExclamationTriangleIcon className="w-5 h-5 text-yellow-500 mt-0.5" />
              <div className="text-sm text-yellow-700">
                <div className="font-medium">Limite atteinte</div>
                <div>
                  Vous avez atteint la limite de codes d'invitation pour votre plan {subscriptionStatus?.plan}.
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Formulaire */}
        <form onSubmit={handleGenerate} className="space-y-4">
          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700">
              Description (optionnelle)
            </label>
            <input
              type="text"
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Ex: Code pour Jean Dupont"
              className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
              disabled={!canGenerate}
            />
            <p className="mt-1 text-xs text-gray-500">
              Ajoutez une note pour identifier à qui vous donnez ce code
            </p>
          </div>

          <button
            type="submit"
            disabled={loading || !canGenerate}
            className={`w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white ${
              canGenerate && !loading
                ? 'bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500'
                : 'bg-gray-300 cursor-not-allowed'
            }`}
          >
            {loading ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Génération...
              </>
            ) : (
              <>
                <PlusIcon className="w-4 h-4 mr-2" />
                Générer un code
              </>
            )}
          </button>
        </form>

        {/* Résultats */}
        {error && (
          <div className="mt-4 bg-red-50 border border-red-200 rounded-md p-3">
            <div className="flex items-center space-x-2">
              <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
              <span className="text-sm text-red-700">{error}</span>
            </div>
          </div>
        )}

        {success && (
          <div className="mt-4 bg-green-50 border border-green-200 rounded-md p-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <CheckCircleIcon className="w-5 h-5 text-green-500" />
                <span className="text-sm text-green-700">{success}</span>
                {copied && (
                  <span className="ml-2 text-xs text-green-600 font-semibold">Code copié !</span>
                )}
              </div>
              {generatedCode && (
                <button
                  onClick={copyToClipboard}
                  className="flex items-center space-x-1 text-green-600 hover:text-green-800"
                  title="Copier le code"
                >
                  <ClipboardDocumentIcon className="w-4 h-4" />
                  <span className="text-sm">Copier</span>
                </button>
              )}
            </div>
            
            {generatedCode && (
              <div className="mt-2 p-2 bg-white border border-green-200 rounded text-center">
                <div className="text-2xl font-mono font-bold text-gray-900 tracking-wider">
                  {generatedCode}
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  Partagez ce code avec votre athlète
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
} 