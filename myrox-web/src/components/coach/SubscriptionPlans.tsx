'use client';

import { CheckIcon } from '@heroicons/react/24/outline';

const plans = [
  {
    id: 'FREE',
    name: 'Gratuit',
    price: '0€',
    period: 'à vie',
    description: 'Parfait pour commencer',
    features: [
      '3 athlètes',
      'Modèles illimités',
      'Support communautaire'
    ],
    limitations: [
      'Fonctionnalités limitées',
      'Pas de statistiques avancées'
    ],
    buttonText: 'Plan actuel',
    buttonStyle: 'bg-gray-300 text-gray-700 cursor-not-allowed',
    popular: false
  },
  {
    id: 'STARTER',
    name: 'Starter',
    price: '19,99€',
    period: ' / mois',
    description: 'Pour les coachs qui se lancent',
    features: [
      '10 athlètes',
      'Modèles illimités',
      'Statistiques de base',
      'Support par email'
    ],
    limitations: [],
    buttonText: 'Choisir Starter',
    buttonStyle: 'bg-blue-600 text-white hover:bg-blue-700',
    popular: false
  },
  {
    id: 'PROFESSIONAL',
    name: 'Professionnel',
    price: '49,99€',
    period: ' / mois',
    description: 'Pour les coachs expérimentés',
    features: [
      '50 athlètes',
      'Modèles illimités',
      'Statistiques avancées',
      'Support prioritaire',
      'Rapports détaillés'
    ],
    limitations: [],
    buttonText: 'Choisir Pro',
    buttonStyle: 'bg-green-600 text-white hover:bg-green-700',
    popular: true
  },
  {
    id: 'ENTERPRISE',
    name: 'Entreprise',
    price: '99,99€',
    period: ' / mois',
    description: 'Pour les structures professionnelles',
    features: [
      'Athlètes illimités',
      'Modèles illimités',
      'Multi-coachs',
      'API personnalisée',
      'Support dédié',
      'Formation incluse'
    ],
    limitations: [],
    buttonText: 'Nous contacter',
    buttonStyle: 'bg-purple-600 text-white hover:bg-purple-700',
    popular: false
  }
];

interface SubscriptionPlansProps {
  currentPlan?: string;
  onSelectPlan?: (planId: string) => void;
}

export default function SubscriptionPlans({ currentPlan = 'FREE', onSelectPlan }: SubscriptionPlansProps) {
  return (
    <div className="bg-white py-12">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-4xl text-center">
          <h2 className="text-base font-semibold leading-7 text-blue-600">Tarifs</h2>
          <p className="mt-2 text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl">
            Choisissez le plan qui vous convient
          </p>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            Évoluez avec vos besoins et développez votre activité de coaching
          </p>
        </div>

        <div className="mx-auto mt-16 pt-4 grid max-w-lg grid-cols-1 gap-y-6 sm:gap-y-6 lg:max-w-none lg:grid-cols-4 lg:gap-x-8">
          {plans.map((plan) => (
            <div
              key={plan.id}
              className={`relative flex flex-col justify-between rounded-3xl bg-white p-8 ring-1 ring-gray-200 xl:p-10 ${
                plan.popular
                  ? 'ring-2 ring-blue-600'
                  : ''
              } ${
                currentPlan === plan.id
                  ? 'ring-2 ring-green-500 bg-green-50'
                  : ''
              }`}
            >
              {plan.popular && (
                <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 w-24 rounded-full bg-blue-600 px-2 py-1 text-xs font-medium text-white text-center z-10">
                  Populaire
                </div>
              )}

              {currentPlan === plan.id && (
                <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 w-24 rounded-full bg-green-600 px-2 py-1 text-xs font-medium text-white text-center z-10">
                  Plan actuel
                </div>
              )}

              <div>
                <div className="flex items-center justify-between gap-x-4">
                  <h3 className="text-lg font-semibold leading-8 text-gray-900">
                    {plan.name}
                  </h3>
                </div>
                <p className="mt-4 text-sm leading-6 text-gray-600 h-10">
                  {plan.description}
                </p>
                <p className="mt-6 flex items-center gap-x-1">
                  <span className="text-4xl font-bold tracking-tight text-gray-900">
                    {plan.price}
                  </span>
                  <span className="text-sm font-semibold leading-6 text-gray-600">
                    {plan.period}
                  </span>
                </p>

                <ul role="list" className="mt-8 space-y-3 text-sm leading-6 text-gray-600">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex gap-x-3">
                      <CheckIcon className="h-6 w-5 flex-none text-blue-600" aria-hidden="true" />
                      {feature}
                    </li>
                  ))}
                </ul>
              </div>

              <button
                onClick={() => onSelectPlan?.(plan.id)}
                disabled={currentPlan === plan.id}
                className={`mt-8 block w-full rounded-md px-3 py-2 text-center text-sm font-semibold focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 ${
                  currentPlan === plan.id
                    ? 'bg-green-100 text-green-800 cursor-not-allowed'
                    : plan.buttonStyle
                }`}
              >
                {currentPlan === plan.id ? 'Plan actuel' : plan.buttonText}
              </button>
            </div>
          ))}
        </div>

        <div className="mt-12 text-center">
          <p className="text-sm text-gray-600">
            Tous les plans incluent une période d&apos;essai de 14 jours •
            Annulation possible à tout moment •
            Support disponible pour tous les plans
          </p>
        </div>
      </div>
    </div>
  );
}
