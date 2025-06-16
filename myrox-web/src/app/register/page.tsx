'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function RegisterPage() {
  const [userType, setUserType] = useState<'athlete' | 'coach'>('coach');
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    displayName: '',
    specialization: '',
    bio: '',
    certifications: [] as string[]
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const { register } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (formData.password !== formData.confirmPassword) {
      setError('Les mots de passe ne correspondent pas');
      return;
    }
    
    if (formData.password.length < 6) {
      setError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setLoading(true);
    setError('');

    try {
      await register(
        formData.email, 
        formData.password, 
        userType,
        {
          displayName: formData.displayName,
          ...(userType === 'coach' && {
            specialization: formData.specialization,
            bio: formData.bio,
            certifications: formData.certifications.filter(c => c.trim() !== '')
          })
        }
      );
      
      router.push('/login');
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Erreur lors de l&apos;inscription';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // const handleAppleSignIn = async () => {
  //   try {
  //     setError('');
  //     await signInWithApple();
  //     // Si succès, redirection automatique via le hook
  //   } catch (err) {
  //     if (err instanceof Error && err.message === 'NEW_USER_NEEDS_TYPE_SELECTION') {
  //       // Nouvel utilisateur Apple - afficher sélection du type
  //       setError('Veuillez d&apos;abord choisir votre type de profil ci-dessous, puis utiliser l&apos;inscription par email.');
  //     } else {
  //       const errorMessage = err instanceof Error ? err.message : 'Erreur de connexion Apple';
  //       setError(errorMessage);
  //     }
  //   }
  // };

  const addCertification = () => {
    setFormData(prev => ({
      ...prev,
      certifications: [...prev.certifications, '']
    }));
  };

  const updateCertification = (index: number, value: string) => {
    setFormData(prev => ({
      ...prev,
      certifications: prev.certifications.map((cert, i) => i === index ? value : cert)
    }));
  };

  const removeCertification = (index: number) => {
    setFormData(prev => ({
      ...prev,
      certifications: prev.certifications.filter((_, i) => i !== index)
    }));
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Rejoignez myROX
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Ou{' '}
            <Link href="/login" className="font-medium text-blue-600 hover:text-blue-500">
              connectez-vous à votre compte
            </Link>
          </p>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6 space-y-6">
          {/* Choix du type d'utilisateur */}
          <div>
            <p className="text-lg font-medium mb-4 text-gray-900">Je suis :</p>
            <div className="grid grid-cols-1 gap-4">
              {/* <button 
                type="button"
                onClick={() => setUserType('athlete')}
                className={`p-4 border rounded-lg text-center transition-colors ${
                  userType === 'athlete' 
                    ? 'border-blue-500 bg-blue-50 text-blue-700' 
                    : 'border-gray-300 hover:border-gray-400'
                }`}
              >
                <div className="text-2xl mb-2">🏃‍♂️</div>
                <div className="font-medium">Athlète</div>
                <div className="text-sm text-gray-500">Je veux m&apos;entraîner</div>
              </button> */}
              
              <button 
                type="button"
                onClick={() => setUserType('coach')}
                className={`p-4 border rounded-lg text-center transition-colors ${
                  userType === 'coach' 
                    ? 'border-blue-500 bg-blue-50 text-blue-700' 
                    : 'border-gray-300 hover:border-gray-400'
                }`}
              >
                <div className="text-2xl mb-2">👨‍🏫</div>
                <div className="font-medium">Coach</div>
                <div className="text-sm text-gray-500">Je veux entraîner</div>
              </button>
            </div>
          </div>

          {/* Sign in with Apple */}
          {/* <div>
            <button
              type="button"
              onClick={handleAppleSignIn}
              className="w-full flex justify-center items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm bg-black text-white text-sm font-medium hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
            >
              <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              Continuer avec Apple
            </button>
          </div> */}

          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-300" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-white text-gray-500">Ou avec votre email</span>
            </div>
          </div>

          {error && (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Champs communs */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email
              </label>
              <input
                id="email"
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Mot de passe
              </label>
              <input
                id="password"
                type="password"
                value={formData.password}
                onChange={(e) => setFormData({...formData, password: e.target.value})}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                required
                minLength={6}
              />
            </div>

            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700">
                Confirmer le mot de passe
              </label>
              <input
                id="confirmPassword"
                type="password"
                value={formData.confirmPassword}
                onChange={(e) => setFormData({...formData, confirmPassword: e.target.value})}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>

            <div>
              <label htmlFor="displayName" className="block text-sm font-medium text-gray-700">
                Nom complet
              </label>
              <input
                id="displayName"
                type="text"
                value={formData.displayName}
                onChange={(e) => setFormData({...formData, displayName: e.target.value})}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                placeholder="Votre nom complet"
              />
            </div>

            {/* Champs spécifiques aux coaches */}
            {userType === 'coach' && (
              <>
                <div>
                  <label htmlFor="specialization" className="block text-sm font-medium text-gray-700">
                    Spécialisation
                  </label>
                  <select
                    id="specialization"
                    value={formData.specialization}
                    onChange={(e) => setFormData({...formData, specialization: e.target.value})}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="">Choisir une spécialisation</option>
                    <option value="HYROX">HYROX</option>
                    <option value="CROSSFIT">CrossFit</option>
                    <option value="RUNNING">Course à pied</option>
                    <option value="STRENGTH">Musculation</option>
                    <option value="CARDIO">Cardio</option>
                  </select>
                </div>
                
                <div>
                  <label htmlFor="bio" className="block text-sm font-medium text-gray-700">
                    Présentation courte
                  </label>
                  <textarea
                    id="bio"
                    value={formData.bio}
                    onChange={(e) => setFormData({...formData, bio: e.target.value})}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    rows={3}
                    placeholder="Décrivez votre expérience et votre approche..."
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Certifications
                  </label>
                  {formData.certifications.map((cert, index) => (
                    <div key={index} className="flex mb-2">
                      <input
                        type="text"
                        value={cert}
                        onChange={(e) => updateCertification(index, e.target.value)}
                        className="flex-1 px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                        placeholder="Ex: HYROX Master Trainer"
                      />
                      <button
                        type="button"
                        onClick={() => removeCertification(index)}
                        className="ml-2 px-2 py-2 text-red-600 hover:text-red-800"
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                  <button
                    type="button"
                    onClick={addCertification}
                    className="text-blue-600 hover:text-blue-800 text-sm"
                  >
                    + Ajouter une certification
                  </button>
                </div>
              </>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Inscription...' : (userType === 'coach' ? 'S\'inscrire comme Coach' : 'S\'inscrire comme Athlète')}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
} 