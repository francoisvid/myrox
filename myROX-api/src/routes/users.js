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

  // GET /users/firebase/:firebaseUID/informations - Récupérer les informations utilisateur
  fastify.get('/users/firebase/:firebaseUID/informations', {
    schema: {
      description: 'Récupérer les informations d\'onboarding utilisateur',
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
            userId: { type: 'string' },
            hasCompletedOnboarding: { type: 'boolean' },
            hyroxExperience: { type: 'string' },
            hasCompetedHyrox: { type: 'boolean' },
            primaryGoal: { type: 'string' },
            currentTrainingFrequency: { type: 'string' },
            trainingTypes: { type: 'array', items: { type: 'string' } },
            fitnessLevel: { type: 'number' },
            injuriesLimitations: { type: 'string' },
            familiarWithHyroxStations: { type: 'boolean' },
            difficultExercises: { type: 'array', items: { type: 'string' } },
            hasGymAccess: { type: 'boolean' },
            gymName: { type: 'string' },
            gymLocation: { type: 'string' },
            availableEquipment: { type: 'array', items: { type: 'string' } },
            preferredTrainingFrequency: { type: 'string' },
            preferredSessionDuration: { type: 'string' },
            targetCompetitionDate: { type: 'string' },
            preferredTrainingTime: { type: 'string' },
            preferredIntensity: { type: 'string' },
            prefersStructuredProgram: { type: 'boolean' },
            wantsNotifications: { type: 'boolean' },
            createdAt: { type: 'string' },
            updatedAt: { type: 'string' },
            completedAt: { type: 'string' }
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
    
    // Vérifier que l'utilisateur demande ses propres informations
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez consulter que vos propres informations'
      })
      return
    }
    
    try {
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: {
          userInformations: true
        }
      })
      
      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        })
        return
      }
      
      if (!user.userInformations) {
        reply.code(404).send({
          success: false,
          error: 'Informations d\'onboarding non trouvées'
        })
        return
      }
      
      const info = user.userInformations
      return {
        id: info.id,
        userId: info.userId,
        hasCompletedOnboarding: info.hasCompletedOnboarding,
        hyroxExperience: info.hyroxExperience,
        hasCompetedHyrox: info.hasCompetedHyrox,
        primaryGoal: info.primaryGoal,
        currentTrainingFrequency: info.currentTrainingFrequency,
        trainingTypes: info.trainingTypes,
        fitnessLevel: info.fitnessLevel,
        injuriesLimitations: info.injuriesLimitations,
        familiarWithHyroxStations: info.familiarWithHyroxStations,
        difficultExercises: info.difficultExercises,
        hasGymAccess: info.hasGymAccess,
        gymName: info.gymName,
        gymLocation: info.gymLocation,
        availableEquipment: info.availableEquipment,
        preferredTrainingFrequency: info.preferredTrainingFrequency,
        preferredSessionDuration: info.preferredSessionDuration,
        targetCompetitionDate: info.targetCompetitionDate?.toISOString(),
        preferredTrainingTime: info.preferredTrainingTime,
        preferredIntensity: info.preferredIntensity,
        prefersStructuredProgram: info.prefersStructuredProgram,
        wantsNotifications: info.wantsNotifications,
        createdAt: info.createdAt.toISOString(),
        updatedAt: info.updatedAt.toISOString(),
        completedAt: info.completedAt?.toISOString()
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des informations utilisateur:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // POST /users/firebase/:firebaseUID/informations - Créer/Compléter onboarding
  fastify.post('/users/firebase/:firebaseUID/informations', {
    schema: {
      description: 'Créer ou mettre à jour les informations d\'onboarding',
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
          // Étape 1
          hyroxExperience: { type: 'string', enum: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'] },
          hasCompetedHyrox: { type: 'boolean' },
          primaryGoal: { type: 'string', enum: ['FIRST_PARTICIPATION', 'IMPROVE_TIME', 'PROFESSIONAL_COMPETITION'] },
          
          // Étape 2
          currentTrainingFrequency: { type: 'string', enum: ['ONCE_WEEK', 'TWICE_WEEK', 'THREE_WEEK', 'FOUR_WEEK', 'FIVE_PLUS_WEEK'] },
          trainingTypes: { type: 'array', items: { type: 'string' } },
          fitnessLevel: { type: 'number', minimum: 1, maximum: 10 },
          injuriesLimitations: { type: 'string' },
          
          // Étape 3
          familiarWithHyroxStations: { type: 'boolean' },
          difficultExercises: { type: 'array', items: { type: 'string' } },
          hasGymAccess: { type: 'boolean' },
          gymName: { type: 'string' },
          gymLocation: { type: 'string' },
          availableEquipment: { type: 'array', items: { type: 'string' } },
          
          // Étape 4
          preferredTrainingFrequency: { type: 'string', enum: ['ONCE_WEEK', 'TWICE_WEEK', 'THREE_WEEK', 'FOUR_WEEK', 'FIVE_PLUS_WEEK'] },
          preferredSessionDuration: { type: 'string', enum: ['THIRTY_MIN', 'FORTY_FIVE_MIN', 'ONE_HOUR', 'ONE_HOUR_PLUS'] },
          targetCompetitionDate: { type: 'string', format: 'date-time' },
          preferredTrainingTime: { type: 'string', enum: ['MORNING', 'MIDDAY', 'EVENING', 'FLEXIBLE'] },
          
          // Étape 5
          preferredIntensity: { type: 'string', enum: ['SHORT_INTENSE', 'LONG_MODERATE', 'MIXED'] },
          prefersStructuredProgram: { type: 'boolean' },
          wantsNotifications: { type: 'boolean' },
          
          // Completion
          hasCompletedOnboarding: { type: 'boolean' }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    const data = request.body
    
    // Vérifier que l'utilisateur modifie ses propres informations
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez modifier que vos propres informations'
      })
      return
    }
    
    try {
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: { userInformations: true }
      })
      
      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        })
        return
      }
      
      // Préparer les données à sauvegarder
      const saveData = {
        ...data,
        targetCompetitionDate: data.targetCompetitionDate ? new Date(data.targetCompetitionDate) : undefined,
        completedAt: data.hasCompletedOnboarding ? new Date() : undefined
      }
      
      let userInformations
      
      if (user.userInformations) {
        // Mettre à jour les informations existantes
        userInformations = await fastify.prisma.userInformations.update({
          where: { userId: user.id },
          data: saveData
        })
      } else {
        // Créer de nouvelles informations
        userInformations = await fastify.prisma.userInformations.create({
          data: {
            userId: user.id,
            ...saveData
          }
        })
      }
      
      reply.code(user.userInformations ? 200 : 201)
      return {
        id: userInformations.id,
        userId: userInformations.userId,
        hasCompletedOnboarding: userInformations.hasCompletedOnboarding,
        message: user.userInformations ? 'Informations mises à jour avec succès' : 'Onboarding complété avec succès'
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la sauvegarde des informations utilisateur:', {
        message: error.message,
        stack: error.stack,
        code: error.code,
        meta: error.meta,
        firebaseUID,
        requestData: data
      })
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })

  // PUT /users/firebase/:firebaseUID/informations - Mettre à jour informations
  fastify.put('/users/firebase/:firebaseUID/informations', {
    schema: {
      description: 'Mettre à jour partiellement les informations utilisateur',
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
          // Même schéma que POST mais tous les champs optionnels
          hyroxExperience: { type: 'string', enum: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'] },
          hasCompetedHyrox: { type: 'boolean' },
          primaryGoal: { type: 'string', enum: ['FIRST_PARTICIPATION', 'IMPROVE_TIME', 'PROFESSIONAL_COMPETITION'] },
          currentTrainingFrequency: { type: 'string', enum: ['ONCE_WEEK', 'TWICE_WEEK', 'THREE_WEEK', 'FOUR_WEEK', 'FIVE_PLUS_WEEK'] },
          trainingTypes: { type: 'array', items: { type: 'string' } },
          fitnessLevel: { type: 'number', minimum: 1, maximum: 10 },
          injuriesLimitations: { type: 'string' },
          familiarWithHyroxStations: { type: 'boolean' },
          difficultExercises: { type: 'array', items: { type: 'string' } },
          hasGymAccess: { type: 'boolean' },
          gymName: { type: 'string' },
          gymLocation: { type: 'string' },
          availableEquipment: { type: 'array', items: { type: 'string' } },
          preferredTrainingFrequency: { type: 'string', enum: ['ONCE_WEEK', 'TWICE_WEEK', 'THREE_WEEK', 'FOUR_WEEK', 'FIVE_PLUS_WEEK'] },
          preferredSessionDuration: { type: 'string', enum: ['THIRTY_MIN', 'FORTY_FIVE_MIN', 'ONE_HOUR', 'ONE_HOUR_PLUS'] },
          targetCompetitionDate: { type: 'string', format: 'date-time' },
          preferredTrainingTime: { type: 'string', enum: ['MORNING', 'MIDDAY', 'EVENING', 'FLEXIBLE'] },
          preferredIntensity: { type: 'string', enum: ['SHORT_INTENSE', 'LONG_MODERATE', 'MIXED'] },
          prefersStructuredProgram: { type: 'boolean' },
          wantsNotifications: { type: 'boolean' }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params
    const updates = request.body
    
    // Vérifier que l'utilisateur modifie ses propres informations
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez modifier que vos propres informations'
      })
      return
    }
    
    try {
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: { userInformations: true }
      })
      
      if (!user || !user.userInformations) {
        reply.code(404).send({
          success: false,
          error: 'Informations d\'onboarding non trouvées'
        })
        return
      }
      
      // Préparer les données à mettre à jour
      const updateData = {
        ...updates,
        targetCompetitionDate: updates.targetCompetitionDate ? new Date(updates.targetCompetitionDate) : undefined
      }
      
      const userInformations = await fastify.prisma.userInformations.update({
        where: { userId: user.id },
        data: updateData
      })
      
      return {
        id: userInformations.id,
        message: 'Informations mises à jour avec succès'
      }
      
    } catch (error) {
      fastify.log.error('Erreur lors de la mise à jour des informations utilisateur:', error)
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      })
    }
  })
}

module.exports = userRoutes 