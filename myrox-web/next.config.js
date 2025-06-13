/** @type {import('next').NextConfig} */
const nextConfig = {
    eslint: {
      ignoreDuringBuilds: true,
    },
    typescript: {
      ignoreBuildErrors: true,
    },
    serverExternalPackages: ['firebase'],
    output: 'standalone',
    env: {
      NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || "https://api.myrox.fr",
      NEXT_PUBLIC_FIREBASE_API_KEY: "AIzaSyCtFy5lkgR1qga65tbqHuBb-cJgrS-7Lvw",
      NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN: "myrox-6fc29.firebaseapp.com",
      NEXT_PUBLIC_FIREBASE_PROJECT_ID: "myrox-6fc29",
      NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET: "myrox-6fc29.firebasestorage.app",
      NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID: "251542675344",
      NEXT_PUBLIC_FIREBASE_APP_ID: "1:251542675344:web:66d4cdebed993e487f1d15",
    }
  }
  
  module.exports = nextConfig