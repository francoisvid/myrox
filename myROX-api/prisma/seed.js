const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Seeding database...')

  // Create HYROX exercises
  const exercises = await Promise.all([
    // HYROX Stations
    prisma.exercise.create({
      data: {
        name: '1000m SkiErg',
        description: 'Ski ergometer - full body cardio exercise',
        category: 'HYROX_STATION',
        equipment: ['SkiErg'],
        instructions: 'Maintain steady pace with full body engagement',
        isHyroxExercise: true
      }
    }),
    prisma.exercise.create({
      data: {
        name: '50m Sled Push',
        description: 'Heavy sled push',
        category: 'HYROX_STATION', 
        equipment: ['Sled', 'Weight plates'],
        instructions: 'Push sled with low body position, drive with legs',
        isHyroxExercise: true
      }
    }),
    prisma.exercise.create({
      data: {
        name: '50m Sled Pull',
        description: 'Heavy sled pull',
        category: 'HYROX_STATION',
        equipment: ['Sled', 'Rope', 'Weight plates'],
        instructions: 'Pull sled hand over hand, maintain tension',
        isHyroxExercise: true
      }
    }),
    prisma.exercise.create({
      data: {
        name: '80m Burpee Broad Jumps',
        description: 'Burpee with broad jump movement',
        category: 'HYROX_STATION',
        equipment: [],
        instructions: 'Burpee followed by broad jump, continuous movement',
        isHyroxExercise: true
      }
    }),
    prisma.exercise.create({
      data: {
        name: '1000m Row',
        description: 'Rowing machine cardio',
        category: 'HYROX_STATION',
        equipment: ['Rowing machine'],
        instructions: 'Maintain stroke rate around 24-28 spm',
        isHyroxExercise: true
      }
    }),
    prisma.exercise.create({
      data: {
        name: '200m Farmers Carry',
        description: 'Farmer carry with kettlebells',
        category: 'HYROX_STATION',
        equipment: ['Kettlebells'],
        instructions: 'Maintain upright posture, steady pace',
        isHyroxExercise: true
      }
    }),
    prisma.exercise.create({
      data: {
        name: '100m Sandbag Lunges',
        description: 'Walking lunges with sandbag',
        category: 'HYROX_STATION',
        equipment: ['Sandbag'],
        instructions: 'Deep lunges, sandbag across shoulders',
        isHyroxExercise: true
      }
    }),
    prisma.exercise.create({
      data: {
        name: '75/100 Wall Balls',
        description: 'Wall ball shots to target',
        category: 'HYROX_STATION',
        equipment: ['Medicine ball', 'Wall target'],
        instructions: 'Full squat depth, hit target on wall',
        isHyroxExercise: true
      }
    }),

    // Running
    prisma.exercise.create({
      data: {
        name: '1km Run',
        description: 'Standard 1 kilometer run',
        category: 'RUNNING',
        equipment: [],
        instructions: 'Maintain steady pace throughout',
        isHyroxExercise: true
      }
    }),

    // General Strength
    prisma.exercise.create({
      data: {
        name: 'Push-ups',
        description: 'Standard push-up exercise',
        category: 'STRENGTH',
        equipment: [],
        instructions: 'Full range of motion, maintain plank position'
      }
    }),
    prisma.exercise.create({
      data: {
        name: 'Pull-ups',
        description: 'Pull-up exercise',
        category: 'STRENGTH',
        equipment: ['Pull-up bar'],
        instructions: 'Full range of motion, chin over bar'
      }
    }),
    prisma.exercise.create({
      data: {
        name: 'Air Squats',
        description: 'Bodyweight squats',
        category: 'FUNCTIONAL',
        equipment: [],
        instructions: 'Full depth squat, thighs parallel to ground'
      }
    })
  ])

  console.log('✅ Created exercises')

  // Create sample user
  const user = await prisma.user.create({
    data: {
      firebaseUID: 'sample-user-123',
      email: 'athlete@myrox.app',
      displayName: 'Sample Athlete'
    }
  })

  console.log('✅ Created sample user')

  // Create HYROX template
  const hyroxTemplate = await prisma.template.create({
    data: {
      name: 'Full HYROX Simulation',
      description: 'Complete HYROX race simulation with all 8 stations',
      difficulty: 'ADVANCED',
      estimatedTime: 90,
      category: 'HYROX',
      creatorId: user.id,
      exercises: {
        create: [
          { order: 1, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 2, exerciseId: exercises.find(e => e.name === '1000m SkiErg').id },
          { order: 3, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 4, exerciseId: exercises.find(e => e.name === '50m Sled Push').id, weight: 152 },
          { order: 5, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 6, exerciseId: exercises.find(e => e.name === '50m Sled Pull').id, weight: 103 },
          { order: 7, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 8, exerciseId: exercises.find(e => e.name === '80m Burpee Broad Jumps').id },
          { order: 9, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 10, exerciseId: exercises.find(e => e.name === '1000m Row').id },
          { order: 11, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 12, exerciseId: exercises.find(e => e.name === '200m Farmers Carry').id, weight: 24 },
          { order: 13, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 14, exerciseId: exercises.find(e => e.name === '100m Sandbag Lunges').id, weight: 20 },
          { order: 15, exerciseId: exercises.find(e => e.name === '1km Run').id },
          { order: 16, exerciseId: exercises.find(e => e.name === '75/100 Wall Balls').id, reps: 75, weight: 9 }
        ]
      }
    }
  })

  console.log('✅ Created HYROX template')

  // Create beginner template
  const beginnerTemplate = await prisma.template.create({
    data: {
      name: 'Functional Fitness Intro',
      description: 'Perfect for beginners to functional fitness',
      difficulty: 'BEGINNER',
      estimatedTime: 30,
      category: 'FUNCTIONAL',
      creatorId: user.id,
      exercises: {
        create: [
          { order: 1, exerciseId: exercises.find(e => e.name === 'Air Squats').id, sets: 3, reps: 15 },
          { order: 2, exerciseId: exercises.find(e => e.name === 'Push-ups').id, sets: 3, reps: 10 },
          { order: 3, exerciseId: exercises.find(e => e.name === '1km Run').id, distance: 500 }
        ]
      }
    }
  })

  console.log('✅ Created beginner template')
  console.log('🎉 Database seeded successfully!')
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  }) 