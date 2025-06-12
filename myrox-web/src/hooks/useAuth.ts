'use client';

import { useState, useEffect } from 'react';
import { 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  OAuthProvider,
  signInWithPopup
} from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { User, Coach } from '@/types';
import { useRouter } from 'next/navigation';

interface AuthUser {
  user: User;
  coach?: Coach;
  userType: 'athlete' | 'coach';
}

export const useAuth = () => {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          setLoading(true);
          setError(null);
          // Récupérer les infos utilisateur depuis l'API
          const userData = await fetchUserData(firebaseUser.uid);
          setUser(userData);
        } catch (error) {
          console.error('Erreur récupération utilisateur:', error);
          
          // Si l'utilisateur n'existe pas dans notre base, on le déconnecte de Firebase
          // et on le redirige vers l'inscription
          if (error instanceof Error && error.message.includes('Utilisateur non trouvé')) {
            console.log('Utilisateur Firebase sans profil - déconnexion et redirection vers inscription');
            await signOut(auth);
            setUser(null);
            setError('Profil utilisateur non trouvé. Veuillez vous inscrire.');
          } else {
            setError('Erreur lors de la récupération des données utilisateur');
          }
        }
      } else {
        setUser(null);
        setError(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const fetchUserData = async (firebaseUID: string): Promise<AuthUser> => {
    // 1. Vérifier si l'utilisateur existe
    const userResponse = await fetch(`/api/auth/user-type/${firebaseUID}`);
    
    if (userResponse.ok) {
      const data = await userResponse.json();
      return {
        user: data.user,
        coach: data.coach,
        userType: data.userType
      };
    }
    
    // 2. Si l'utilisateur n'existe pas, il faut le créer
    // Cela ne devrait arriver que si un utilisateur existant n'a pas encore été migré
    throw new Error('Utilisateur non trouvé - inscription requise');
  };

  const register = async (
    email: string, 
    password: string, 
    userType: 'athlete' | 'coach',
    additionalData?: {
      displayName?: string;
      specialization?: string;
      bio?: string;
      certifications?: string[];
    }
  ) => {
    try {
      setError(null);
      setLoading(true);
      
      // 1. Créer le compte Firebase
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      
      // 2. Créer le profil dans l'API avec le rôle
      const response = await fetch('/api/auth/register', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'x-firebase-uid': userCredential.user.uid,
          'x-firebase-email': userCredential.user.email || ''
        },
        body: JSON.stringify({
          firebaseUID: userCredential.user.uid,
          email,
          userType,
          displayName: additionalData?.displayName || email.split('@')[0],
          ...additionalData
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Erreur création profil');
      }
      
      const userData = await response.json();
      
      const authUser: AuthUser = {
        user: userData.user,
        coach: userData.coach,
        userType: userType
      };
      
      setUser(authUser);
      return authUser;
    } catch (error) {
      console.error('Erreur inscription:', error);
      const errorMessage = error instanceof Error ? error.message : 'Erreur d\'inscription';
      setError(errorMessage);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const login = async (email: string, password: string) => {
    try {
      setError(null);
      setLoading(true);
      await signInWithEmailAndPassword(auth, email, password);
      router.push('/');
      // L'utilisateur sera automatiquement mis à jour via onAuthStateChanged
    } catch (error) {
      console.error('Erreur connexion:', error);
      const errorMessage = error instanceof Error ? error.message : 'Erreur de connexion';
      setError(errorMessage);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const signInWithApple = async () => {
    try {
      setError(null);
      setLoading(true);
      
      const provider = new OAuthProvider('apple.com');
      provider.addScope('email');
      provider.addScope('name');
      
      const result = await signInWithPopup(auth, provider);
      
      // Vérifier si c'est un nouvel utilisateur ou existant
      const userExists = await checkUserExists(result.user.uid);
      
      if (!userExists) {
        // Nouvel utilisateur Apple - demander le type
        throw new Error('NEW_USER_NEEDS_TYPE_SELECTION');
      }
      
      // L'utilisateur sera automatiquement mis à jour via onAuthStateChanged
    } catch (error) {
      console.error('Erreur connexion Apple:', error);
      const errorMessage = error instanceof Error ? error.message : 'Erreur de connexion Apple';
      setError(errorMessage);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const checkUserExists = async (firebaseUID: string): Promise<boolean> => {
    try {
      const response = await fetch(`/api/auth/user-type/${firebaseUID}`);
      return response.ok;
    } catch {
      return false;
    }
  };

  const logout = async () => {
    try {
      setError(null);
      await signOut(auth);
      setUser(null);
    } catch (error) {
      console.error('Erreur déconnexion:', error);
      const errorMessage = error instanceof Error ? error.message : 'Erreur de déconnexion';
      setError(errorMessage);
      throw error;
    }
  };

  const clearError = () => setError(null);

  return {
    user,
    loading,
    error,
    isAuthenticated: !!user,
    isCoach: user?.userType === 'coach',
    coachId: user?.coach?.id,
    register,
    login,
    signInWithApple,
    logout,
    clearError
  };
}; 