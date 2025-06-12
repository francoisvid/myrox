export const config = {
  // API Configuration
  api: {
    baseUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
    version: 'v1',
    get fullUrl() {
      return `${this.baseUrl}/api/${this.version}`;
    }
  },
  
  // Environment
  isDevelopment: process.env.NODE_ENV === 'development',
  isProduction: process.env.NODE_ENV === 'production',
  
  // Default values - ATTENTION: À utiliser uniquement comme fallback
  // L'application doit maintenant utiliser l'utilisateur connecté via useCoachId()
  defaults: {
    firebaseUID: 'coach-master-456', // ⚠️ Fallback uniquement - utiliser useCoachId()
    coachId: 'ba031335-1c73-4a3a-b296-f4d19a6a18f7' // ⚠️ Fallback uniquement - utiliser useCoachId()
  }
};

export default config; 