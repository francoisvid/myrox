import SwiftUI
import Combine

class WatchWorkoutViewModel: ObservableObject {
    @Published var currentExerciseIndex = 0
    @Published var exerciseTimer: TimeInterval = 0
    @Published var isTimerRunning = false
    
    private var timer: Timer?
    private var exerciseStartTime: Date?
    private var workoutStartTime: Date?
    
    var currentExercise: WatchExercise? {
        guard let workout = WatchDataService.shared.activeWorkout else { return nil }
        
        // Trier les exercices par round puis par ordre
        let sortedExercises = workout.exercises.sorted { (exercise1: WatchExercise, exercise2: WatchExercise) in
            if exercise1.round == exercise2.round {
                return exercise1.order < exercise2.order
            }
            return exercise1.round < exercise2.round
        }
        
        // Trouver le premier exercice non complété
        guard let nextExercise = sortedExercises.first(where: { !$0.isCompleted }) else {
            return nil
        }
        
        return nextExercise
    }
    
    var progress: Double {
        guard let workout = WatchDataService.shared.activeWorkout else { return 0 }
        let completed = workout.exercises.filter { $0.isCompleted }.count
        return Double(completed) / Double(workout.exercises.count)
    }
    
    func startExerciseTimer() {
        print("Démarrage du timer d'exercice")
        if workoutStartTime == nil {
            workoutStartTime = Date()
        }
        exerciseStartTime = Date()
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let startTime = self.exerciseStartTime {
                DispatchQueue.main.async {
                    self.exerciseTimer = Date().timeIntervalSince(startTime)
                }
            }
        }
    }
    
    func pauseExerciseTimer() {
        print("Pause du timer d'exercice")
        DispatchQueue.main.async {
            self.isTimerRunning = false
            self.timer?.invalidate()
        }
    }
    
    func completeCurrentExercise() {
        guard let workout = WatchDataService.shared.activeWorkout,
              let currentExercise = currentExercise else {
            print("Impossible de compléter l'exercice - Pas d'exercice actif")
            return
        }
        
        print("Complétion de l'exercice \(currentExercise.name) - Round \(currentExercise.round)")
        
        // Créer une copie mutable du workout
        var updatedWorkout = workout
        
        // Mettre à jour l'exercice actuel
        if let index = updatedWorkout.exercises.firstIndex(where: { $0.id == currentExercise.id }) {
            updatedWorkout.exercises[index].duration = self.exerciseTimer
            updatedWorkout.exercises[index].isCompleted = true
            
            // 🔧 NOUVEAU : Copier les valeurs cibles dans les valeurs réelles
            if let targetDistance = currentExercise.targetDistance {
                updatedWorkout.exercises[index].distance = targetDistance
                print("✅ Distance copiée: \(targetDistance)m pour \(currentExercise.name)")
            }
            
            if let targetRepetitions = currentExercise.targetRepetitions {
                updatedWorkout.exercises[index].repetitions = targetRepetitions
                print("✅ Répétitions copiées: \(targetRepetitions) pour \(currentExercise.name)")
            }
            
            // Mettre à jour le workout dans le service
            WatchDataService.shared.activeWorkout = updatedWorkout
        }
        
        // Réinitialiser le timer pour le prochain exercice
        self.exerciseTimer = 0
        self.exerciseStartTime = nil
        self.pauseExerciseTimer()
        
        // Vérifier s'il reste des exercices
        if self.currentExercise != nil {
            print("Passage à l'exercice suivant")
        } else {
            // Workout terminé
            print("Workout terminé")
            self.finishWorkout()
        }
    }
    
    func previousExercise() {
        guard let workout = WatchDataService.shared.activeWorkout,
              let currentExercise = currentExercise else { return }
        
        // Trier les exercices par round puis par ordre
        let sortedExercises = workout.exercises.sorted { (exercise1: WatchExercise, exercise2: WatchExercise) in
            if exercise1.round == exercise2.round {
                return exercise1.order < exercise2.order
            }
            return exercise1.round < exercise2.round
        }
        
        // Trouver l'index de l'exercice actuel
        if let currentIndex = sortedExercises.firstIndex(where: { $0.id == currentExercise.id }),
           currentIndex > 0 {
            // Trouver le dernier exercice non complété avant l'exercice actuel
            for i in (0..<currentIndex).reversed() {
                if !sortedExercises[i].isCompleted {
                    DispatchQueue.main.async {
                        self.exerciseTimer = 0
                        self.exerciseStartTime = nil
                        self.pauseExerciseTimer()
                        print("Passage à l'exercice précédent: \(sortedExercises[i].name) - Round \(sortedExercises[i].round)")
                    }
                    break
                }
            }
        }
    }
    
    func nextExercise() {
        guard let workout = WatchDataService.shared.activeWorkout,
              let currentExercise = currentExercise else { return }
        
        // Trier les exercices par round puis par ordre
        let sortedExercises = workout.exercises.sorted { (exercise1: WatchExercise, exercise2: WatchExercise) in
            if exercise1.round == exercise2.round {
                return exercise1.order < exercise2.order
            }
            return exercise1.round < exercise2.round
        }
        
        // Trouver l'index de l'exercice actuel
        if let currentIndex = sortedExercises.firstIndex(where: { $0.id == currentExercise.id }),
           currentIndex < sortedExercises.count - 1 {
            // Trouver le prochain exercice non complété après l'exercice actuel
            for i in (currentIndex + 1)..<sortedExercises.count {
                if !sortedExercises[i].isCompleted {
                    DispatchQueue.main.async {
                        self.exerciseTimer = 0
                        self.exerciseStartTime = nil
                        self.pauseExerciseTimer()
                        print("Passage à l'exercice suivant: \(sortedExercises[i].name) - Round \(sortedExercises[i].round)")
                    }
                    break
                }
            }
        }
    }
    
    func finishWorkout() {
        print("Finalisation du workout")
        DispatchQueue.main.async {
            self.timer?.invalidate()
            
            if var workout = WatchDataService.shared.activeWorkout {
                // Calculer le temps total du workout
                if let startTime = self.workoutStartTime {
                    workout.totalDuration = Date().timeIntervalSince(startTime)
                    print("Temps total du workout: \(workout.totalDuration) secondes")
                    
                    // 🔧 NOUVEAU : Calculer la distance totale
                    workout.totalDistance = workout.exercises.reduce(0) { $0 + $1.distance }
                    print("✅ Distance totale calculée: \(workout.totalDistance)m")
                    
                    // Mettre à jour le workout dans le service
                    WatchDataService.shared.activeWorkout = workout
                }
                
                // Vérifier que la somme des exercices correspond
                let exercisesTotal = workout.exercises.reduce(0) { $0 + $1.duration }
                print("Somme des temps d'exercices: \(exercisesTotal) secondes")
                
                // S'assurer que le temps total est au moins égal à la somme des exercices
                if workout.totalDuration < exercisesTotal {
                    workout.totalDuration = exercisesTotal
                    WatchDataService.shared.activeWorkout = workout
                    print("Temps total ajusté à la somme des exercices: \(workout.totalDuration) secondes")
                }
                
                WatchDataService.shared.endWorkoutSession()
            }
        }
    }
    
    func cancelWorkout() {
        print("🔴 Annulation du workout depuis la Watch")
        DispatchQueue.main.async {
            // Arrêter le timer
            self.timer?.invalidate()
            self.isTimerRunning = false
            
            // Réinitialiser les états
            self.exerciseTimer = 0
            self.exerciseStartTime = nil
            self.workoutStartTime = nil
            
            // Supprimer le workout actif
            WatchDataService.shared.activeWorkout = nil
            
            print("✅ Workout annulé depuis la Watch")
        }
    }
}
