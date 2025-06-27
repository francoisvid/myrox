-- CreateEnum
CREATE TYPE "HyroxExperience" AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED');

-- CreateEnum
CREATE TYPE "HyroxGoal" AS ENUM ('FIRST_PARTICIPATION', 'IMPROVE_TIME', 'PROFESSIONAL_COMPETITION');

-- CreateEnum
CREATE TYPE "TrainingFrequency" AS ENUM ('ONCE_WEEK', 'TWICE_WEEK', 'THREE_WEEK', 'FOUR_WEEK', 'FIVE_PLUS_WEEK');

-- CreateEnum
CREATE TYPE "SessionDuration" AS ENUM ('THIRTY_MIN', 'FORTY_FIVE_MIN', 'ONE_HOUR', 'ONE_HOUR_PLUS');

-- CreateEnum
CREATE TYPE "TrainingTime" AS ENUM ('MORNING', 'MIDDAY', 'EVENING', 'FLEXIBLE');

-- CreateEnum
CREATE TYPE "TrainingIntensity" AS ENUM ('SHORT_INTENSE', 'LONG_MODERATE', 'MIXED');

-- CreateEnum
CREATE TYPE "SubscriptionPlan" AS ENUM ('FREE', 'STARTER', 'PROFESSIONAL', 'ENTERPRISE');

-- AlterTable
ALTER TABLE "coaches" ADD COLUMN     "is_subscription_active" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "max_athletes" INTEGER NOT NULL DEFAULT 3,
ADD COLUMN     "max_invitations" INTEGER NOT NULL DEFAULT 5,
ADD COLUMN     "subscription_expires_at" TIMESTAMP(3),
ADD COLUMN     "subscription_plan" "SubscriptionPlan" NOT NULL DEFAULT 'FREE',
ADD COLUMN     "trial_ends_at" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "user_informations" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "has_completed_onboarding" BOOLEAN NOT NULL DEFAULT false,
    "hyrox_experience" "HyroxExperience",
    "has_competed_hyrox" BOOLEAN,
    "primary_goal" "HyroxGoal",
    "current_training_frequency" "TrainingFrequency",
    "training_types" TEXT[],
    "fitness_level" INTEGER,
    "injuries_limitations" TEXT,
    "familiar_hyrox_stations" BOOLEAN,
    "difficult_exercises" TEXT[],
    "has_gym_access" BOOLEAN,
    "gym_name" TEXT,
    "gym_location" TEXT,
    "available_equipment" TEXT[],
    "preferred_training_frequency" "TrainingFrequency",
    "preferred_session_duration" "SessionDuration",
    "target_competition_date" TIMESTAMP(3),
    "preferred_training_time" "TrainingTime",
    "preferred_intensity" "TrainingIntensity",
    "prefers_structured_program" BOOLEAN,
    "wants_notifications" BOOLEAN,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "completed_at" TIMESTAMP(3),

    CONSTRAINT "user_informations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coach_invitations" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "coach_id" TEXT NOT NULL,
    "used_by_user_id" TEXT,
    "used_at" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "coach_invitations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "user_informations_user_id_key" ON "user_informations"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "coach_invitations_code_key" ON "coach_invitations"("code");

-- CreateIndex
CREATE UNIQUE INDEX "coach_invitations_used_by_user_id_key" ON "coach_invitations"("used_by_user_id");

-- AddForeignKey
ALTER TABLE "user_informations" ADD CONSTRAINT "user_informations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coach_invitations" ADD CONSTRAINT "coach_invitations_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "coaches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "coach_invitations" ADD CONSTRAINT "coach_invitations_used_by_user_id_fkey" FOREIGN KEY ("used_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
