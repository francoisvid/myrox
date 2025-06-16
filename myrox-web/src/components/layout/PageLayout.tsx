import { ReactNode } from 'react';

interface PageLayoutProps {
  children: ReactNode;
  title?: string;
  description?: string;
  actions?: ReactNode;
  loading?: boolean;
}

// Skeleton pour le header de page
function PageHeaderSkeleton() {
  return (
    <header className="bg-white shadow animate-pulse">
      <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center">
          <div>
            <div className="h-8 bg-gray-200 rounded w-48 mb-2"></div>
            <div className="h-4 bg-gray-200 rounded w-64"></div>
          </div>
          <div className="h-10 bg-gray-200 rounded w-32"></div>
        </div>
      </div>
    </header>
  );
}

export default function PageLayout({ 
  children, 
  title, 
  description, 
  actions, 
  loading = false 
}: PageLayoutProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      {loading ? (
        <PageHeaderSkeleton />
      ) : (
        <header className="bg-white shadow">
          <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between items-center">
              {title && (
                <div>
                  <h1 className="text-3xl font-bold text-gray-900">{title}</h1>
                  {description && (
                    <p className="mt-1 text-sm text-gray-500">{description}</p>
                  )}
                </div>
              )}
              {actions && (
                <div className="flex items-center space-x-4">
                  {actions}
                </div>
              )}
            </div>
          </div>
        </header>
      )}

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
} 
