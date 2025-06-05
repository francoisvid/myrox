// Routes pour les exercices
async function exerciseRoutes(fastify, options) {
  // GET /exercises - Liste tous les exercices disponibles
  fastify.get('/exercises', {
    schema: {
      description: 'Liste de tous les exercices disponibles',
      tags: ['Exercises'],
      response: {
        200: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              name: { type: 'string' },
              description: { type: 'string' },
              category: { type: 'string' },
              equipment: { type: 'array', items: { type: 'string' } },
              instructions: { type: 'string' },
              isHyroxExercise: { type: 'boolean' }
            }
          }
        }
      }
    }
  }, async (request, reply) => {
    try {
      const exercises = await fastify.prisma.exercise.findMany({
        orderBy: {
          name: 'asc'
        }
      })
      
      return exercises
      
    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des exercices:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })
}

module.exports = exerciseRoutes 