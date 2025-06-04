async function userRoutes(fastify, options) {

  // GET /users/firebase/:firebaseUID - Profil utilisateur
  fastify.get('/users/firebase/:firebaseUID', {
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
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez consulter que votre propre profil'
      })
      return
    }
    
    try {
      fastify.log.info(`🔍 Recherche user: ${firebaseUID}`)
      
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: {
          coach: {
            select: {
              id: true,
              displayName: true,
              specialization: true
            }
          }
        }
      })
      
      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        })
        return
      }
      
      return {
        id: user.id,
        firebaseUID: user.firebaseUID,
        email: user.email,
        displayName: user.displayName,
        coachId: user.coachId,
        coach: user.coach,
        createdAt: user.createdAt.toISOString(),
        updatedAt: user.updatedAt.toISOString()
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la récupération utilisateur:', {
        message: error.message,
        stack: error.stack,
        firebaseUID
      })
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // POST /users - Créer nouvel utilisateur
  fastify.post('/users', {
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
    
    try {
      fastify.log.info(`✨ Création user: ${userData.firebaseUID}`)
      
      // Vérifier si l'utilisateur existe déjà
      const existingUser = await fastify.prisma.user.findUnique({
        where: { firebaseUID: userData.firebaseUID }
      })
      
      if (existingUser) {
        reply.code(409).send({
          success: false,
          error: 'Utilisateur déjà existant'
        })
        return
      }
      
      // Créer l'utilisateur
      const newUser = await fastify.prisma.user.create({
        data: {
          firebaseUID: userData.firebaseUID,
          email: userData.email,
          displayName: userData.displayName
        }
      })
      
      reply.code(201)
      return {
        id: newUser.id,
        firebaseUID: newUser.firebaseUID,
        email: newUser.email,
        displayName: newUser.displayName,
        coachId: newUser.coachId,
        createdAt: newUser.createdAt.toISOString(),
        updatedAt: newUser.updatedAt.toISOString()
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la création utilisateur:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // PUT /users/firebase/:firebaseUID - Mettre à jour utilisateur
  fastify.put('/users/firebase/:firebaseUID', {
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
    
    try {
      fastify.log.info(`📝 Mise à jour user: ${firebaseUID}`)
      
      const updatedUser = await fastify.prisma.user.update({
        where: { firebaseUID },
        data: {
          email: updateData.email,
          displayName: updateData.displayName
        }
      })
      
      return {
        id: updatedUser.id,
        firebaseUID: updatedUser.firebaseUID,
        email: updatedUser.email,
        displayName: updatedUser.displayName,
        coachId: updatedUser.coachId,
        createdAt: updatedUser.createdAt.toISOString(),
        updatedAt: updatedUser.updatedAt.toISOString()
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la mise à jour utilisateur:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // GET /users/firebase/:firebaseUID/personal-templates
  fastify.get('/users/firebase/:firebaseUID/personal-templates', {
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
    
    try {
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: {
          personalTemplates: {
            include: {
              exercises: {
                include: {
                  exercise: true
                },
                orderBy: {
                  order: 'asc'
                }
              }
            }
          }
        }
      })
      
      if (!user) {
        reply.code(404).send({ success: false, error: 'Utilisateur non trouvé' })
        return
      }
      
      return {
        success: true,
        data: user.personalTemplates
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des templates:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // GET /users/firebase/:firebaseUID/assigned-templates
  fastify.get('/users/firebase/:firebaseUID/assigned-templates', {
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
    
    try {
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: {
          assignedTemplates: {
            include: {
              coach: {
                select: {
                  displayName: true,
                  specialization: true
                }
              },
              exercises: {
                include: {
                  exercise: true
                },
                orderBy: {
                  order: 'asc'
                }
              }
            }
          }
        }
      })
      
      if (!user) {
        reply.code(404).send({ success: false, error: 'Utilisateur non trouvé' })
        return
      }
      
      return {
        success: true,
        data: user.assignedTemplates
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des templates assignés:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })
}

module.exports = userRoutes 