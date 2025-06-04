async function coachRoutes(fastify, options) {

  // GET /coaches/:id - Informations du coach (lecture seule)
  fastify.get('/:id', {
    schema: {
      description: 'Récupérer les informations publiques d\'un coach',
      tags: ['Coaches'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        },
        required: ['id']
      },
      response: {
        200: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            email: { type: 'string' },
            bio: { type: 'string' },
            certifications: {
              type: 'array',
              items: { type: 'string' }
            },
            profilePicture: { type: 'string' },
            createdAt: { type: 'string' },
            isActive: { type: 'boolean' }
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
    const { id } = request.params
    
    fastify.log.info(`👨‍🏫 Recherche coach: ${id}`)
    
    // TODO: Requête base de données pour récupérer les infos du coach
    
    // Mock data pour test
    if (id === 'coach-not-found') {
      reply.code(404).send({
        success: false,
        error: 'Coach non trouvé'
      })
      return
    }
    
    // Mock coach info
    return {
      id: id,
      name: "Coach Expert",
      email: "coach@myrox.app",
      bio: "Coach certifié HYROX avec 5 ans d'expérience dans l'entraînement fonctionnel",
      certifications: [
        "HYROX Master Trainer",
        "CrossFit Level 2",
        "Nutrition Sportive"
      ],
      profilePicture: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300",
      createdAt: "2023-01-15T00:00:00.000Z",
      isActive: true
    }
  })

  // GET /coaches/:id/athletes - Athletes du coach (pour plus tard, web only)
  fastify.get('/:id/athletes', {
    schema: {
      description: 'Liste des athlètes d\'un coach (access web uniquement)',
      tags: ['Coaches'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      },
      response: {
        403: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            error: { type: 'string' },
            message: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    // Cette route sera uniquement accessible via l'interface web
    // L'app iOS ne doit pas y avoir accès
    
    reply.code(403).send({
      success: false,
      error: 'Accès interdit depuis l\'app mobile',
      message: 'Cette fonctionnalité est réservée à l\'interface web coach'
    })
  })

  // GET /coaches/:id/statistics - Stats du coach (pour plus tard, web only)
  fastify.get('/:id/statistics', {
    schema: {
      description: 'Statistiques du coach (access web uniquement)',
      tags: ['Coaches'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      },
      response: {
        403: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            error: { type: 'string' },
            message: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    // Cette route sera uniquement accessible via l'interface web
    
    reply.code(403).send({
      success: false,
      error: 'Accès interdit depuis l\'app mobile',
      message: 'Cette fonctionnalité est réservée à l\'interface web coach'
    })
  })
}

module.exports = coachRoutes 