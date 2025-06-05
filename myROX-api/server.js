const fastify = require('fastify')({ logger: true })
const { PrismaClient } = require('@prisma/client')

// Configuration des variables d'environnement
require('dotenv').config()
const PORT = process.env.PORT || 3000
const NODE_ENV = process.env.NODE_ENV || 'development'

// Initialiser Prisma
const prisma = new PrismaClient()

// Plugin pour Prisma - Rendre accessible globalement
fastify.decorate('prisma', prisma)

fastify.addHook('onClose', async () => {
  await prisma.$disconnect()
})

// Configuration CORS
fastify.register(require('@fastify/cors'), {
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
})

// Middleware d'authentification Firebase UID
fastify.register(require('./src/middleware/auth'))

// Documentation Swagger
fastify.register(require('@fastify/swagger'), {
  openapi: {
    info: { 
      title: 'myROX API', 
      version: '1.0.0',
      description: 'API REST pour l\'application myROX - Fitness & HYROX'
    },
    servers: [{ url: 'http://localhost:3000' }],
    components: {
      securitySchemes: {
        FirebaseUID: {
          type: 'apiKey',
          in: 'header',
          name: 'x-firebase-uid'
        }
      }
    }
  }
})

fastify.register(require('@fastify/swagger-ui'), {
  routePrefix: '/docs',
  uiConfig: {
    docExpansion: 'list',
    deepLinking: false
  }
})

// Routes
fastify.register(require('./src/routes/health'), { prefix: '/api/v1' })
fastify.register(require('./src/routes/users'), { prefix: '/api/v1' })
fastify.register(require('./src/routes/coaches'), { prefix: '/api/v1' })
fastify.register(require('./src/routes/exercises'), { prefix: '/api/v1' })

// Route racine
fastify.get('/', async (request, reply) => {
  return {
    message: '🚀 myROX API',
    version: '1.0.0',
    environment: NODE_ENV,
    endpoints: {
      health: '/api/v1/health',
      docs: '/docs',
      swagger: '/docs/json'
    }
  }
})

// Gestionnaire d'erreur global
fastify.setErrorHandler(async (error, request, reply) => {
  const statusCode = error.statusCode || 500
  
  fastify.log.error({
    error: error.message,
    stack: error.stack,
    request: {
      method: request.method,
      url: request.url,
      headers: request.headers
    }
  })

  return reply.status(statusCode).send({
    error: true,
    message: statusCode === 500 ? 'Internal Server Error' : error.message,
    statusCode,
    timestamp: new Date().toISOString()
  })
})

// Démarrer le serveur
const start = async () => {
  try {
    // Test de connexion à la base de données
    await prisma.$connect()
    fastify.log.info('✅ Connexion à la base de données établie')
    
    // Démarrer le serveur
    await fastify.listen({ 
      port: PORT, 
      host: NODE_ENV === 'development' ? '0.0.0.0' : '127.0.0.1' 
    })
    
    fastify.log.info(`🚀 myROX API démarrée sur http://localhost:${PORT}`)
    fastify.log.info(`📖 Documentation: http://localhost:${PORT}/docs`)
    
  } catch (err) {
    fastify.log.error('❌ Erreur au démarrage:', err)
    await prisma.$disconnect()
    process.exit(1)
  }
}

// Gestion propre de l'arrêt
process.on('SIGINT', async () => {
  fastify.log.info('🛑 Arrêt du serveur...')
  await fastify.close()
  await prisma.$disconnect()
  process.exit(0)
})

process.on('SIGTERM', async () => {
  fastify.log.info('🛑 Arrêt du serveur...')
  await fastify.close()
  await prisma.$disconnect()
  process.exit(0)
})

start() 