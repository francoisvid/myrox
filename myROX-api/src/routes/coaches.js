async function coachRoutes(fastify, options) {
  console.log('🏗️ ENREGISTREMENT DES ROUTES COACHES');

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

  // GET /coaches/:id/athletes - Athletes du coach (web only)
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
        200: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              firebaseUID: { type: 'string' },
              email: { type: 'string' },
              displayName: { type: 'string' },
              createdAt: { type: 'string' },
              lastActiveAt: { type: 'string' }
            }
          }
        },
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
    const { id } = request.params;
    
    // Vérifier si l'appel vient de l'interface web
    const clientType = request.headers['x-client-type'];
    const isWebInterface = clientType === 'web';
    
    // Bloquer l'accès pour l'app mobile
    if (!isWebInterface) {
      return reply.code(403).send({
        success: false,
        error: 'Accès interdit depuis l\'app mobile',
        message: 'Cette fonctionnalité est réservée à l\'interface web coach'
      });
    }
    
    fastify.log.info(`👥 Récupération des athlètes du coach: ${id}`);
    
    try {
      // Récupérer le coach et ses athlètes depuis la base de données
      const coach = await fastify.prisma.coach.findUnique({
        where: { id },
        include: {
          athletes: {
            select: {
              id: true,
              firebaseUID: true,
              email: true,
              displayName: true,
              createdAt: true,
              updatedAt: true
            },
            orderBy: { createdAt: 'desc' }
          }
        }
      });

      if (!coach) {
        return reply.code(404).send({
          success: false,
          error: 'Coach non trouvé'
        });
      }

      // Ajouter une date fictive de dernière activité pour chaque athlète
      const athletesWithActivity = coach.athletes.map(athlete => ({
        ...athlete,
        lastActiveAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString()
      }));

      return athletesWithActivity;
    } catch (error) {
      fastify.log.error(`❌ Erreur récupération athlètes coach ${id}:`, error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur serveur lors de la récupération des athlètes'
      });
    }
  })

  // GET /coaches/:id/stats/detailed - Statistiques détaillées du coach
  fastify.get('/:id/stats/detailed', {
    schema: {
      description: 'Statistiques détaillées du coach avec données d\'athlètes',
      tags: ['Coaches'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        },
        required: ['id']
      },
      querystring: {
        type: 'object',
        properties: {
          period: { 
            type: 'string', 
            enum: ['7d', '30d', '90d'],
            default: '30d'
          }
        }
      }
    }
  }, async (request, reply) => {
    const { id } = request.params;
    const { period = '30d' } = request.query;
    
    fastify.log.info(`📊 Statistiques détaillées coach: ${id}, période: ${period}`);
    
    // Vérifier que le coach existe
    const coach = await fastify.prisma.coach.findUnique({
      where: { id },
      include: {
        athletes: {
          include: {
            workouts: {
              where: {
                completedAt: {
                  not: null,
                  gte: new Date(Date.now() - (period === '7d' ? 7 : period === '30d' ? 30 : 90) * 24 * 60 * 60 * 1000)
                }
              }
            }
          }
        }
      }
    });

    if (!coach) {
      return reply.code(404).send({
        success: false,
        error: 'Coach non trouvé'
      });
    }

    // Calculs des statistiques
    const athleteStats = coach.athletes.map(athlete => {
      const workouts = athlete.workouts;
      const totalWorkouts = workouts.length;
      const avgRating = workouts.length > 0 
        ? workouts.reduce((sum, w) => sum + (w.rating || 0), 0) / workouts.length 
        : 0;
      const totalTime = workouts.reduce((sum, w) => sum + (w.totalDuration || 0), 0) / 60; // en minutes
      
      // Calcul réaliste du taux de complétion basé sur les workouts terminés
      const completedWorkouts = workouts.filter(w => w.completedAt !== null).length;
      const completionRate = totalWorkouts > 0 ? (completedWorkouts / totalWorkouts) * 100 : 100;

      return {
        athleteId: athlete.id,
        athleteName: athlete.displayName || athlete.email,
        totalWorkouts,
        avgRating: Number(avgRating.toFixed(1)),
        totalTime: Math.round(totalTime),
        completionRate: Math.round(completionRate)
      };
    });

    // Tendances de workouts basées sur les vraies données
    const allWorkouts = coach.athletes.flatMap(athlete => athlete.workouts);
    const workoutTrends = [];
    const days = period === '7d' ? 7 : period === '30d' ? 30 : 90;
    
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      // Filtrer les workouts pour cette date
      const dayWorkouts = allWorkouts.filter(w => {
        if (!w.completedAt) return false;
        const workoutDate = new Date(w.completedAt).toISOString().split('T')[0];
        return workoutDate === dateStr;
      });
      
      const count = dayWorkouts.length;
      const avgRating = count > 0 
        ? dayWorkouts.reduce((sum, w) => sum + (w.rating || 0), 0) / count 
        : 0;
      
      workoutTrends.push({
        date: dateStr,
        count,
        avgRating: Number(avgRating.toFixed(2))
      });
    }

    // Statistiques par catégorie basées sur les noms des workouts
    const categoryCount = {};
    allWorkouts.forEach(workout => {
      let category = 'Autre';
      const name = workout.name?.toLowerCase() || '';
      
      if (name.includes('hyrox')) {
        category = 'HYROX';
      } else if (name.includes('cardio')) {
        category = 'Cardio';
      } else if (name.includes('force') || name.includes('strength')) {
        category = 'Force';
      } else if (name.includes('running') || name.includes('course')) {
        category = 'Course';
      } else if (name.includes('web')) {
        category = 'Test';
      }
      
      categoryCount[category] = (categoryCount[category] || 0) + 1;
    });
    
    const colors = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#6366F1'];
    const categoryStats = Object.entries(categoryCount).map(([name, value], index) => ({
      name,
      value,
      color: colors[index % colors.length]
    }));

    // Résumé
    const totalWorkouts = athleteStats.reduce((sum, a) => sum + a.totalWorkouts, 0);
    const avgRating = athleteStats.length > 0 
      ? athleteStats.reduce((sum, a) => sum + a.avgRating, 0) / athleteStats.length 
      : 0;
    const avgCompletionRate = athleteStats.length > 0 
      ? athleteStats.reduce((sum, a) => sum + a.completionRate, 0) / athleteStats.length 
      : 0;

    return {
      athleteStats,
      workoutTrends,
      categoryStats,
      summary: {
        totalWorkouts,
        avgRating: Number(avgRating.toFixed(1)),
        avgCompletionRate: Math.round(avgCompletionRate),
        activeAthletes: athleteStats.length
      }
    };
  })

  // GET /coaches/:id/templates - Templates créés par le coach (accès limité)
  fastify.get('/:id/templates', {
    schema: {
      description: 'Récupérer tous les templates créés par un coach (access restreint)',
      tags: ['Coaches'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        },
        required: ['id']
      }
    }
  }, async (request, reply) => {
    const { id } = request.params;
    
    // Vérifier si l'appel vient de l'interface web
    const clientType = request.headers['x-client-type'];
    const isWebInterface = clientType === 'web';
    
    // Bloquer l'accès pour l'app mobile
    if (!isWebInterface) {
      return reply.code(403).send({
        success: false,
        error: 'Accès interdit depuis l\'app mobile',
        message: 'Cette fonctionnalité est réservée à l\'interface web coach'
      });
    }
    
    fastify.log.info(`📋 Récupération templates coach: ${id}`);
    
    try {
      // Vérifier que le coach existe et récupérer ses templates
      const coach = await fastify.prisma.coach.findUnique({
        where: { id },
        include: {
          user: true, // Inclure les infos utilisateur pour vérifier les droits
          createdTemplates: {
            include: {
              exercises: {
                include: {
                  exercise: true
                },
                orderBy: {
                  order: 'asc'
                }
              }
            },
            orderBy: {
              createdAt: 'desc'
            }
          }
        }
      });

      if (!coach) {
        return reply.code(404).send({
          success: false,
          error: 'Coach non trouvé'
        });
      }

      // Vérifier que l'utilisateur connecté est bien ce coach
      if (request.user && request.user.firebaseUID !== coach.user.firebaseUID) {
        return reply.code(403).send({
          success: false,
          error: 'Accès interdit - vous ne pouvez voir que vos propres templates'
        });
      }

      // Formater les templates pour l'API
      const templates = coach.createdTemplates.map(template => ({
        id: template.id,
        name: template.name,
        description: template.description,
        rounds: template.rounds,
        difficulty: template.difficulty,
        category: template.category,
        estimatedTime: template.estimatedTime,
        isPersonal: template.isPersonal,
        createdAt: template.createdAt.toISOString(),
        updatedAt: template.updatedAt.toISOString(),
        exercises: template.exercises.map(ex => ({
          id: ex.id,
          order: ex.order,
          sets: ex.sets,
          reps: ex.reps,
          duration: ex.duration,
          distance: ex.distance,
          weight: ex.weight,
          restTime: ex.restTime,
          exercise: {
            id: ex.exercise.id,
            name: ex.exercise.name,
            category: ex.exercise.category,
            description: ex.exercise.description
          }
        }))
      }));

      return templates;

    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des templates:', error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  })

  // GET /coaches/:id/templates/for-athlete/:athleteId - Templates assignés à un athlète spécifique
  fastify.get('/:id/templates/for-athlete/:athleteId', {
    schema: {
      description: 'Templates du coach assignés à un athlète spécifique',
      tags: ['Coaches'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          athleteId: { type: 'string' }
        },
        required: ['id', 'athleteId']
      }
    }
  }, async (request, reply) => {
    const { id: coachId, athleteId } = request.params;
    
    fastify.log.info(`📋 Récupération templates coach ${coachId} pour athlète ${athleteId}`);
    
    try {
      // Vérifier que l'utilisateur connecté est bien l'athlète en question
      const athlete = await fastify.prisma.user.findUnique({
        where: { id: athleteId }
      });

      if (!athlete) {
        return reply.code(404).send({
          success: false,
          error: 'Athlète non trouvé'
        });
      }

      if (request.user && request.user.firebaseUID !== athlete.firebaseUID) {
        return reply.code(403).send({
          success: false,
          error: 'Accès interdit - vous ne pouvez voir que vos propres templates assignés'
        });
      }

      // Vérifier que l'athlète appartient bien à ce coach
      if (athlete.coachId !== coachId) {
        return reply.code(403).send({
          success: false,
          error: 'Cet athlète n\'appartient pas à ce coach'
        });
      }

      // Récupérer uniquement les templates assignés à cet athlète par ce coach
      const assignedTemplates = await fastify.prisma.template.findMany({
        where: {
          coachId: coachId,
          isPersonal: false, // Templates de coach uniquement
          assignedUsers: {
            some: {
              id: athleteId
            }
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
        },
        orderBy: {
          createdAt: 'desc'
        }
      });

      // Formater les templates pour l'API
      const templates = assignedTemplates.map(template => ({
        id: template.id,
        name: template.name,
        description: template.description,
        rounds: template.rounds,
        difficulty: template.difficulty,
        category: template.category,
        estimatedTime: template.estimatedTime,
        isPersonal: template.isPersonal,
        createdAt: template.createdAt.toISOString(),
        updatedAt: template.updatedAt.toISOString(),
        exercises: template.exercises.map(ex => ({
          id: ex.id,
          order: ex.order,
          sets: ex.sets,
          reps: ex.reps,
          duration: ex.duration,
          distance: ex.distance,
          weight: ex.weight,
          restTime: ex.restTime,
          exercise: {
            id: ex.exercise.id,
            name: ex.exercise.name,
            category: ex.exercise.category,
            description: ex.exercise.description
          }
        }))
      }));

      return templates;

    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des templates assignés:', error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
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