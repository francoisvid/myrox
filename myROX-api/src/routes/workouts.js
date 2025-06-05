const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function workoutRoutes(fastify, options) {

  // GET /users/firebase/:firebaseUID/workouts - Récupérer tous les workouts d'un utilisateur
  fastify.get('/users/firebase/:firebaseUID/workouts', {
    schema: {
      description: 'Récupérer tous les workouts d\'un utilisateur',
      tags: ['Workouts'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        },
        required: ['firebaseUID']
      },
      querystring: {
        type: 'object',
        properties: {
          includeIncomplete: { type: 'boolean', default: false },
          limit: { type: 'number', default: 50 },
          offset: { type: 'number', default: 0 }
        }
      },
      response: {
        200: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              name: { type: 'string' },
              startedAt: { type: 'string' },
              completedAt: { type: 'string' },
              totalDuration: { type: 'number' },
              notes: { type: 'string' },
              rating: { type: 'number' },
              templateId: { type: 'string' },
              template: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  name: { type: 'string' }
                }
              },
              exercises: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    order: { type: 'number' },
                    sets: { type: 'number' },
                    repsCompleted: { type: 'number' },
                    durationCompleted: { type: 'number' },
                    distanceCompleted: { type: 'number' },
                    weightUsed: { type: 'number' },
                    restTime: { type: 'number' },
                    notes: { type: 'string' },
                    completedAt: { type: 'string' },
                    exercise: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        name: { type: 'string' },
                        category: { type: 'string' }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params;
    const { includeIncomplete = false, limit = 50, offset = 0 } = request.query;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez consulter que vos propres workouts'
      });
      return;
    }

    try {
      fastify.log.info(`🔍 Récupération workouts pour: ${firebaseUID}`);
      
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID }
      });

      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        });
        return;
      }

      const whereClause = {
        userId: user.id,
        ...(includeIncomplete ? {} : { completedAt: { not: null } })
      };

      const workouts = await fastify.prisma.workout.findMany({
        where: whereClause,
        include: {
          template: {
            select: {
              id: true,
              name: true
            }
          },
          exercises: {
            include: {
              exercise: {
                select: {
                  id: true,
                  name: true,
                  category: true
                }
              }
            },
            orderBy: {
              order: 'asc'
            }
          }
        },
        orderBy: {
          startedAt: 'desc'
        },
        take: limit,
        skip: offset
      });

      const formattedWorkouts = workouts.map(workout => ({
        id: workout.id,
        name: workout.name,
        startedAt: workout.startedAt.toISOString(),
        completedAt: workout.completedAt?.toISOString() || null,
        totalDuration: workout.totalDuration,
        notes: workout.notes,
        rating: workout.rating,
        templateId: workout.templateId,
        template: workout.template ? {
          id: workout.template.id,
          name: workout.template.name
        } : null,
        exercises: workout.exercises.map(exercise => ({
          id: exercise.id,
          order: exercise.order,
          sets: exercise.sets,
          repsCompleted: exercise.repsCompleted,
          durationCompleted: exercise.durationCompleted,
          distanceCompleted: exercise.distanceCompleted,
          weightUsed: exercise.weightUsed,
          restTime: exercise.restTime,
          notes: exercise.notes,
          completedAt: exercise.completedAt?.toISOString() || null,
          exercise: {
            id: exercise.exercise.id,
            name: exercise.exercise.name,
            category: exercise.exercise.category
          }
        }))
      }));

      return formattedWorkouts;

    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des workouts:', error);
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });

  // POST /users/firebase/:firebaseUID/workouts - Créer un nouveau workout
  fastify.post('/users/firebase/:firebaseUID/workouts', {
    schema: {
      description: 'Créer un nouveau workout',
      tags: ['Workouts'],
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
          templateId: { type: 'string' },
          name: { type: 'string' },
          startedAt: { type: 'string' },
          exercises: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                exerciseId: { type: 'string' },
                order: { type: 'number' },
                sets: { type: 'number' },
                targetReps: { type: 'number' },
                targetDuration: { type: 'number' },
                targetDistance: { type: 'number' },
                targetWeight: { type: 'number' },
                restTime: { type: 'number' }
              },
              required: ['exerciseId', 'order']
            }
          }
        },
        required: ['startedAt', 'exercises']
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params;
    const workoutData = request.body;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      });
      return;
    }

    try {
      fastify.log.info(`✨ Création workout pour: ${firebaseUID}`);
      
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID }
      });

      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        });
        return;
      }

      // Créer le workout avec les exercices en transaction
      const workout = await fastify.prisma.$transaction(async (tx) => {
        const newWorkout = await tx.workout.create({
          data: {
            name: workoutData.name,
            startedAt: new Date(workoutData.startedAt),
            userId: user.id,
            templateId: workoutData.templateId || null
          }
        });

        // Créer les exercices du workout
        if (workoutData.exercises && workoutData.exercises.length > 0) {
          // Debug : loguer les IDs reçus
          fastify.log.info(`📋 Exercices reçus (${workoutData.exercises.length}):`);
          workoutData.exercises.forEach((exercise, index) => {
            fastify.log.info(`   [${index}] ID: ${exercise.exerciseId} (ordre: ${exercise.order})`);
          });
          
          const exerciseData = workoutData.exercises.map(exercise => ({
            workoutId: newWorkout.id,
            exerciseId: exercise.exerciseId,
            order: exercise.order,
            sets: exercise.sets || null,
            // Les valeurs target sont stockées comme valeurs initiales
            repsCompleted: exercise.targetReps || null,
            durationCompleted: exercise.targetDuration || null,
            distanceCompleted: exercise.targetDistance || null,
            weightUsed: exercise.targetWeight || null,
            restTime: exercise.restTime || null
          }));

          await tx.workoutExercise.createMany({
            data: exerciseData
          });
        }

        return newWorkout;
      });

      // Récupérer le workout complet avec les relations
      const completeWorkout = await fastify.prisma.workout.findUnique({
        where: { id: workout.id },
        include: {
          template: {
            select: {
              id: true,
              name: true
            }
          },
          exercises: {
            include: {
              exercise: {
                select: {
                  id: true,
                  name: true,
                  category: true
                }
              }
            },
            orderBy: {
              order: 'asc'
            }
          }
        }
      });

      reply.code(201);
      return {
        id: completeWorkout.id,
        name: completeWorkout.name,
        startedAt: completeWorkout.startedAt.toISOString(),
        completedAt: completeWorkout.completedAt?.toISOString() || null,
        totalDuration: completeWorkout.totalDuration,
        notes: completeWorkout.notes,
        rating: completeWorkout.rating,
        templateId: completeWorkout.templateId,
        template: completeWorkout.template ? {
          id: completeWorkout.template.id,
          name: completeWorkout.template.name
        } : null,
        exercises: completeWorkout.exercises.map(exercise => ({
          id: exercise.id,
          order: exercise.order,
          sets: exercise.sets,
          repsCompleted: exercise.repsCompleted,
          durationCompleted: exercise.durationCompleted,
          distanceCompleted: exercise.distanceCompleted,
          weightUsed: exercise.weightUsed,
          restTime: exercise.restTime,
          notes: exercise.notes,
          completedAt: exercise.completedAt?.toISOString() || null,
          exercise: {
            id: exercise.exercise.id,
            name: exercise.exercise.name,
            category: exercise.exercise.category
          }
        }))
      };

    } catch (error) {
      fastify.log.error('Erreur lors de la création du workout:', error);
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });

  // PUT /users/firebase/:firebaseUID/workouts/:workoutId - Mettre à jour un workout
  fastify.put('/users/firebase/:firebaseUID/workouts/:workoutId', {
    schema: {
      description: 'Mettre à jour un workout (complétion, notes, rating, exercices)',
      tags: ['Workouts'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' },
          workoutId: { type: 'string' }
        },
        required: ['firebaseUID', 'workoutId']
      },
      body: {
        type: 'object',
        properties: {
          completedAt: { type: 'string' },
          totalDuration: { type: 'number' },
          notes: { type: 'string' },
          rating: { type: 'number', minimum: 1, maximum: 5 },
          exercises: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                repsCompleted: { type: 'number' },
                durationCompleted: { type: 'number' },
                distanceCompleted: { type: 'number' },
                weightUsed: { type: 'number' },
                restTime: { type: 'number' },
                notes: { type: 'string' },
                completedAt: { type: 'string' }
              },
              required: ['id']
            }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID, workoutId } = request.params;
    const updateData = request.body;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      });
      return;
    }

    try {
      fastify.log.info(`🔄 Mise à jour workout: ${workoutId} pour: ${firebaseUID}`);
      
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID }
      });

      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        });
        return;
      }

      // Vérifier que le workout appartient à l'utilisateur
      const existingWorkout = await fastify.prisma.workout.findUnique({
        where: { id: workoutId },
        include: { exercises: true }
      });

      if (!existingWorkout || existingWorkout.userId !== user.id) {
        reply.code(404).send({
          success: false,
          error: 'Workout non trouvé'
        });
        return;
      }

      // Mettre à jour en transaction
      const updatedWorkout = await fastify.prisma.$transaction(async (tx) => {
        // Mettre à jour le workout principal
        const workout = await tx.workout.update({
          where: { id: workoutId },
          data: {
            completedAt: updateData.completedAt ? new Date(updateData.completedAt) : undefined,
            totalDuration: updateData.totalDuration,
            notes: updateData.notes,
            rating: updateData.rating
          }
        });

        // Mettre à jour les exercices si fournis
        if (updateData.exercises && updateData.exercises.length > 0) {
          for (const exerciseUpdate of updateData.exercises) {
            await tx.workoutExercise.update({
              where: { id: exerciseUpdate.id },
              data: {
                repsCompleted: exerciseUpdate.repsCompleted,
                durationCompleted: exerciseUpdate.durationCompleted,
                distanceCompleted: exerciseUpdate.distanceCompleted,
                weightUsed: exerciseUpdate.weightUsed,
                restTime: exerciseUpdate.restTime,
                notes: exerciseUpdate.notes,
                completedAt: exerciseUpdate.completedAt ? new Date(exerciseUpdate.completedAt) : undefined
              }
            });
          }
        }

        return workout;
      });

      // Si le workout est complété, calculer les personal bests
      if (updateData.completedAt && updateData.exercises) {
        await calculatePersonalBests(fastify.prisma, user.id, workoutId, updateData.exercises);
      }

      // Récupérer le workout complet mis à jour
      const completeWorkout = await fastify.prisma.workout.findUnique({
        where: { id: workoutId },
        include: {
          template: {
            select: {
              id: true,
              name: true
            }
          },
          exercises: {
            include: {
              exercise: {
                select: {
                  id: true,
                  name: true,
                  category: true
                }
              }
            },
            orderBy: {
              order: 'asc'
            }
          }
        }
      });

      return {
        id: completeWorkout.id,
        name: completeWorkout.name,
        startedAt: completeWorkout.startedAt.toISOString(),
        completedAt: completeWorkout.completedAt?.toISOString() || null,
        totalDuration: completeWorkout.totalDuration,
        notes: completeWorkout.notes,
        rating: completeWorkout.rating,
        templateId: completeWorkout.templateId,
        template: completeWorkout.template ? {
          id: completeWorkout.template.id,
          name: completeWorkout.template.name
        } : null,
        exercises: completeWorkout.exercises.map(exercise => ({
          id: exercise.id,
          order: exercise.order,
          sets: exercise.sets,
          repsCompleted: exercise.repsCompleted,
          durationCompleted: exercise.durationCompleted,
          distanceCompleted: exercise.distanceCompleted,
          weightUsed: exercise.weightUsed,
          restTime: exercise.restTime,
          notes: exercise.notes,
          completedAt: exercise.completedAt?.toISOString() || null,
          exercise: {
            id: exercise.exercise.id,
            name: exercise.exercise.name,
            category: exercise.exercise.category
          }
        }))
      };

    } catch (error) {
      fastify.log.error('Erreur lors de la mise à jour du workout:', error);
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });

  // DELETE /users/firebase/:firebaseUID/workouts/:workoutId - Supprimer un workout
  fastify.delete('/users/firebase/:firebaseUID/workouts/:workoutId', {
    schema: {
      description: 'Supprimer un workout',
      tags: ['Workouts'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' },
          workoutId: { type: 'string' }
        },
        required: ['firebaseUID', 'workoutId']
      }
    }
  }, async (request, reply) => {
    const { firebaseUID, workoutId } = request.params;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      });
      return;
    }

    try {
      fastify.log.info(`🗑️ Suppression workout: ${workoutId} pour: ${firebaseUID}`);
      
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID }
      });

      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        });
        return;
      }

      // Vérifier que le workout appartient à l'utilisateur
      const existingWorkout = await fastify.prisma.workout.findUnique({
        where: { id: workoutId }
      });

      if (!existingWorkout || existingWorkout.userId !== user.id) {
        reply.code(404).send({
          success: false,
          error: 'Workout non trouvé'
        });
        return;
      }

      // Supprimer le workout (cascade supprimera les exercices et personal bests liés)
      await fastify.prisma.workout.delete({
        where: { id: workoutId }
      });

      reply.code(204).send();

    } catch (error) {
      fastify.log.error('Erreur lors de la suppression du workout:', error);
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });

  // GET /users/firebase/:firebaseUID/personal-bests - Récupérer les records personnels
  fastify.get('/users/firebase/:firebaseUID/personal-bests', {
    schema: {
      description: 'Récupérer les records personnels d\'un utilisateur',
      tags: ['Personal Bests'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' }
        },
        required: ['firebaseUID']
      },
      response: {
        200: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              exerciseType: { type: 'string' },
              value: { type: 'number' },
              unit: { type: 'string' },
              achievedAt: { type: 'string' },
              workoutId: { type: 'string' },
              workout: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  name: { type: 'string' },
                  completedAt: { type: 'string' }
                }
              }
            }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      });
      return;
    }

    try {
      fastify.log.info(`🏆 Récupération personal bests pour: ${firebaseUID}`);
      
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID }
      });

      if (!user) {
        reply.code(404).send({
          success: false,
          error: 'Utilisateur non trouvé'
        });
        return;
      }

      const personalBests = await fastify.prisma.personalBest.findMany({
        where: { userId: user.id },
        include: {
          workout: {
            select: {
              id: true,
              name: true,
              completedAt: true
            }
          }
        },
        orderBy: {
          achievedAt: 'desc'
        }
      });

      return personalBests.map(pb => ({
        id: pb.id,
        exerciseType: pb.exerciseType,
        value: pb.value,
        unit: pb.unit,
        achievedAt: pb.achievedAt.toISOString(),
        workoutId: pb.workoutId,
        workout: pb.workout ? {
          id: pb.workout.id,
          name: pb.workout.name,
          completedAt: pb.workout.completedAt?.toISOString() || null
        } : null
      }));

    } catch (error) {
      fastify.log.error('Erreur lors de la récupération des personal bests:', error);
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });
}

