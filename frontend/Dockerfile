FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package.json ./
COPY package-lock.json* ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Build the application
RUN npm run build

# Expose port
EXPOSE 3000

# Use nginx to serve the built files
FROM nginx:alpine
COPY --from=0 /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
CMD ["sh", "-c", "sed \"s|\\$BACKEND_HOST|\\${BACKEND_HOST:-foodhawk-backend}|g\" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
EXPOSE 80
