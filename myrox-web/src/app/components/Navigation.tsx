'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import Image from 'next/image';
import { useAuth } from '@/hooks/useAuth';
import {
  ChartBarIcon,
  DocumentDuplicateIcon,
  HomeIcon,
  UserGroupIcon,
  PlayIcon,
  TrophyIcon,
  ArrowRightOnRectangleIcon,
  UserPlusIcon,
  ArrowLeftOnRectangleIcon
} from '@heroicons/react/24/outline';

// Navigation pour les coaches (dashboards temporairement redirigés vers l'accueil)
const coachNavigation = [
  { name: 'Accueil', href: '/', icon: HomeIcon },
  { name: 'Statistiques', href: '/stats', icon: ChartBarIcon },
  { name: 'Templates', href: '/templates', icon: DocumentDuplicateIcon },
  { name: 'Mes Athlètes', href: '/coach/athletes', icon: UserGroupIcon },
];

// Navigation pour les athlètes (dashboards temporairement redirigés vers l'accueil)
const athleteNavigation = [
  { name: 'Accueil', href: '/', icon: HomeIcon },
  { name: 'Entraînements', href: '/', icon: PlayIcon },
  { name: 'Mes Templates', href: '/', icon: DocumentDuplicateIcon },
  { name: 'Records', href: '/', icon: TrophyIcon },
];

export default function Navigation() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, loading, logout, isAuthenticated, isCoach } = useAuth();

  // Ne pas afficher la navigation sur les pages d'auth
  const isAuthPage = pathname === '/login' || pathname === '/register';
  if (isAuthPage) {
    return null;
  }

  const handleLogout = async () => {
    try {
      await logout();
      router.push('/login');
    } catch (error) {
      console.error('Erreur lors de la déconnexion:', error);
    }
  };

  // Choisir la navigation selon le type d'utilisateur
  const navigation = isAuthenticated && user ? 
    (isCoach ? coachNavigation : athleteNavigation) : 
    coachNavigation; // Par défaut pour les non-connectés

  return (
    <nav className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <div className="flex gap-2 flex-shrink-0 flex items-center">
              <Image src="/logo_myrox.png" className="rounded-md" alt="myROX" width={42} height={32} />
              <h1 className="text-xl font-bold text-gray-900">
                {isAuthenticated && user ? 
                  (isCoach ? 'MyROX Coach' : 'MyROX Athlete') : 
                  'MyROX'
                }
              </h1>
            </div>
            
            {/* Navigation principale - seulement si connecté */}
            {isAuthenticated && user && (
              <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                {navigation.map((item) => {
                  const isActive = pathname === item.href;
                  const Icon = item.icon;
                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                        isActive
                          ? 'border-blue-500 text-gray-900'
                          : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                      }`}
                    >
                      <Icon className="w-4 h-4 mr-2" />
                      {item.name}
                    </Link>
                  );
                })}
              </div>
            )}
          </div>

          {/* Actions utilisateur */}
          <div className="flex items-center space-x-4">
            {loading ? (
              <div className="animate-pulse">
                <div className="h-8 w-20 bg-gray-200 rounded"></div>
              </div>
            ) : isAuthenticated && user ? (
              // Utilisateur connecté
              <div className="flex items-center space-x-4">
                <span className="text-sm text-gray-700">
                  Salut, {user.user.displayName || user.user.email?.split('@')[0]} !
                </span>
                <button
                  onClick={handleLogout}
                  className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-gray-500 hover:text-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <ArrowRightOnRectangleIcon className="w-4 h-4 mr-1" />
                  Déconnexion
                </button>
              </div>
            ) : (
              // Utilisateur non connecté
              <div className="flex items-center space-x-2">
                <Link
                  href="/login"
                  className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-gray-500 hover:text-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <ArrowLeftOnRectangleIcon className="w-4 h-4 mr-1" />
                  Connexion
                </Link>
                <Link
                  href="/register"
                  className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <UserPlusIcon className="w-4 h-4 mr-1" />
                  Inscription
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
} 