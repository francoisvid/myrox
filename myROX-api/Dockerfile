FROM node:18-alpine

WORKDIR /app

# Copie package.json et lockfile
COPY package*.json ./

# Installe les dépendances
RUN npm ci --only=production

# Copie le dossier prisma ET le code source
COPY prisma ./prisma
COPY . .

# Génère le client Prisma
RUN npx prisma generate

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/v1/health || exit 1

CMD ["node", "server.js"]