const fp = require('fastify-plugin')

async function authMiddleware(fastify, options) {
  fastify.addHook('preHandler', async (request, reply) => {
    // Skip auth pour les routes publiques
    const publicRoutes = [
      '/api/v1/health',
      '/docs',
      '/',
      '/favicon.ico'
    ]
    
    const isPublicRoute = publicRoutes.some(route => 
      request.url === route || request.url.startsWith('/docs')
    )
    
    if (isPublicRoute) {
      return
    }

    const firebaseUID = request.headers['x-firebase-uid']
    const firebaseEmail = request.headers['x-firebase-email']

    if (!firebaseUID) {
      reply.code(401).send({
        success: false,
        error: 'Firebase UID manquant dans les headers',
        message: 'Veuillez vous authentifier avec Firebase'
      })
      return
    }

    // Validation basique de l'UID (Firebase UIDs sont généralement de 28 caractères)
    if (firebaseUID.length < 10) {
      reply.code(401).send({
        success: false,
        error: 'Firebase UID invalide',
        message: 'L\'UID Firebase semble invalide'
      })
      return
    }

    // Ajouter l'utilisateur au request pour l'utiliser dans les routes
    request.user = {
      firebaseUID,
      email: firebaseEmail
    }

    fastify.log.info(`🔐 Auth: ${firebaseUID} (${firebaseEmail || 'no email'})`)
  })
}

module.exports = fp(authMiddleware) 