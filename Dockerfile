FROM node:18-alpine

RUN apk add --no-cache curl

WORKDIR /app

RUN mkdir -p logs

COPY package*.json ./
RUN npm ci --only=production

COPY tsconfig.json ./
COPY src/ ./src/

# need typescript to build
RUN npm install --save-dev typescript @types/node @types/express
RUN npm run build
RUN npm prune --production

# security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001
RUN chown -R nextjs:nodejs /app
USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/healthz || exit 1

CMD ["npm", "start"]
