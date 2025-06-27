-- Migration: Ajouter CASCADE DELETE sur personal_bests.workout_id
-- Date: 2025-01-27
-- Description: Quand un workout est supprimé, supprimer automatiquement les Personal Bests associés

-- Supprimer l'ancienne contrainte
ALTER TABLE "personal_bests" DROP CONSTRAINT "personal_bests_workout_id_fkey";

-- Ajouter la nouvelle contrainte avec CASCADE
ALTER TABLE "personal_bests" 
ADD CONSTRAINT "personal_bests_workout_id_fkey" 
FOREIGN KEY ("workout_id") REFERENCES "workouts"("id") ON DELETE CASCADE; 