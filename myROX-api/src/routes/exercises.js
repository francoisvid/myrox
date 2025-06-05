const fastify = require('fastify')({ logger: true })
const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

/**
 * Routes pour la gestion des exercices
 */
async function exerciseRoutes(fastify, options) {
  
  // GET /exercises - Récupérer tous les exercices
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
      console.log('📋 GET /exercises - Récupération de tous les exercices')
      
      const exercises = await fastify.prisma.exercise.findMany({
        orderBy: {
          name: 'asc'
        }
      })
      
      console.log(`✅ ${exercises.length} exercices trouvés`)
      return exercises
      
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des exercices:', error)
      reply.status(500).send({
        error: 'Erreur serveur lors de la récupération des exercices',
        details: error.message
      })
    }
  })
  
  // GET /exercises/:id - Récupérer un exercice spécifique
  fastify.get('/exercises/:id', {
    schema: {
      description: 'Récupérer un exercice spécifique par son ID',
      tags: ['Exercises'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', description: 'ID de l\'exercice' }
        },
        required: ['id']
      },
      response: {
        200: {
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
        },
        404: {
          type: 'object',
          properties: {
            error: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    try {
      const { id } = request.params
      console.log(`📋 GET /exercises/${id} - Récupération exercice spécifique`)
      
      const exercise = await fastify.prisma.exercise.findUnique({
        where: { id: id }
      })
      
      if (!exercise) {
        console.log(`❌ Exercice ${id} non trouvé`)
        return reply.status(404).send({
          error: 'Exercice non trouvé'
        })
      }
      
      console.log(`✅ Exercice trouvé: ${exercise.name}`)
      return exercise
      
    } catch (error) {
      console.error('❌ Erreur lors de la récupération de l\'exercice:', error)
      reply.status(500).send({
        error: 'Erreur serveur lors de la récupération de l\'exercice',
        details: error.message
      })
    }
  })
}

module.exports = exerciseRoutes 