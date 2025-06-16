'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState } from 'react';
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
  TicketIcon,
  CreditCardIcon,
  Bars3Icon,
  XMarkIcon
} from '@heroicons/react/24/outline';

// Navigation pour les coaches
const coachNavigation = [
  { name: 'Accueil', href: '/', icon: HomeIcon },
  { name: 'Statistiques', href: '/stats', icon: ChartBarIcon },
  { name: 'Templates', href: '/templates', icon: DocumentDuplicateIcon },
  { name: 'Mes Athlètes', href: '/coach/athletes', icon: UserGroupIcon },
  { name: 'Invitations', href: '/coach/invitations', icon: TicketIcon },
  { name: 'Abonnement', href: '/coach/subscription', icon: CreditCardIcon },
];

// Navigation pour les athlètes
const athleteNavigation = [
  { name: 'Accueil', href: '/', icon: HomeIcon },
  { name: 'Entraînements', href: '/', icon: PlayIcon },
  { name: 'Mes Templates', href: '/', icon: DocumentDuplicateIcon },
  { name: 'Records', href: '/', icon: TrophyIcon },
];

// Composant skeleton pour l'état de chargement
function NavigationSkeleton() {
  return (
    <nav className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <div className="flex gap-2 flex-shrink-0 flex items-center">
              <Image src="/logo_myrox.png" className="rounded-md" alt="myROX" width={42} height={32} />

            </div>

            {/* Navigation skeleton */}
            <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="inline-flex items-center px-1 pt-1 border-b-2 border-transparent">
                  <div className="w-4 h-4 bg-gray-200 rounded animate-pulse mr-2"></div>
                  <div className="w-16 h-4 bg-gray-200 rounded animate-pulse"></div>
                </div>
              ))}
            </div>
          </div>

          {/* Actions utilisateur skeleton */}
          <div className="flex items-center space-x-4">
            <div className="animate-pulse">
              <div className="h-8 w-20 bg-gray-200 rounded"></div>
            </div>
          </div>
        </div>
      </div>
    </nav>
  );
}

export default function Navigation() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, loading, logout, isAuthenticated, isCoach } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);

  // Ne pas afficher la navigation sur les pages d'auth
  const isAuthPage = pathname === '/login' || pathname === '/register';
  if (isAuthPage) {
    return null;
  }

  // Afficher le skeleton pendant le chargement initial
  if (loading) {
    return <NavigationSkeleton />;
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
    <nav className="bg-white shadow-sm border-b sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16 items-center">
          <div className="flex items-center gap-2">
            <Image src="/logo_myrox.png" className="rounded-md" alt="myROX" width={42} height={32} priority />
          </div>

          {/* Menu desktop */}
          <div className="hidden sm:flex sm:space-x-6">
            {navigation.map((item) => {
              const isActive = pathname === item.href;
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  prefetch
                  className={`group flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-all duration-300 ${
                    isActive ? 'bg-blue-100 text-blue-700' : 'text-gray-600 hover:bg-gray-100'
                  }`}
                >
                  <Icon className={`w-5 h-5 ${isActive ? 'text-blue-600' : 'text-gray-400 group-hover:text-gray-600'}`} />
                  {item.name}
                </Link>
              );
            })}
          </div>

          {/* User actions desktop */}
          <div className="hidden sm:flex sm:items-center">
            {isAuthenticated && user ? (
              <button
                onClick={handleLogout}
                className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-md"
              >
                <ArrowRightOnRectangleIcon className="w-5 h-5 text-gray-400" />
                Déconnexion
              </button>
            ) : (
              <div className="flex items-center space-x-4">
                <Link href="/login" className="text-sm text-gray-600 hover:text-gray-900">Connexion</Link>
                <Link href="/register" className="text-sm text-white bg-blue-600 px-4 py-2 rounded-md hover:bg-blue-700">Inscription</Link>
              </div>
            )}
          </div>

          {/* Mobile menu button */}
          <div className="sm:hidden">
            <button
              onClick={() => setMenuOpen(!menuOpen)}
              className="text-gray-700 hover:text-gray-900 focus:outline-none"
            >
              {menuOpen ? <XMarkIcon className="w-6 h-6" /> : <Bars3Icon className="w-6 h-6" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu drawer */}
      {menuOpen && (
        <div className="sm:hidden px-4 pt-2 pb-4 space-y-1 bg-white border-t border-gray-200">
          {navigation.map((item) => {
            const isActive = pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                href={item.href}
                prefetch
                className={`group flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-all duration-300 ${
                  isActive ? 'bg-blue-100 text-blue-700' : 'text-gray-600 hover:bg-gray-100'
                }`}
                onClick={() => setMenuOpen(false)}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'text-blue-600' : 'text-gray-400 group-hover:text-gray-600'}`} />
                {item.name}
              </Link>
            );
          })}
          {/* Mobile user actions */}
          {isAuthenticated && user ? (
            <button
              onClick={() => {
                handleLogout();
                setMenuOpen(false);
              }}
              className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-md w-full"
            >
              <ArrowRightOnRectangleIcon className="w-5 h-5 text-gray-400" />
              Déconnexion
            </button>
          ) : (
            <>
              <Link href="/login" onClick={() => setMenuOpen(false)} className="block text-sm px-3 py-2 text-gray-600 hover:bg-gray-100 rounded-md">Connexion</Link>
              <Link href="/register" onClick={() => setMenuOpen(false)} className="block text-sm px-3 py-2 text-white bg-blue-600 rounded-md text-center">Inscription</Link>
            </>
          )}
        </div>
      )}
    </nav>
  );
}
