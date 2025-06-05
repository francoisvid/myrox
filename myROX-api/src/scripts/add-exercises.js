const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

// Exercices basés sur le ModelContainer iOS
const exercises = [
  // 8 Exercices officiels HYROX avec valeurs de compétition
  {
    name: "SkiErg",
    description: "Machine SkiErg",
    category: "HYROX_STATION",
    equipment: ["SkiErg"],
    instructions: "Maintenez un rythme régulier avec engagement de tout le corps",
    isHyroxExercise: true
  },
  {
    name: "Sled Push",
    description: "Poussée de traîneau",
    category: "HYROX_STATION", 
    equipment: ["Sled", "Weight plates"],
    instructions: "Poussez le traîneau avec une position corporelle basse, propulsez avec les jambes",
    isHyroxExercise: true
  },
  {
    name: "Sled Pull",
    description: "Traction de traîneau",
    category: "HYROX_STATION",
    equipment: ["Sled", "Rope", "Weight plates"],
    instructions: "Tirez le traîneau main après main, maintenez la tension",
    isHyroxExercise: true
  },
  {
    name: "Burpees Broad Jump",
    description: "Burpees avec saut en longueur",
    category: "HYROX_STATION",
    equipment: [],
    instructions: "Burpee suivi d'un saut en longueur, mouvement continu",
    isHyroxExercise: true
  },
  {
    name: "RowErg",
    description: "Rameur",
    category: "HYROX_STATION",
    equipment: ["Rowing machine"],
    instructions: "Maintenez un taux de coups autour de 24-28 spm",
    isHyroxExercise: true
  },
  {
    name: "Farmers Carry",
    description: "Transport de poids",
    category: "HYROX_STATION",
    equipment: ["Kettlebells"],
    instructions: "Maintenez une posture droite, rythme régulier",
    isHyroxExercise: true
  },
  {
    name: "Sandbag Lunges",
    description: "Fentes avec sac de sable",
    category: "HYROX_STATION",
    equipment: ["Sandbag"],
    instructions: "Fentes profondes, sac de sable sur les épaules",
    isHyroxExercise: true
  },
  {
    name: "Wall Balls",
    description: "Wall balls",
    category: "HYROX_STATION",
    equipment: ["Medicine ball", "Wall target"],
    instructions: "Profondeur complète du squat, touchez la cible au mur",
    isHyroxExercise: true
  },
  
  // Exercices d'entraînement supplémentaires - Cardio
  {
    name: "Run",
    description: "Course à pied",
    category: "RUNNING",
    equipment: [],
    instructions: "Maintenez un rythme régulier tout au long",
    isHyroxExercise: false
  },
  {
    name: "Assault Bike",
    description: "Exercice sur Assault Bike",
    category: "CARDIO",
    equipment: ["Assault Bike"],
    instructions: "Engagement de tout le corps, maintenir le rythme",
    isHyroxExercise: false
  },
  {
    name: "Jump Rope",
    description: "Exercice de corde à sauter",
    category: "CARDIO",
    equipment: ["Jump rope"],
    instructions: "Sauts légers, mouvement de poignets",
    isHyroxExercise: false
  },
  {
    name: "Sprint Intervals",
    description: "Intervalles de sprint",
    category: "CARDIO",
    equipment: [],
    instructions: "Alternez entre sprint et récupération",
    isHyroxExercise: false
  },
  {
    name: "High Knees",
    description: "Exercice de genoux hauts",
    category: "CARDIO",
    equipment: [],
    instructions: "Levez les genoux haut, rythme rapide",
    isHyroxExercise: false
  },
  {
    name: "Mountain Climbers",
    description: "Exercice de grimpeurs",
    category: "CARDIO",
    equipment: [],
    instructions: "Position de planche, alternez les genoux vers la poitrine",
    isHyroxExercise: false
  },
  {
    name: "Bear Crawl",
    description: "Exercice de déplacement en ours",
    category: "CARDIO",
    equipment: [],
    instructions: "Déplacement à quatre pattes, genoux légèrement décollés",
    isHyroxExercise: false
  },
  {
    name: "Battle Ropes",
    description: "Exercice avec cordes ondulatoires",
    category: "CARDIO",
    equipment: ["Battle ropes"],
    instructions: "Mouvements ondulatoires avec engagement du core",
    isHyroxExercise: false
  },
  
  // Force
  {
    name: "Deadlifts",
    description: "Soulevés de terre",
    category: "STRENGTH",
    equipment: ["Barbell", "Weight plates"],
    instructions: "Dos droit, mouvement de hanches",
    isHyroxExercise: false
  },
  {
    name: "Dumbbell Thrusters",
    description: "Thrusters avec haltères",
    category: "STRENGTH",
    equipment: ["Dumbbells"],
    instructions: "Squat et press combinés en un mouvement",
    isHyroxExercise: false
  },
  {
    name: "Dumbbell Snatch",
    description: "Arraché avec haltère",
    category: "STRENGTH",
    equipment: ["Dumbbell"],
    instructions: "Mouvement explosif du sol au-dessus de la tête",
    isHyroxExercise: false
  },
  {
    name: "Kettlebell Snatches",
    description: "Arrachés avec kettlebell",
    category: "STRENGTH",
    equipment: ["Kettlebell"],
    instructions: "Mouvement de hanches explosif",
    isHyroxExercise: false
  },
  {
    name: "Kettlebell Cleans",
    description: "Clean avec kettlebell",
    category: "STRENGTH",
    equipment: ["Kettlebell"],
    instructions: "Remontée en position rack",
    isHyroxExercise: false
  },
  {
    name: "Kettlebell Goblet Squats",
    description: "Squats goblet avec kettlebell",
    category: "STRENGTH",
    equipment: ["Kettlebell"],
    instructions: "Kettlebell tenue près de la poitrine",
    isHyroxExercise: false
  },
  {
    name: "Sandbag Cleans",
    description: "Clean avec sac de sable",
    category: "STRENGTH",
    equipment: ["Sandbag"],
    instructions: "Remontée du sac en position rack",
    isHyroxExercise: false
  },
  {
    name: "Sandbag Shouldering",
    description: "Portage de sac de sable sur l'épaule",
    category: "STRENGTH",
    equipment: ["Sandbag"],
    instructions: "Montée du sac sur l'épaule",
    isHyroxExercise: false
  },
  {
    name: "Weighted Lunges",
    description: "Fentes avec poids",
    category: "STRENGTH",
    equipment: ["Dumbbells"],
    instructions: "Fentes profondes avec charge",
    isHyroxExercise: false
  },
  {
    name: "Box Step Overs",
    description: "Montées sur caisse",
    category: "STRENGTH",
    equipment: ["Box"],
    instructions: "Montée complète sur la caisse",
    isHyroxExercise: false
  },
  {
    name: "Overhead Carry",
    description: "Transport en position overhead",
    category: "STRENGTH",
    equipment: ["Dumbbells"],
    instructions: "Transport avec poids au-dessus de la tête",
    isHyroxExercise: false
  },
  {
    name: "Med Ball Slams",
    description: "Lancers de médecine ball",
    category: "STRENGTH",
    equipment: ["Medicine ball"],
    instructions: "Levée et lancer explosif au sol",
    isHyroxExercise: false
  },
  {
    name: "Push-ups",
    description: "Pompes",
    category: "STRENGTH",
    equipment: [],
    instructions: "Amplitude complète, maintenir la position de planche",
    isHyroxExercise: false
  },
  {
    name: "Wall Sit",
    description: "Position assise contre un mur",
    category: "STRENGTH",
    equipment: [],
    instructions: "Position assise maintenue contre le mur",
    isHyroxExercise: false
  },
  
  // Core
  {
    name: "Plank Hold",
    description: "Gainage en planche",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Position de planche maintenue, corps aligné",
    isHyroxExercise: false
  },
  {
    name: "Sit-ups",
    description: "Redressements assis",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Redressement complet du tronc",
    isHyroxExercise: false
  },
  {
    name: "Russian Twists",
    description: "Rotations russes",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Rotations du tronc assis",
    isHyroxExercise: false
  },
  {
    name: "Hanging Knee Raises",
    description: "Élévations de genoux suspendu",
    category: "FUNCTIONAL",
    equipment: ["Pull-up bar"],
    instructions: "Élévation des genoux vers la poitrine suspendu",
    isHyroxExercise: false
  },
  {
    name: "Toes to Bar",
    description: "Orteils à la barre",
    category: "FUNCTIONAL",
    equipment: ["Pull-up bar"],
    instructions: "Orteils touchent la barre de traction",
    isHyroxExercise: false
  },
  {
    name: "Standing Pallof Press",
    description: "Press Pallof debout",
    category: "FUNCTIONAL",
    equipment: ["Cable machine"],
    instructions: "Résistance anti-rotation debout",
    isHyroxExercise: false
  },
  {
    name: "Air Squats",
    description: "Squats au poids du corps",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Squats complets au poids du corps",
    isHyroxExercise: false
  },
  
  // Plyo
  {
    name: "Box Jumps",
    description: "Sauts sur caisse",
    category: "FUNCTIONAL",
    equipment: ["Box"],
    instructions: "Saut explosif sur la caisse",
    isHyroxExercise: false
  },
  {
    name: "Broad Jumps",
    description: "Sauts en longueur",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Saut en longueur explosif",
    isHyroxExercise: false
  },
  {
    name: "Jumping Lunges",
    description: "Fentes sautées",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Fentes avec changement de jambe en sautant",
    isHyroxExercise: false
  },
  {
    name: "Burpees",
    description: "Burpees classiques",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Mouvement complet corps : squat, planche, pompe, saut",
    isHyroxExercise: false
  },
  {
    name: "Lateral Hops",
    description: "Sauts latéraux",
    category: "FUNCTIONAL",
    equipment: [],
    instructions: "Sauts latéraux sur une jambe ou deux",
    isHyroxExercise: false
  }
]

