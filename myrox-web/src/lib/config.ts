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
  
  // Default values
  defaults: {
    firebaseUID: 'FkCwkLcLLYhH2RCOyOs4J0Rl28G2', // TODO: Get from Firebase Auth context
    coachId: '888346a9-b2bc-488f-8766-83deea97de8d'
  }
};

export default config; 