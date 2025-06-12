import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ firebaseUID: string }> }
) {
  try {
    const { firebaseUID } = await context.params;

    // Utiliser l'URL interne pour les appels serveur-à-serveur depuis Docker
    const apiUrl = process.env.API_INTERNAL_URL || 'http://api:3000';
    
    console.log('🔍 URL API utilisée:', apiUrl);

    const fullUrl = `${apiUrl}/api/v1/auth/user-type/${firebaseUID}`;
    console.log('🌐 Appel API vers:', fullUrl);

    // Faire appel à l'API Fastify avec les headers Firebase requis
    const response = await fetch(fullUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'x-firebase-uid': firebaseUID,
        'x-firebase-email': '' // On n'a pas l'email ici, mais l'UID suffit pour cette route
      }
    });

    const data = await response.json();

    if (!response.ok) {
      console.log('❌ Réponse API non OK:', response.status, data);
      return NextResponse.json(
        { exists: false },
        { status: response.status }
      );
    }

    console.log('✅ Réponse API OK:', data);
    return NextResponse.json(data);

  } catch (error) {
    console.error('❌ Erreur API vérification utilisateur:', error);
    return NextResponse.json(
      { exists: false },
      { status: 500 }
    );
  }
} 