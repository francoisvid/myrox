const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

// Exercices du ModelContainer iOS (pour comparaison)
const iOSExercises = [
  // 8 Exercices officiels HYROX
  "SkiErg", "Sled Push", "Sled Pull", "Burpees Broad Jump",
  "RowErg", "Farmers Carry", "Sandbag Lunges", "Wall Balls",
  
  // Exercices d'entraînement - Cardio
  "Run", "Assault Bike", "Jump Rope", "Sprint Intervals", "High Knees",
  "Mountain Climbers", "Bear Crawl", "Battle Ropes",
  
  // Force
  "Deadlifts", "Dumbbell Thrusters", "Dumbbell Snatch", "Kettlebell Snatches",
  "Kettlebell Cleans", "Kettlebell Goblet Squats", "Sandbag Cleans", 
  "Sandbag Shouldering", "Weighted Lunges", "Box Step Overs", 
  "Overhead Carry", "Med Ball Slams", "Push-ups", "Wall Sit",
  
  // Core/Functional
  "Plank Hold", "Sit-ups", "Russian Twists", "Hanging Knee Raises",
  "Toes to Bar", "Standing Pallof Press", "Air Squats",
  
  // Plyo
  "Box Jumps", "Broad Jumps", "Jumping Lunges", "Burpees", "Lateral Hops"
]

async function auditExercises() {
  try {
    console.log('🔍 Audit des exercices API vs iOS ModelContainer\n')
    
    // Récupérer les exercices de l'API
    const apiExercises = await prisma.exercise.findMany({
      select: { name: true },
      orderBy: { name: 'asc' }
    })
    
    const apiExerciseNames = apiExercises.map(ex => ex.name)
    const iOSSet = new Set(iOSExercises)
    const apiSet = new Set(apiExerciseNames)
    
    // Calculer les différences
    const onlyIOS = iOSExercises.filter(name => !apiSet.has(name))
    const onlyAPI = apiExerciseNames.filter(name => !iOSSet.has(name))
    const common = iOSExercises.filter(name => apiSet.has(name))
    
    // Afficher les résultats
    console.log('📊 RÉSULTATS DE L\'AUDIT')
    console.log('=' .repeat(50))
    console.log(`Total iOS ModelContainer: ${iOSExercises.length}`)
    console.log(`Total API Database: ${apiExerciseNames.length}`)
    console.log(`Exercices communs: ${common.length}`)
    console.log(`Seulement iOS: ${onlyIOS.length}`)
    console.log(`Seulement API: ${onlyAPI.length}`)
    console.log('')
    
    if (onlyIOS.length > 0) {
      console.log('⚠️  EXERCICES MANQUANTS DANS L\'API (' + onlyIOS.length + '):')
      console.log('-'.repeat(40))
      onlyIOS.forEach(name => console.log(`   • ${name}`))
      console.log('')
    }
    
    if (onlyAPI.length > 0) {
      console.log('📥 EXERCICES SEULEMENT DANS L\'API (' + onlyAPI.length + '):')
      console.log('-'.repeat(40))
      onlyAPI.forEach(name => console.log(`   • ${name}`))
      console.log('')
    }
    
    console.log('✅ EXERCICES SYNCHRONISÉS (' + common.length + '):')
    console.log('-'.repeat(40))
    common.forEach(name => console.log(`   • ${name}`))
    console.log('')
    
    // Recommandations
    console.log('💡 RECOMMANDATIONS:')
    console.log('-'.repeat(40))
    if (onlyIOS.length > 0) {
      console.log(`   • Ajouter ${onlyIOS.length} exercices manquants à l'API`)
    }
    if (onlyAPI.length > 0) {
      console.log(`   • Vérifier si les ${onlyAPI.length} exercices supplémentaires sont nécessaires`)
    }
    if (onlyIOS.length === 0 && onlyAPI.length === 0) {
      console.log('   • ✅ Parfaite synchronisation ! Aucune action requise.')
    }
    
    console.log('')
    
  } catch (error) {
    console.error('❌ Erreur lors de l\'audit:', error)
  } finally {
    await prisma.$disconnect()
  }
}

// Exécuter l'audit
auditExercises() 