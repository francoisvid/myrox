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
        guard let workout = WatchDataService.shared.activeWorkout,
              currentExerciseIndex < workout.exercises.count else {
            print("Pas d'exercice actif - Index: \(currentExerciseIndex), Workout: \(String(describing: WatchDataService.shared.activeWorkout))")
            return nil
        }
        return workout.exercises[currentExerciseIndex]
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
              currentExerciseIndex < workout.exercises.count else {
            print("Impossible de compléter l'exercice - Index: \(currentExerciseIndex), Workout: \(String(describing: WatchDataService.shared.activeWorkout))")
            return
        }
        
        print("Complétion de l'exercice \(currentExerciseIndex + 1)/\(workout.exercises.count)")
        
        DispatchQueue.main.async {
            WatchDataService.shared.activeWorkout?.exercises[self.currentExerciseIndex].duration = self.exerciseTimer
            WatchDataService.shared.activeWorkout?.exercises[self.currentExerciseIndex].isCompleted = true
            
            // Passer au suivant
            if self.currentExerciseIndex < workout.exercises.count - 1 {
                self.currentExerciseIndex += 1
                self.exerciseTimer = 0
                self.exerciseStartTime = nil
                self.pauseExerciseTimer()
                print("Passage à l'exercice suivant: \(self.currentExerciseIndex + 1)")
            } else {
                // Workout terminé
                print("Workout terminé")
                self.pauseExerciseTimer()
                self.finishWorkout()
            }
        }
    }
    
    func previousExercise() {
        guard let workout = WatchDataService.shared.activeWorkout else { return }
        
        if currentExerciseIndex > 0 {
            DispatchQueue.main.async {
                self.currentExerciseIndex -= 1
                self.exerciseTimer = 0
                self.exerciseStartTime = nil
                self.pauseExerciseTimer()
                print("Passage à l'exercice précédent: \(self.currentExerciseIndex + 1)")
            }
        }
    }
    
    func nextExercise() {
        guard let workout = WatchDataService.shared.activeWorkout else { return }
        
        if currentExerciseIndex < workout.exercises.count - 1 {
            DispatchQueue.main.async {
                self.currentExerciseIndex += 1
                self.exerciseTimer = 0
                self.exerciseStartTime = nil
                self.pauseExerciseTimer()
                print("Passage à l'exercice suivant: \(self.currentExerciseIndex + 1)")
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
}
