import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};

// Fonction pour initialiser Firebase côté client uniquement
function initializeFirebase() {
  if (typeof window === 'undefined') {
    return null;
  }
  
  // Vérifier que toutes les variables Firebase sont présentes
  if (!firebaseConfig.apiKey || firebaseConfig.apiKey === 'undefined') {
    console.warn('Variables Firebase manquantes ou invalides');
    return null;
  }
  
  try {
    // Éviter la double initialisation
    const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
    return getAuth(app);
  } catch (error) {
    console.error('Erreur initialisation Firebase:', error);
    return null;
  }
}

// Initialiser Firebase seulement côté client
export const auth = initializeFirebase();

// Configuration pour le développement (optionnel)
if (typeof window !== 'undefined' && process.env.NODE_ENV === 'development') {
  // Optionnel: connecter à l'émulateur Firebase Auth en développement
  // connectAuthEmulator(auth, 'http://localhost:9099');
}

export default auth ? getApp() : null;