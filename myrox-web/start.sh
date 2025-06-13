#!/bin/bash

echo "🚀 Démarrage de myROX Coach Dashboard"
echo "======================================"

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Arrêter les containers existants
echo "🛑 Arrêt des containers existants..."
docker-compose down

# Démarrer l'application web uniquement
echo "🌐 Démarrage de l'application web..."
docker-compose up -d

# Attendre que l'application soit prête
echo "⏳ Attente du démarrage de l'application..."
sleep 5

# Vérifier l'état
if docker-compose ps | grep -q "Up"; then
    echo "✅ Application démarrée avec succès !"
    echo ""
    echo "🌐 Application web : http://localhost:3002"
    echo ""
    echo "📋 Commandes utiles :"
    echo "  - Voir les logs : docker-compose logs -f web"
    echo "  - Arrêter : docker-compose down"
    echo "  - Redémarrer : docker-compose restart"
    echo ""
    echo "🔧 Pour démarrer la stack complète (DB + API + Web) :"
    echo "  docker-compose -f docker-compose.full.yml up -d"
else
    echo "❌ Erreur lors du démarrage de l'application"
    echo "📋 Vérifiez les logs avec : docker-compose logs"
    exit 1
fi 