async function addExercises() {
  console.log('🚀 Début de l\'ajout des exercices...')
  
  // Vérifier les exercices existants
  const existingExercises = await prisma.exercise.findMany()
  console.log(`📊 Exercices existants : ${existingExercises.length}`)
  
  let addedCount = 0
  let skippedCount = 0
  
  for (const exercise of exercises) {
    // Vérifier si l'exercice existe déjà
    const existing = existingExercises.find(e => e.name === exercise.name)
    
    if (existing) {
      console.log(`⏭️  Exercice déjà existant : ${exercise.name}`)
      skippedCount++
      continue
    }
    
    try {
      await prisma.exercise.create({
        data: exercise
      })
      console.log(`✅ Exercice ajouté : ${exercise.name}`)
      addedCount++
    } catch (error) {
      console.error(`❌ Erreur pour ${exercise.name} :`, error.message)
    }
  }
  
  console.log('\n📊 Résumé :')
  console.log(`✅ Exercices ajoutés : ${addedCount}`)
  console.log(`⏭️  Exercices ignorés (déjà existants) : ${skippedCount}`)
  console.log(`📝 Total exercices traités : ${exercises.length}`)
}

async function main() {
  try {
    await addExercises()
  } catch (error) {
    console.error('💥 Erreur globale :', error)
  } finally {
    await prisma.$disconnect()
  }
}

main() 