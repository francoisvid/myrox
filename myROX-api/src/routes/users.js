async function userRoutes(fastify, options) {

  // GET /users/firebase/:firebaseUID - Profil utilisateur
  fastify.get('/firebase/:firebaseUID', {
    schema: {
      description: 'Récupérer le profil utilisateur par Firebase UID',
      tags: ['Users'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        },
        required: ['firebaseUID']
      },
      response: {
        200: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            firebaseUID: { type: 'string' },
            email: { type: 'string' },
            displayName: { type: 'string' },
            coachId: { type: 'string' },
            createdAt: { type: 'string' },
            updatedAt: { type: 'string' }
          }
        },
        404: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            error: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    
    // Vérifier que l'utilisateur demande son propre profil
    if (request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez consulter que votre propre profil'
      })
      return
    }
    
    fastify.log.info(`🔍 Recherche user: ${firebaseUID}`)
    
    // TODO: Requête base de données
    // Pour l'instant, mock response basée sur l'UID
    
    // Simuler user not found pour test
    if (firebaseUID === 'user-not-found') {
      reply.code(404).send({
        success: false,
        error: 'Utilisateur non trouvé'
      })
      return
    }
    
    // Simuler user avec coach
    const hasCoach = firebaseUID.includes('coached')
    
    return {
      id: "550e8400-e29b-41d4-a716-446655440000",
      firebaseUID: firebaseUID,
      email: request.user.email || "athlete@myrox.app",
      displayName: "Athlète Test",
      coachId: hasCoach ? "coach-uuid-123" : null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }
  })

  // POST /users - Créer nouvel utilisateur
  fastify.post('/', {
    schema: {
      description: 'Créer un nouveau profil utilisateur',
      tags: ['Users'],
      body: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' },
          email: { type: 'string' },
          displayName: { type: 'string' }
        },
        required: ['firebaseUID']
      },
      response: {
        201: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            firebaseUID: { type: 'string' },
            email: { type: 'string' },
            displayName: { type: 'string' },
            coachId: { type: 'string' },
            createdAt: { type: 'string' },
            updatedAt: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const userData = request.body
    
    // Vérifier que l'utilisateur crée son propre profil
    if (request.user.firebaseUID !== userData.firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez créer que votre propre profil'
      })
      return
    }
    
    fastify.log.info(`✨ Création user: ${userData.firebaseUID}`)
    
    // TODO: Vérifier si l'utilisateur existe déjà
    // TODO: Sauvegarder en base de données
    
    reply.code(201)
    return {
      id: "new-user-" + Date.now(),
      firebaseUID: userData.firebaseUID,
      email: userData.email || request.user.email,
      displayName: userData.displayName || "Nouvel Athlète",
      coachId: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }
  })

  // PUT /users/firebase/:firebaseUID - Mettre à jour utilisateur
  fastify.put('/firebase/:firebaseUID', {
    schema: {
      description: 'Mettre à jour le profil utilisateur',
      tags: ['Users'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        },
        required: ['firebaseUID']
      },
      body: {
        type: 'object',
        properties: {
          displayName: { type: 'string' },
          email: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    const updateData = request.body
    
    // Vérifier que l'utilisateur modifie son propre profil
    if (request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      })
      return
    }
    
    fastify.log.info(`📝 Mise à jour user: ${firebaseUID}`)
    
    // TODO: Mettre à jour en base de données
    
    return {
      id: "550e8400-e29b-41d4-a716-446655440000",
      firebaseUID: firebaseUID,
      email: updateData.email || request.user.email,
      displayName: updateData.displayName || "Athlète Mis à Jour",
      coachId: null,
      createdAt: "2024-01-01T00:00:00.000Z",
      updatedAt: new Date().toISOString()
    }
  })

  // GET /users/firebase/:firebaseUID/personal-templates
  fastify.get('/firebase/:firebaseUID/personal-templates', {
    schema: {
      description: 'Templates créés par l\'utilisateur',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    
    if (request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({ success: false, error: 'Accès interdit' })
      return
    }
    
    fastify.log.info(`📋 Templates personnels: ${firebaseUID}`)
    
    // TODO: Implement - Récupérer templates depuis DB
    return []
  })

  // GET /users/firebase/:firebaseUID/assigned-templates  
  fastify.get('/firebase/:firebaseUID/assigned-templates', {
    schema: {
      description: 'Templates assignés par le coach',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    
    if (request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({ success: false, error: 'Accès interdit' })
      return
    }
    
    fastify.log.info(`🏃‍♂️ Templates assignés: ${firebaseUID}`)
    
    // TODO: Implement - Récupérer templates assignés depuis DB
    return []
  })

  // GET /users/firebase/:firebaseUID/workouts
  fastify.get('/firebase/:firebaseUID/workouts', {
    schema: {
      description: 'Historique des workouts de l\'utilisateur',
      tags: ['Workouts'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    
    if (request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({ success: false, error: 'Accès interdit' })
      return
    }
    
    fastify.log.info(`💪 Workouts: ${firebaseUID}`)
    
    // TODO: Implement - Récupérer workouts depuis DB
    return []
  })
}

module.exports = userRoutes 