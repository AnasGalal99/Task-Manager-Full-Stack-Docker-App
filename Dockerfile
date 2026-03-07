# -----------------------------
# Builder Stage
# -----------------------------

# Use Python 3.11 based on Alpine Linux as a lightweight base image
FROM python:3.11-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Install build dependencies required to compile Python packages
# gcc           -> C compiler required for building native extensions
# musl-dev      -> Development libraries for Alpine's C standard library
# postgresql-dev-> PostgreSQL development headers for psycopg2
# python3-dev   -> Python headers needed to build Python extensions
RUN apk add --no-cache gcc musl-dev postgresql-dev python3-dev

# Copy only requirements.txt first to leverage Docker layer caching
COPY requirements.txt .

# Build Python wheel packages for all dependencies
# --no-cache-dir  -> disable pip cache to reduce image size
# --no-deps       -> do not resolve dependencies again
# --wheel-dir     -> directory where compiled wheels will be stored
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt


# -----------------------------
# Runtime Stage
# -----------------------------

# Start a fresh lightweight Python Alpine image for the final container
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Install runtime dependencies only
# libpq -> PostgreSQL client library required by psycopg2 at runtime
# wget  -> used for container healthcheck
RUN apk add --no-cache libpq wget

# Copy pre-built wheels from the builder stage
COPY --from=builder /usr/src/app/wheels /wheels

# Install dependencies from wheels then remove them to reduce image size
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

# Create a non-root group and user for better container security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy application source code into the container
COPY . .

# Change ownership of application files to the non-root user
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Define a health check to verify that the API is responding
# Docker will call this endpoint every 30 seconds
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:8000/api/health || exit 1

# Start the Flask application using Gunicorn
# -w 2         -> number of worker processes
# -b 0.0.0.0   -> listen on all network interfaces
# :8000        -> port number
# flask_app:app-> module and Flask application instance
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8000", "flask_app:app"]
