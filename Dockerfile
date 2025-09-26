# Build stage
FROM node:20-alpine AS builder

# Install pnpm
RUN npm install -g pnpm

# Install necessary tools
RUN apk add --no-cache git sed

# Set working directory
WORKDIR /app

# Copy dependency files first for better caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies first
RUN pnpm install

# Copy source code
COPY . .

# Add 'standalone' mode configuration to next.config.js
RUN if ! grep -q "output: 'standalone'" next.config.js; then \
  sed -i "/^const nextConfig = {/a \  output: 'standalone'," next.config.js; \
  fi

# Set environment variables for build
ENV NEXT_PUBLIC_LK_TOKEN_ENDPOINT=/api/token

# Build the application
RUN pnpm run build

# Runtime stage
FROM node:20-alpine
WORKDIR /app

# Copy built files and necessary resources
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Set environment variables
ENV PORT=3000
EXPOSE 3000

# Start the application
CMD ["node", "server.js"]