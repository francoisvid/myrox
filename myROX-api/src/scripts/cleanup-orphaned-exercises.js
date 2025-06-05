const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

async function cleanupOrphanedExercises() {
  try {
    console.log('🧹 Recherche d\'exercices orphelins ou problématiques...\n')
    
    // 1. Trouver les exercices sans templates ni workouts associés
    const orphanedExercises = await prisma.exercise.findMany({
      where: {
        AND: [
          {
            templateExercises: {
              none: {}
            }
          },
          {
            workoutExercises: {
              none: {}
            }
          }
        ]
      },
      select: {
        id: true,
        name: true,
        category: true,
        createdAt: true
      }
    })
    
    // 2. Trouver les exercices avec des noms en doublons
    const duplicateNames = await prisma.exercise.groupBy({
      by: ['name'],
      having: {
        name: {
          _count: {
            gt: 1
          }
        }
      }
    })
    
    // 3. Trouver les exercices avec des noms suspects (test, temp, etc.)
    const suspiciousExercises = await prisma.exercise.findMany({
      where: {
        OR: [
          { name: { contains: 'test', mode: 'insensitive' } },
          { name: { contains: 'temp', mode: 'insensitive' } },
          { name: { contains: 'debug', mode: 'insensitive' } },
          { name: { contains: 'example', mode: 'insensitive' } },
          { name: { startsWith: 'TODO' } },
          { name: { startsWith: 'DELETE' } }
        ]
      },
      select: {
        id: true,
        name: true,
        category: true,
        createdAt: true,
        _count: {
          select: {
            templateExercises: true,
            workoutExercises: true
          }
        }
      }
    })
    
    // Afficher les résultats
    console.log('📊 RÉSULTATS DE L\'ANALYSE')
    console.log('=' .repeat(50))
    
    if (orphanedExercises.length > 0) {
      console.log(`\n⚠️  EXERCICES ORPHELINS (${orphanedExercises.length}):`)
      console.log('(Sans templates ni workouts associés)')
      console.log('-'.repeat(40))
      orphanedExercises.forEach(ex => {
        console.log(`   • ${ex.name} (${ex.category}) - Créé: ${ex.createdAt.toISOString().split('T')[0]}`)
      })
    }
    
    if (duplicateNames.length > 0) {
      console.log(`\n🔄 NOMS EN DOUBLONS (${duplicateNames.length}):`)
      console.log('-'.repeat(40))
      for (const duplicate of duplicateNames) {
        const exercises = await prisma.exercise.findMany({
          where: { name: duplicate.name },
          select: {
            id: true,
            name: true,
            category: true,
            createdAt: true,
            _count: {
              select: {
                templateExercises: true,
                workoutExercises: true
              }
            }
          }
        })
        
        console.log(`   • "${duplicate.name}":`)
        exercises.forEach(ex => {
          console.log(`     - ID: ${ex.id} | Templates: ${ex._count.templateExercises} | Workouts: ${ex._count.workoutExercises}`)
        })
      }
    }
    
    if (suspiciousExercises.length > 0) {
      console.log(`\n🚨 EXERCICES SUSPECTS (${suspiciousExercises.length}):`)
      console.log('(Noms contenant: test, temp, debug, example, TODO, DELETE)')
      console.log('-'.repeat(40))
      suspiciousExercises.forEach(ex => {
        console.log(`   • ${ex.name} | Templates: ${ex._count.templateExercises} | Workouts: ${ex._count.workoutExercises}`)
      })
    }
    
    // Recommandations
    console.log('\n💡 RECOMMANDATIONS:')
    console.log('-'.repeat(40))
    
    if (orphanedExercises.length === 0 && duplicateNames.length === 0 && suspiciousExercises.length === 0) {
      console.log('   • ✅ Aucun problème détecté ! Base de données propre.')
    } else {
      if (orphanedExercises.length > 0) {
        console.log(`   • Considérer la suppression des ${orphanedExercises.length} exercices orphelins`)
      }
      if (duplicateNames.length > 0) {
        console.log(`   • Fusionner ou supprimer les ${duplicateNames.length} doublons`)
      }
      if (suspiciousExercises.length > 0) {
        console.log(`   • Nettoyer les ${suspiciousExercises.length} exercices de test/debug`)
      }
    }
    
    console.log('')
    
    // Option de nettoyage automatique (optionnelle)
    if (process.argv.includes('--cleanup')) {
      console.log('🧹 NETTOYAGE AUTOMATIQUE ACTIVÉ...')
      
      // Supprimer les exercices orphelins avec des noms suspects
      const toDelete = orphanedExercises.filter(ex => 
        ex.name.toLowerCase().includes('test') ||
        ex.name.toLowerCase().includes('temp') ||
        ex.name.toLowerCase().includes('debug')
      )
      
      if (toDelete.length > 0) {
        console.log(`Suppression de ${toDelete.length} exercices orphelins suspects...`)
        for (const ex of toDelete) {
          await prisma.exercise.delete({ where: { id: ex.id } })
          console.log(`   ✅ Supprimé: ${ex.name}`)
        }
      }
      
      console.log('🎯 Nettoyage terminé.')
    } else {
      console.log('💡 Ajoutez --cleanup pour activer le nettoyage automatique')
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error)
  } finally {
    await prisma.$disconnect()
  }
}

// Exécuter le nettoyage
cleanupOrphanedExercises() 