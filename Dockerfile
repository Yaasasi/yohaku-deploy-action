FROM node:20-alpine AS runtime

WORKDIR /app
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

COPY apps/web/.next/standalone/ ./

EXPOSE 3000

CMD ["node", "server.js"]
