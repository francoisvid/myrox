async function templateRoutes(fastify, options) {
  console.log('🏗️ ENREGISTREMENT DES ROUTES TEMPLATES');

  // POST /templates/:templateId/assign - Assigner un template à des utilisateurs
  fastify.post('/:templateId/assign', {
    schema: {
      description: 'Assigner un template à des utilisateurs',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          templateId: { type: 'string' }
        },
        required: ['templateId']
      },
      body: {
        type: 'object',
        properties: {
          userIds: {
            type: 'array',
            items: { type: 'string' },
            minItems: 1
          }
        },
        required: ['userIds']
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            assignedCount: { type: 'number' }
          }
        },
        404: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            error: { type: 'string' }
          }
        },
        500: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            error: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { templateId } = request.params;
    const { userIds } = request.body;
    
    fastify.log.info(`🎯 Assignation template: ${templateId} à ${userIds.length} utilisateurs`);
    
    try {
      // Vérifier que le template existe
      const template = await fastify.prisma.template.findUnique({
        where: { id: templateId }
      });

      if (!template) {
        return reply.code(404).send({
          success: false,
          error: 'Template non trouvé'
        });
      }

      // Vérifier que tous les utilisateurs existent
      const users = await fastify.prisma.user.findMany({
        where: {
          id: { in: userIds }
        }
      });

      if (users.length !== userIds.length) {
        return reply.code(404).send({
          success: false,
          error: 'Un ou plusieurs utilisateurs non trouvés'
        });
      }

      // Assigner le template aux utilisateurs via la relation many-to-many
      const result = await fastify.prisma.template.update({
        where: { id: templateId },
        data: {
          assignedUsers: {
            connect: userIds.map(userId => ({ id: userId }))
          }
        }
      });

      fastify.log.info(`✅ Template assigné aux utilisateurs: ${userIds.length}`);

      return {
        success: true,
        message: `Template assigné à ${userIds.length} utilisateur(s)`,
        assignedCount: userIds.length
      };

    } catch (error) {
      fastify.log.error(`❌ Erreur assignation template ${templateId}:`, error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur serveur lors de l\'assignation'
      });
    }
  });

  // DELETE /templates/:templateId/assign/:userId - Désassigner un template d'un utilisateur
  fastify.delete('/:templateId/assign/:userId', {
    schema: {
      description: 'Désassigner un template d\'un utilisateur',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          templateId: { type: 'string' },
          userId: { type: 'string' }
        },
        required: ['templateId', 'userId']
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' }
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
    const { templateId, userId } = request.params;
    
    fastify.log.info(`🎯 Désassignation template: ${templateId} de l'utilisateur: ${userId}`);
    
    try {
      // Désassigner le template de l'utilisateur via la relation many-to-many
      const result = await fastify.prisma.template.update({
        where: { id: templateId },
        data: {
          assignedUsers: {
            disconnect: { id: userId }
          }
        }
      });

      fastify.log.info(`✅ Template désassigné: ${templateId} de ${userId}`);

      return {
        success: true,
        message: 'Template désassigné avec succès'
      };

    } catch (error) {
      if (error.code === 'P2025') {
        // Record not found
        return reply.code(404).send({
          success: false,
          error: 'Assignation non trouvée'
        });
      }
      
      fastify.log.error(`❌ Erreur désassignation template ${templateId}:`, error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur serveur lors de la désassignation'
      });
    }
  });

  // GET /templates/:templateId/assignments - Récupérer les assignations d'un template
  fastify.get('/:templateId/assignments', {
    schema: {
      description: 'Récupérer les utilisateurs assignés à un template',
      tags: ['Templates'],
      params: {
        type: 'object',
        properties: {
          templateId: { type: 'string' }
        },
        required: ['templateId']
      },
      response: {
        200: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              userId: { type: 'string' },
              email: { type: 'string' },
              displayName: { type: 'string' },
              assignedAt: { type: 'string' }
            }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { templateId } = request.params;
    
    try {
      // Récupérer le template avec ses utilisateurs assignés
      const template = await fastify.prisma.template.findUnique({
        where: { id: templateId },
        include: {
          assignedUsers: {
            select: {
              id: true,
              email: true,
              displayName: true,
              createdAt: true
            }
          }
        }
      });

      if (!template) {
        return reply.code(404).send({
          success: false,
          error: 'Template non trouvé'
        });
      }

      const result = template.assignedUsers.map(user => ({
        userId: user.id,
        email: user.email,
        displayName: user.displayName,
        assignedAt: user.createdAt
      }));

      return result;

    } catch (error) {
      fastify.log.error(`❌ Erreur récupération assignations template ${templateId}:`, error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur serveur lors de la récupération des assignations'
      });
    }
  });
}

module.exports = templateRoutes; 