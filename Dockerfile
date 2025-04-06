# Stage 1: Build
FROM node:16 AS builder
WORKDIR /app
COPY . .
RUN npm install

# Stage 2: Runtime
FROM node:16-slim
WORKDIR /app
COPY --from=builder /app /app
COPY .env .env
EXPOSE 3000
CMD ["node", "app.js"]