// MARK: - Helper Functions

/**
 * Calcule les records personnels après la complétion d'un workout
 */
async function calculatePersonalBests(prisma, userId, workoutId, exercises) {
  try {
    for (const exercise of exercises) {
      if (!exercise.completedAt || !exercise.durationCompleted) {
        continue; // Skip non-completed exercises
      }

      // Récupérer l'exercice pour avoir son nom
      const workoutExercise = await prisma.workoutExercise.findUnique({
        where: { id: exercise.id },
        include: { exercise: true }
      });

      if (!workoutExercise) continue;

      // Générer la clé du type d'exercice (similaire à iOS)
      let exerciseType = workoutExercise.exercise.name;
      
      if (exercise.distanceCompleted && exercise.distanceCompleted > 0) {
        exerciseType += `_${Math.round(exercise.distanceCompleted)}m`;
      }
      
      if (exercise.repsCompleted && exercise.repsCompleted > 0) {
        exerciseType += `_${exercise.repsCompleted}reps`;
      }
      
      if (!exercise.distanceCompleted && !exercise.repsCompleted) {
        exerciseType += '_timeOnly';
      }

      // Vérifier s'il existe déjà un record pour ce type d'exercice
      const existingRecord = await prisma.personalBest.findUnique({
        where: {
          userId_exerciseType: {
            userId: userId,
            exerciseType: exerciseType
          }
        }
      });

      // Pour le temps, plus petit = meilleur
      const newTime = exercise.durationCompleted;
      const shouldUpdateRecord = !existingRecord || newTime < existingRecord.value;

      if (shouldUpdateRecord) {
        await prisma.personalBest.upsert({
          where: {
            userId_exerciseType: {
              userId: userId,
              exerciseType: exerciseType
            }
          },
          update: {
            value: newTime,
            unit: 'seconds',
            achievedAt: new Date(exercise.completedAt),
            workoutId: workoutId
          },
          create: {
            userId: userId,
            exerciseType: exerciseType,
            value: newTime,
            unit: 'seconds',
            achievedAt: new Date(exercise.completedAt),
            workoutId: workoutId
          }
        });

        console.log(`🏆 Nouveau record personnel: ${exerciseType} - ${newTime}s`);
      }
    }
  } catch (error) {
    console.error('Erreur lors du calcul des personal bests:', error);
    // Ne pas faire échouer le workout pour une erreur de calcul de records
  }
}

module.exports = workoutRoutes; 