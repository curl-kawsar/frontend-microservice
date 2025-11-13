# Multi-stage build: Build app in one stage, serve in another for smaller final image
# Stage 1: Build the application
FROM node:18-alpine AS build    # Lightweight Node.js image for building

WORKDIR /app                    # Set working directory inside container

# Set API URL that Vite will inject into the build
ARG VITE_API_URL=https://api.prod.example.com  # Build-time variable (can be overridden)
ENV VITE_API_URL=$VITE_API_URL                 # Make it available during build

# Copy package files first for better Docker layer caching
COPY package*.json ./           # Copy dependency files only

# Install all dependencies needed for building
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi  # Use fastest install method

# Copy all source code
COPY . .                        # Copy everything else (src/, configs, etc.)

# Build optimized production bundle
RUN npm run build              # Creates ./dist/ folder with built app

# Stage 2: Serve the application with nginx (much smaller final image)
FROM nginx:alpine AS production # Lightweight web server image

# Copy built files from previous stage
COPY --from=build /app/dist /usr/share/nginx/html  # Only copy the built app

# Use custom nginx config for SPA routing and performance
COPY nginx.conf /etc/nginx/conf.d/default.conf     # Custom server configuration

EXPOSE 80                      # Document that app runs on port 80

# Monitor container health automatically
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Start web server in foreground
CMD ["nginx", "-g", "daemon off;"]  # Keep container running
