// Charger les variables d'environnement
require('dotenv').config()

const fastify = require('fastify')({
  logger: {
    level: 'info',
    transport: {
      target: 'pino-pretty',
      options: {
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname',
      },
    },
  }
})

// Variables d'environnement avec fallback
const config = {
  PORT: process.env.PORT || '3000',
  NODE_ENV: process.env.NODE_ENV || 'development',
  DATABASE_URL: process.env.DATABASE_URL || 'postgresql://user:password@localhost:5432/myrox_db'
}

// Plugins de sécurité et CORS
fastify.register(require('@fastify/helmet'))
fastify.register(require('@fastify/cors'), {
  origin: config.NODE_ENV === 'production' ? false : true,
  credentials: true
})

// Documentation API Swagger
fastify.register(require('@fastify/swagger'), {
  swagger: {
    info: {
      title: 'myROX API',
      description: 'API Backend pour l\'application myROX - Fitness & HYROX Training',
      version: '1.0.0'
    },
    host: 'localhost:3000',
    schemes: ['http'],
    consumes: ['application/json'],
    produces: ['application/json'],
    tags: [
      { name: 'Health', description: 'Health check endpoints' },
      { name: 'Users', description: 'User management' },
      { name: 'Coaches', description: 'Coach information' },
      { name: 'Templates', description: 'Workout templates' },
      { name: 'Workouts', description: 'Workout tracking' }
    ]
  }
})

fastify.register(require('@fastify/swagger-ui'), {
  routePrefix: '/docs',
  uiConfig: {
    docExpansion: 'full',
    deepLinking: false
  },
  uiHooks: {
    onRequest: function (request, reply, next) { next() },
    preHandler: function (request, reply, next) { next() }
  },
  staticCSP: true,
  transformStaticCSP: (header) => header
})

// Middleware d'authentification Firebase UID
fastify.register(require('./src/middleware/auth'))

// Routes
fastify.register(require('./src/routes/health'), { prefix: '/api/v1' })
fastify.register(require('./src/routes/users'), { prefix: '/api/v1/users' })
fastify.register(require('./src/routes/coaches'), { prefix: '/api/v1/coaches' })

// Route racine
fastify.get('/', async (request, reply) => {
  return {
    message: '🚀 myROX API is running!',
    version: '1.0.0',
    endpoints: {
      health: '/api/v1/health',
      docs: '/docs',
      users: '/api/v1/users',
      coaches: '/api/v1/coaches'
    }
  }
})

// Démarrage du serveur
const start = async () => {
  try {
    await fastify.listen({ 
      port: parseInt(config.PORT),
      host: '0.0.0.0'
    })
    
    console.log(`🚀 myROX API running on http://localhost:${config.PORT}`)
    console.log(`📚 Documentation: http://localhost:${config.PORT}/docs`)
    console.log(`🏥 Health Check: http://localhost:${config.PORT}/api/v1/health`)
    console.log(`🌍 Environment: ${config.NODE_ENV}`)
    
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}

// Gestion propre de l'arrêt
process.on('SIGINT', async () => {
  console.log('\n🛑 Arrêt du serveur...')
  await fastify.close()
  process.exit(0)
})

start() 