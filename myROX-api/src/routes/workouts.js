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

  // POST /users/firebase/:firebaseUID/personal-bests - Créer un nouveau record personnel
  fastify.post('/users/firebase/:firebaseUID/personal-bests', {
    schema: {
      description: 'Créer un nouveau record personnel',
      tags: ['Personal Bests'],
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
          exerciseType: { type: 'string' },
          value: { type: 'number' },
          unit: { type: 'string' },
          achievedAt: { type: 'string' },
          workoutId: { type: 'string' }
        },
        required: ['exerciseType', 'value', 'unit', 'achievedAt']
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params;
    const { exerciseType, value, unit, achievedAt, workoutId } = request.body;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      });
      return;
    }

    try {
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

      const personalBest = await fastify.prisma.personalBest.create({
        data: {
          userId: user.id,
          exerciseType,
          value,
          unit,
          achievedAt: new Date(achievedAt),
          workoutId
        },
        include: {
          workout: {
            select: {
              id: true,
              name: true,
              completedAt: true
            }
          }
        }
      });

      return {
        id: personalBest.id,
        exerciseType: personalBest.exerciseType,
        value: personalBest.value,
        unit: personalBest.unit,
        achievedAt: personalBest.achievedAt.toISOString(),
        workoutId: personalBest.workoutId,
        workout: personalBest.workout ? {
          id: personalBest.workout.id,
          name: personalBest.workout.name,
          completedAt: personalBest.workout.completedAt?.toISOString() || null
        } : null
      };

    } catch (error) {
      fastify.log.error('Erreur lors de la création du personal best:', error);
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });

  // PUT /users/firebase/:firebaseUID/personal-bests/:personalBestId - Mettre à jour un record personnel
  fastify.put('/users/firebase/:firebaseUID/personal-bests/:personalBestId', {
    schema: {
      description: 'Mettre à jour un record personnel',
      tags: ['Personal Bests'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' },
          personalBestId: { type: 'string' }
        },
        required: ['firebaseUID', 'personalBestId']
      },
      body: {
        type: 'object',
        properties: {
          value: { type: 'number' },
          achievedAt: { type: 'string' },
          workoutId: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID, personalBestId } = request.params;
    const { value, achievedAt, workoutId } = request.body;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      });
      return;
    }

    try {
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

      // Vérifier que le record appartient à l'utilisateur
      const existingRecord = await fastify.prisma.personalBest.findUnique({
        where: { id: personalBestId }
      });

      if (!existingRecord || existingRecord.userId !== user.id) {
        reply.code(404).send({
          success: false,
          error: 'Record personnel non trouvé'
        });
        return;
      }

      const updatedRecord = await fastify.prisma.personalBest.update({
        where: { id: personalBestId },
        data: {
          ...(value !== undefined && { value }),
          ...(achievedAt !== undefined && { achievedAt: new Date(achievedAt) }),
          ...(workoutId !== undefined && { workoutId })
        },
        include: {
          workout: {
            select: {
              id: true,
              name: true,
              completedAt: true
            }
          }
        }
      });

      return {
        id: updatedRecord.id,
        exerciseType: updatedRecord.exerciseType,
        value: updatedRecord.value,
        unit: updatedRecord.unit,
        achievedAt: updatedRecord.achievedAt.toISOString(),
        workoutId: updatedRecord.workoutId,
        workout: updatedRecord.workout ? {
          id: updatedRecord.workout.id,
          name: updatedRecord.workout.name,
          completedAt: updatedRecord.workout.completedAt?.toISOString() || null
        } : null
      };

    } catch (error) {
      fastify.log.error('Erreur lors de la mise à jour du personal best:', error);
      reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });

  // DELETE /users/firebase/:firebaseUID/personal-bests/:personalBestId - Supprimer un record personnel
  fastify.delete('/users/firebase/:firebaseUID/personal-bests/:personalBestId', {
    schema: {
      description: 'Supprimer un record personnel',
      tags: ['Personal Bests'],
      params: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' },
          personalBestId: { type: 'string' }
        },
        required: ['firebaseUID', 'personalBestId']
      }
    }
  }, async (request, reply) => {
    const { firebaseUID, personalBestId } = request.params;
    
    // Vérifier les permissions
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      reply.code(403).send({
        success: false,
        error: 'Accès interdit'
      });
      return;
    }

    try {
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

      // Vérifier que le record appartient à l'utilisateur
      const existingRecord = await fastify.prisma.personalBest.findUnique({
        where: { id: personalBestId }
      });

      if (!existingRecord || existingRecord.userId !== user.id) {
        reply.code(404).send({
          success: false,
          error: 'Record personnel non trouvé'
        });
        return;
      }

      await fastify.prisma.personalBest.delete({
        where: { id: personalBestId }
      });

      reply.code(204).send();

    } catch (error) {
      fastify.log.error('Erreur lors de la suppression du personal best:', error);
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
    console.log(`🏆 Calcul des personal bests pour le workout ${workoutId} avec ${exercises.length} exercices`);
    
    for (const exercise of exercises) {
      if (!exercise.completedAt || !exercise.durationCompleted || exercise.durationCompleted <= 0) {
        console.log(`⏭️ Skip exercice ${exercise.id}: pas de temps valide`);
        continue; // Skip non-completed exercises ou temps invalide
      }

      // Récupérer l'exercice pour avoir son nom
      const workoutExercise = await prisma.workoutExercise.findUnique({
        where: { id: exercise.id },
        include: { exercise: true }
      });

      if (!workoutExercise) {
        console.log(`❌ WorkoutExercise ${exercise.id} introuvable`);
        continue;
      }

      // Générer la clé du type d'exercice avec logique améliorée
      const exerciseType = generateExerciseType(workoutExercise.exercise.name, exercise);
      
      console.log(`📊 Traitement exercice: ${exerciseType} (${exercise.durationCompleted}s)`);

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
        const recordData = {
          userId: userId,
          exerciseType: exerciseType,
          value: newTime,
          unit: 'seconds',
          achievedAt: new Date(exercise.completedAt),
          workoutId: workoutId
        };

        await prisma.personalBest.upsert({
          where: {
            userId_exerciseType: {
              userId: userId,
              exerciseType: exerciseType
            }
          },
          update: recordData,
          create: recordData
        });

        const improvement = existingRecord 
          ? `(amélioration de ${(existingRecord.value - newTime).toFixed(1)}s)`
          : '(premier record)';
        
        console.log(`🎉 Nouveau record personnel: ${exerciseType} - ${newTime}s ${improvement}`);
      } else {
        console.log(`📈 Record existant meilleur: ${exerciseType} - actuel: ${existingRecord.value}s vs nouveau: ${newTime}s`);
      }
    }
  } catch (error) {
    console.error('Erreur lors du calcul des personal bests:', error);
    // Ne pas faire échouer le workout pour une erreur de calcul de records
  }
}

/**
 * Génère une clé d'exercice standardisée pour les personal bests
 * Format: exerciseName_distance_reps ou exerciseName_timeOnly
 */
function generateExerciseType(exerciseName, exercise) {
  // Nettoyer le nom de l'exercice (enlever espaces, mettre en minuscules)
  const cleanName = exerciseName.toLowerCase().replace(/\s+/g, '');
  
  let suffix = '';
  
  // Priorité: distance > reps > timeOnly
  if (exercise.distanceCompleted && exercise.distanceCompleted > 0) {
    // Arrondir la distance et créer la clé
    const roundedDistance = Math.round(exercise.distanceCompleted);
    suffix = `_${roundedDistance}m`;
  } else if (exercise.repsCompleted && exercise.repsCompleted > 0) {
    suffix = `_${exercise.repsCompleted}reps`;
  } else {
    // Exercice basé uniquement sur le temps (ex: plank, dead hang)
    suffix = '_timeonly';
  }
  
  return `${cleanName}${suffix}`;
}

module.exports = workoutRoutes; 