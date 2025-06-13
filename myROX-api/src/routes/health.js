async function healthRoutes(fastify, options) {
  
  fastify.get('/health', {
    schema: {
      description: 'Health check endpoint - Vérifier l\'état de l\'API',
      tags: ['Health'],
      response: {
        200: {
          type: 'object',
          properties: {
            status: { type: 'string' },
            timestamp: { type: 'string' },
            version: { type: 'string' },
            uptime: { type: 'number' },
            environment: { type: 'string' },
            message: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const startTime = Date.now()
    
    // Simuler une vérification de base de données (plus tard)
    const dbStatus = 'connected' // TODO: Vrai check DB
    
    const responseTime = Date.now() - startTime
    
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      uptime: Math.floor(process.uptime()),
      environment: process.env.NODE_ENV || 'development',
      message: '🚀 myROX API is healthy!',
      checks: {
        database: dbStatus,
        responseTime: `${responseTime}ms`
      }
    }
  })

  // Endpoint de ping simple
  fastify.get('/ping', {
    schema: {
      description: 'Simple ping endpoint',
      tags: ['Health'],
      response: {
        200: {
          type: 'object',
          properties: {
            message: { type: 'string' },
            timestamp: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    return {
      message: 'pong',
      timestamp: new Date().toISOString()
    }
  })
}

module.exports = healthRoutes 