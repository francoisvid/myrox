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
      
      return user.personalTemplates.map(template => ({
        ...template,
        userId: template.creatorId,
        creatorId: undefined
      }))
      
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
      
      return user.assignedTemplates.map(template => ({
        ...template,
        userId: template.creatorId,
        creatorId: undefined
      }))
      
    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des templates assignés:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // POST /users/firebase/:firebaseUID/personal-templates - Créer un template personnel
  fastify.post('/users/firebase/:firebaseUID/personal-templates', {
    schema: {
      description: 'Créer un nouveau template personnel',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          description: { type: 'string' },
          rounds: { type: 'integer', minimum: 1 },
          difficulty: { type: 'string', enum: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'] },
          category: { type: 'string', enum: ['HYROX', 'FUNCTIONAL', 'STRENGTH', 'CARDIO', 'FLEXIBILITY', 'MIXED'] },
          estimatedTime: { type: 'integer', minimum: 1 },
          exercises: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                exerciseId: { type: 'string' },
                order: { type: 'integer', minimum: 0 },
                sets: { type: 'integer' },
                targetRepetitions: { type: 'integer' },
                targetTime: { type: 'integer' },
                targetDistance: { type: 'integer' },
                weight: { type: 'number' },
                restTime: { type: 'integer' }
              },
              required: ['exerciseId', 'order']
            }
          }
        },
        required: ['name', 'rounds']
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    const templateData = request.body
    
    if (request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({ success: false, error: 'Accès interdit' })
      return
    }
    
    try {
      fastify.log.info(`✨ Création template pour user: ${firebaseUID}`)
      
      // Vérifier que l'utilisateur existe et vérifier s'il est coach
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: {
          coachProfile: true // Inclure le profil coach s'il existe
        }
      })
      
      if (!user) {
        reply.code(404).send({ success: false, error: 'Utilisateur non trouvé' })
        return
      }
      
      // Déterminer si c'est un template personnel ou de coach
      const isCoach = !!user.coachProfile
      const coachId = isCoach ? user.coachProfile.id : null
      
      fastify.log.info(`📋 Utilisateur ${user.displayName} - Coach: ${isCoach}, CoachId: ${coachId}`)
      
      // Préparer les données du template
      const templateCreateData = {
        name: templateData.name,
        rounds: templateData.rounds || 1,
        description: templateData.description || null,
        difficulty: templateData.difficulty || 'BEGINNER',
        category: templateData.category || 'FUNCTIONAL',
        estimatedTime: templateData.estimatedTime || 30,
        creatorId: user.id,
        coachId: coachId,
        isPersonal: !isCoach // Si c'est un coach, ce n'est pas personnel
      }
      
      // Créer le template avec les exercices
      const newTemplate = await fastify.prisma.template.create({
        data: {
          ...templateCreateData,
          exercises: {
            create: templateData.exercises?.map(exercise => ({
              exerciseId: exercise.exerciseId,
              order: exercise.order,
              sets: exercise.sets,
              reps: exercise.targetRepetitions,
              duration: exercise.targetTime,
              distance: exercise.targetDistance,
              weight: exercise.weight,
              restTime: exercise.restTime
            })) || []
          }
        },
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
      })
      
      fastify.log.info(`✅ Template créé: ${newTemplate.id}`)
      
      reply.code(201)
      return {
        ...newTemplate,
        userId: newTemplate.creatorId,
        creatorId: undefined
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la création du template:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // PUT /users/firebase/:firebaseUID/personal-templates/:templateId - Mettre à jour un template personnel
  fastify.put('/users/firebase/:firebaseUID/personal-templates/:templateId', {
    schema: {
      description: 'Mettre à jour un template personnel',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' },
          templateId: { type: 'string' }
        },
        required: ['firebaseUID', 'templateId']
      },
      body: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          description: { type: 'string' },
          rounds: { type: 'integer', minimum: 1 },
          difficulty: { type: 'string', enum: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'] },
          category: { type: 'string', enum: ['HYROX', 'FUNCTIONAL', 'STRENGTH', 'CARDIO', 'FLEXIBILITY', 'MIXED'] },
          estimatedTime: { type: 'integer', minimum: 1 },
          exercises: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                exerciseId: { type: 'string' },
                order: { type: 'integer', minimum: 0 },
                sets: { type: 'integer' },
                targetRepetitions: { type: 'integer' },
                targetTime: { type: 'integer' },
                targetDistance: { type: 'integer' },
                weight: { type: 'number' },
                restTime: { type: 'integer' }
              },
              required: ['exerciseId', 'order']
            }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID, templateId } = request.params
    const updateData = request.body
    
    // Normaliser l'ID en minuscules pour être insensible à la casse
    const normalizedTemplateId = templateId.toLowerCase()
    
    if (request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({ success: false, error: 'Accès interdit' })
      return
    }
    
    try {
      fastify.log.info(`📝 Mise à jour template: ${normalizedTemplateId} pour user: ${firebaseUID}`)
      
      // Logs détaillés des données reçues
      fastify.log.info(`📋 Données reçues:`)
      fastify.log.info(`   - name: ${updateData.name}`)
      fastify.log.info(`   - rounds: ${updateData.rounds}`)
      fastify.log.info(`   - exercices: ${updateData.exercises ? updateData.exercises.length : 'undefined'} exercices`)
      
      if (updateData.exercises) {
        fastify.log.info(`📝 Détail des exercices reçus:`)
        updateData.exercises.forEach((exercise, index) => {
          fastify.log.info(`   [${index}] exerciseId: ${exercise.exerciseId}, order: ${exercise.order}, reps: ${exercise.targetRepetitions}, distance: ${exercise.targetDistance}`)
        })
      }
      
      // Vérifier que l'utilisateur existe et vérifier s'il est coach
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: {
          coachProfile: true // Inclure le profil coach s'il existe
        }
      })
      
      if (!user) {
        reply.code(404).send({ success: false, error: 'Utilisateur non trouvé' })
        return
      }
      
      const isCoach = !!user.coachProfile
      
      // Vérifier que le template appartient à l'utilisateur
      const existingTemplate = await fastify.prisma.template.findFirst({
        where: {
          id: normalizedTemplateId,
          creatorId: user.id,
          // Pour un coach, on peut modifier tous ses templates (personnels ou non)
          // Pour un utilisateur normal, seulement les templates personnels
          ...(isCoach ? {} : { isPersonal: true })
        },
        include: {
          exercises: true
        }
      })
      
      if (!existingTemplate) {
        reply.code(404).send({ success: false, error: 'Template non trouvé ou accès interdit' })
        return
      }
      
      fastify.log.info(`📊 Template existant:`)
      fastify.log.info(`   - Exercices actuels: ${existingTemplate.exercises.length}`)
      existingTemplate.exercises.forEach((exercise, index) => {
        fastify.log.info(`   [${index}] id: ${exercise.id}, exerciseId: ${exercise.exerciseId}, order: ${exercise.order}`)
      })
      
      // Supprimer les anciens exercices du template
      const deletedExercises = await fastify.prisma.templateExercise.deleteMany({
        where: { templateId: normalizedTemplateId }
      })
      
      fastify.log.info(`🗑️ Exercices supprimés: ${deletedExercises.count}`)
      
      // Préparer les nouveaux exercices
      const newExercisesData = updateData.exercises?.map(exercise => ({
        exerciseId: exercise.exerciseId,
        order: exercise.order,
        sets: exercise.sets,
        reps: exercise.targetRepetitions,
        duration: exercise.targetTime,
        distance: exercise.targetDistance,
        weight: exercise.weight,
        restTime: exercise.restTime
      })) || []
      
      fastify.log.info(`➕ Nouveaux exercices à créer: ${newExercisesData.length}`)
      newExercisesData.forEach((exercise, index) => {
        fastify.log.info(`   [${index}] exerciseId: ${exercise.exerciseId}, order: ${exercise.order}, reps: ${exercise.reps}, distance: ${exercise.distance}`)
      })
      
      // Mettre à jour le template avec les nouvelles données
      const updatedTemplate = await fastify.prisma.template.update({
        where: { id: normalizedTemplateId },
        data: {
          name: updateData.name || existingTemplate.name,
          description: updateData.description !== undefined ? updateData.description : existingTemplate.description,
          rounds: updateData.rounds || existingTemplate.rounds,
          difficulty: updateData.difficulty || existingTemplate.difficulty,
          category: updateData.category || existingTemplate.category,
          estimatedTime: updateData.estimatedTime || existingTemplate.estimatedTime,
          exercises: {
            create: newExercisesData
          }
        },
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
      })
      
      fastify.log.info(`✅ Template mis à jour: ${normalizedTemplateId}`)
      fastify.log.info(`📊 Résultat final: ${updatedTemplate.exercises.length} exercices`)
      
      return {
        ...updatedTemplate,
        userId: updatedTemplate.creatorId,
        creatorId: undefined
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la mise à jour du template:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // DELETE /users/firebase/:firebaseUID/personal-templates/:templateId - Supprimer un template personnel
  fastify.delete('/users/firebase/:firebaseUID/personal-templates/:templateId', {
    schema: {
      description: 'Supprimer un template personnel',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string', minLength: 1 },
          templateId: { type: 'string', minLength: 1 }
        },
        required: ['firebaseUID', 'templateId']
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' }
          }
        },
        403: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            error: { type: 'string' }
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
    try {
      fastify.log.info(`🚀 DELETE Route called: ${request.url}`)
      fastify.log.info(`📋 Headers reçus: ${JSON.stringify(request.headers)}`)
      fastify.log.info(`🔍 Params: ${JSON.stringify(request.params)}`)
      fastify.log.info(`👤 Request.user: ${JSON.stringify(request.user)}`)
      
      const { firebaseUID, templateId } = request.params
      
      fastify.log.info(`🔑 firebaseUID: ${firebaseUID}`)
      fastify.log.info(`🆔 templateId: ${templateId}`)
      
      // Normaliser l'ID en minuscules pour être insensible à la casse
      const normalizedTemplateId = templateId.toLowerCase()
      
      fastify.log.info(`🔄 normalizedTemplateId: ${normalizedTemplateId}`)
      
      if (!request.user) {
        fastify.log.error(`❌ request.user est undefined`)
        reply.code(401).send({ success: false, error: 'Utilisateur non authentifié' })
        return
      }
      
      if (request.user.firebaseUID !== firebaseUID) {
        fastify.log.error(`❌ Mismatch firebaseUID: ${request.user.firebaseUID} !== ${firebaseUID}`)
        reply.code(403).send({ success: false, error: 'Accès interdit' })
        return
      }
      
      fastify.log.info(`🗑️ Suppression template: ${normalizedTemplateId} pour user: ${firebaseUID}`)
      
      // Vérifier que l'utilisateur existe et vérifier s'il est coach
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: {
          coachProfile: true // Inclure le profil coach s'il existe
        }
      })
      
      if (!user) {
        fastify.log.error(`❌ Utilisateur non trouvé: ${firebaseUID}`)
        reply.code(404).send({ success: false, error: 'Utilisateur non trouvé' })
        return
      }
      
      const isCoach = !!user.coachProfile
      
      fastify.log.info(`✅ Utilisateur trouvé: ${user.id} - Coach: ${isCoach}`)
      
      // Vérifier que le template appartient à l'utilisateur
      const existingTemplate = await fastify.prisma.template.findFirst({
        where: {
          id: normalizedTemplateId,
          creatorId: user.id,
          // Pour un coach, on peut supprimer tous ses templates (personnels ou non)
          // Pour un utilisateur normal, seulement les templates personnels
          ...(isCoach ? {} : { isPersonal: true })
        }
      })
      
      if (!existingTemplate) {
        fastify.log.error(`❌ Template non trouvé: ${normalizedTemplateId} pour user: ${user.id}`)
        reply.code(404).send({ success: false, error: 'Template non trouvé ou accès interdit' })
        return
      }
      
      fastify.log.info(`✅ Template trouvé: ${existingTemplate.id}`)
      
      // Supprimer les exercices du template d'abord (relation cascade)
      await fastify.prisma.templateExercise.deleteMany({
        where: { templateId: normalizedTemplateId }
      })
      
      fastify.log.info(`✅ Exercices supprimés pour template: ${normalizedTemplateId}`)
      
      // Supprimer le template
      await fastify.prisma.template.delete({
        where: { id: normalizedTemplateId }
      })
      
      fastify.log.info(`✅ Template supprimé: ${normalizedTemplateId}`)
      
      return {
        success: true,
        message: 'Template supprimé avec succès'
      }
      
    } catch (error) {
      fastify.log.error('💥 Erreur complète lors de la suppression du template:', {
        message: error.message,
        stack: error.stack,
        url: request.url,
        headers: request.headers,
        params: request.params
      })
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })
}

module.exports = userRoutes 