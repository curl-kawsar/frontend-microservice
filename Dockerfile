# Multi-stage build for Vite frontend microservice
# Stage 1: Build the application
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Set build-time environment variable for Vite
ARG VITE_API_URL=https://api.prod.example.com
ENV VITE_API_URL=$VITE_API_URL

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install dependencies (including dev dependencies for build)
# Use npm ci if package-lock.json exists, otherwise use npm install
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy source code
COPY . .

# Build the application for production
RUN npm run build

# Stage 2: Serve the application with nginx
FROM nginx:alpine AS production

# Copy built application from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Health check (using wget which is available in nginx:alpine)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]


#
# STAGE 1 (Build): 
# - Uses Node.js 18 Alpine (~200MB) to compile TypeScript and bundle assets
# - Installs all dependencies (including devDependencies) needed for building
# - Runs 'vite build' to create optimized production bundle in ./dist/
# - Injects VITE_API_URL environment variable during build process
#
# STAGE 2 (Production):
# - Uses nginx Alpine (~40MB) as lightweight web server
# - Only copies the built files from Stage 1 (no source code or build tools)
# - Final image size: ~50MB (vs ~200MB if single-stage)
# - Configured for SPA routing with fallback to index.html
# - Includes gzip compression, caching headers, and security features
# - Health check endpoint at /health for container orchestration
# - Runs nginx in foreground to keep container alive
#
# USAGE:
# docker build -t frontend-microservice .
# docker run -p 8080:80 frontend-microservice
