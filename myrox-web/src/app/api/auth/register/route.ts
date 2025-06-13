import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { firebaseUID, email, userType, displayName, specialization, bio, certifications } = body;

    // Récupérer l'URL de l'API depuis les variables d'environnement
    // Utiliser l'URL interne pour les appels serveur-à-serveur depuis Docker
    const apiUrl = process.env.API_INTERNAL_URL || 'http://api:3000';

    // Faire appel à l'API Fastify
    const response = await fetch(`${apiUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-firebase-uid': firebaseUID,
        'x-firebase-email': email
      },
      body: JSON.stringify({
        firebaseUID,
        email,
        userType,
        displayName,
        specialization,
        bio,
        certifications
      })
    });

    const data = await response.json();

    if (!response.ok) {
      return NextResponse.json(
        { error: data.error || 'Erreur lors de l\'inscription' },
        { status: response.status }
      );
    }

    return NextResponse.json(data, { status: 201 });

  } catch (error) {
    console.error('Erreur API inscription:', error);
    return NextResponse.json(
      { error: 'Erreur interne du serveur' },
      { status: 500 }
    );
  }
} 