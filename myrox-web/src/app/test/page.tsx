'use client';

import { useState, useEffect } from 'react';
import { config } from '@/lib/config';

export default function TestPage() {
  const [apiStatus, setApiStatus] = useState('Testing...');
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const testAPI = async () => {
      try {
        setApiStatus('Calling API...');
        
        const response = await fetch(`${config.api.fullUrl}/coaches/${config.defaults.coachId}/stats/detailed`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'x-firebase-uid': config.defaults.firebaseUID
          }
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();
        setData(result);
        setApiStatus('✅ API Connected!');
      } catch (err) {
        console.error('API Test Error:', err);
        setError(err instanceof Error ? err.message : 'Unknown error');
        setApiStatus('❌ API Failed');
      }
    };

    testAPI();
  }, []);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">API Test Page</h1>
        
        <div className="bg-white p-6 rounded-lg shadow mb-6">
          <h2 className="text-xl font-semibold mb-4">Status: {apiStatus}</h2>
          
          {error && (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
              <strong>Error:</strong> {error}
            </div>
          )}
          
          {data && (
            <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
              <h3 className="font-semibold">API Response Summary:</h3>
              <ul className="mt-2">
                <li>Total Workouts: {data.summary?.totalWorkouts}</li>
                <li>Average Rating: {data.summary?.avgRating}</li>
                <li>Active Athletes: {data.summary?.activeAthletes}</li>
                <li>Completion Rate: {data.summary?.avgCompletionRate}%</li>
              </ul>
              
              <h3 className="font-semibold mt-4">Athletes:</h3>
              <ul className="mt-2">
                {data.athleteStats?.map((athlete: any, index: number) => (
                  <li key={index}>
                    {athlete.athleteName}: {athlete.totalWorkouts} workouts (Rate: {athlete.completionRate}%)
                  </li>
                ))}
              </ul>
            </div>
          )}
          
          <div className="mt-4">
            <h3 className="font-semibold">Debug Info:</h3>
            <p>API URL: {config.api.fullUrl}/coaches/{config.defaults.coachId}/stats/detailed</p>
            <p>Firebase UID: {config.defaults.firebaseUID}</p>
            <p>Environment: {config.isDevelopment ? 'Development' : 'Production'}</p>
          </div>
        </div>
      </div>
    </div>
  );
} 