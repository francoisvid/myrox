async function authRoutes(fastify, options) {
  console.log('🔐 ENREGISTREMENT DES ROUTES AUTH');

  // POST /auth/register - Inscription avec rôle (Coach ou Athlète)
  fastify.post('/register', {
    schema: {
      description: 'Inscription d\'un nouvel utilisateur avec rôle',
      tags: ['Auth'],
      body: {
        type: 'object',
        properties: {
          firebaseUID: { type: 'string' },
          email: { type: 'string' },
          displayName: { type: 'string' },
          userType: { type: 'string', enum: ['athlete', 'coach'] },
          // Champs supplémentaires pour les coaches
          specialization: { type: 'string' },
          bio: { type: 'string' },
          certifications: { type: 'array', items: { type: 'string' } }
        },
        required: ['firebaseUID', 'email', 'userType']
      },
      response: {
        201: {
          type: 'object',
          properties: {
            user: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                firebaseUID: { type: 'string' },
                email: { type: 'string' },
                displayName: { type: 'string' },
                userType: { type: 'string' },
                createdAt: { type: 'string' }
              }
            },
            coach: {
              type: 'object',
              nullable: true,
              properties: {
                id: { type: 'string' },
                specialization: { type: 'string' },
                bio: { type: 'string' },
                certifications: { type: 'array', items: { type: 'string' } }
              }
            }
          }
        },
        409: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            error: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID, email, displayName, userType, specialization, bio, certifications } = request.body;
    
    // Vérifier que l'utilisateur crée son propre profil
    if (!request.user || request.user.firebaseUID !== firebaseUID) {
      return reply.code(403).send({
        success: false,
        error: 'Accès interdit - Vous ne pouvez créer que votre propre profil'
      });
    }
    
    try {
      fastify.log.info(`✨ Inscription ${userType}: ${firebaseUID} (${email})`);
      
      // Vérifier si l'utilisateur existe déjà
      const existingUser = await fastify.prisma.user.findUnique({
        where: { firebaseUID }
      });
      
      if (existingUser) {
        return reply.code(409).send({
          success: false,
          error: 'Utilisateur déjà existant'
        });
      }
      
      // Transaction pour créer l'utilisateur et éventuellement le coach
      const result = await fastify.prisma.$transaction(async (prisma) => {
        // 1. Créer l'utilisateur de base
        const user = await prisma.user.create({
          data: {
            firebaseUID,
            email,
            displayName: displayName || email.split('@')[0]
          }
        });
        
        let coach = null;
        let updatedUser = user;
        
        // 2. Si c'est un coach, créer aussi le profil coach
        if (userType === 'coach') {
          coach = await prisma.coach.create({
            data: {
              firebaseUID,
              displayName: user.displayName || 'Coach',
              email: user.email,
              specialization: specialization || 'HYROX',
              bio: bio || 'Coach certifié myROX',
              certifications: certifications || [],
              userId: user.id
            }
          });
          
          // 3. Mettre à jour l'utilisateur avec l'ID du coach pour établir la relation bidirectionnelle
          updatedUser = await prisma.user.update({
            where: { id: user.id },
            data: { coachId: coach.id }
          });
        }
        
        return { user: updatedUser, coach };
      });
      
      fastify.log.info(`✅ Inscription réussie - User: ${result.user.id}${result.coach ? `, Coach: ${result.coach.id}` : ''}`);
      
      return reply.code(201).send({
        user: {
          id: result.user.id,
          firebaseUID: result.user.firebaseUID,
          email: result.user.email,
          displayName: result.user.displayName,
          userType: userType,
          createdAt: result.user.createdAt.toISOString()
        },
        coach: result.coach ? {
          id: result.coach.id,
          specialization: result.coach.specialization,
          bio: result.coach.bio,
          certifications: result.coach.certifications
        } : null
      });
      
    } catch (error) {
      fastify.log.error('Erreur lors de l\'inscription:', error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });

  // GET /auth/user-type/:firebaseUID - Vérifier le type d'utilisateur
  fastify.get('/user-type/:firebaseUID', {
    schema: {
      description: 'Vérifier si un utilisateur existe et récupérer son type',
      tags: ['Auth'],
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
            exists: { type: 'boolean' },
            userType: { type: 'string', enum: ['athlete', 'coach'] },
            user: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                firebaseUID: { type: 'string' },
                email: { type: 'string' },
                displayName: { type: 'string' },
                createdAt: { type: 'string' },
                updatedAt: { type: 'string' }
              }
            },
            coach: {
              type: 'object',
              nullable: true,
              properties: {
                id: { type: 'string' },
                displayName: { type: 'string' },
                specialization: { type: 'string' },
                bio: { type: 'string' },
                certifications: { type: 'array', items: { type: 'string' } }
              }
            }
          }
        },
        404: {
          type: 'object',
          properties: {
            exists: { type: 'boolean' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const { firebaseUID } = request.params;
    
    fastify.log.info(`🔍 Vérification type utilisateur: ${firebaseUID}`);
    
    try {
      const user = await fastify.prisma.user.findUnique({
        where: { firebaseUID },
        include: { 
          coachProfile: true 
        }
      });
      
      if (!user) {
        fastify.log.info(`❌ Utilisateur non trouvé: ${firebaseUID}`);
        return reply.code(404).send({ 
          exists: false 
        });
      }
      
      const userType = user.coachProfile ? 'coach' : 'athlete';
      
      fastify.log.info(`✅ Utilisateur trouvé: ${user.displayName} (${userType})`);
      
      return {
        exists: true,
        userType: userType,
        user: {
          id: user.id,
          firebaseUID: user.firebaseUID,
          email: user.email,
          displayName: user.displayName,
          createdAt: user.createdAt.toISOString(),
          updatedAt: user.updatedAt.toISOString()
        },
        coach: user.coachProfile ? {
          id: user.coachProfile.id,
          displayName: user.coachProfile.displayName,
          specialization: user.coachProfile.specialization,
          bio: user.coachProfile.bio,
          certifications: user.coachProfile.certifications
        } : null
      };
      
    } catch (error) {
      fastify.log.error('Erreur lors de la vérification utilisateur:', error);
      return reply.code(500).send({
        success: false,
        error: 'Erreur interne du serveur'
      });
    }
  });
}

module.exports = authRoutes; 