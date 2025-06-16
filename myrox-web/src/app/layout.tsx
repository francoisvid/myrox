"use client";

import { Geist, Geist_Mono } from "next/font/google";
import Navigation from "@/components/layout/Navigation";
import "./globals.css";
import { usePathname } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

// export const metadata: Metadata = {
//   title: "myROX Coach Dashboard",
//   description: "Dashboard pour les coachs myROX - Gérez vos athlètes et templates d'entraînement",
// };

function AuthGate({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, loading } = useAuth();
  const pathname = usePathname();

  // Routes publiques qui ne nécessitent pas d'auth
  const publicRoutes = ['/login', '/register'];
  const isPublic = publicRoutes.some((route) => pathname.startsWith(route));

  if (isPublic) {
    return <>{children}</>;
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Chargement...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">Authentification requise</h1>
          <p className="text-gray-600">Veuillez vous connecter pour accéder à cette page.</p>
            <div className="mt-6">
                <a
                href="/login"
                className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                >
                Se connecter
                </a>
            </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
        suppressHydrationWarning={true}
      >
        <Navigation />
        <AuthGate>
          {children}
        </AuthGate>
      </body>
    </html>
  );
}
