# Task Manager — Production Ready Docker Stack

A production-style containerized full-stack application built using Docker.

This project demonstrates how to deploy a scalable backend architecture using:

* Nginx (Reverse Proxy + Load Balancer)
* Flask API (2 containers)
* PostgreSQL Database
* Redis Cache

The entire infrastructure is orchestrated using Docker Compose and follows container best practices such as health checks, environment variables, SSL, and multi-stage builds.

This project was built as part of the **Docker Advanced Course – Lab 7**.

---

# Architecture

The application runs using the following architecture:

```
Client (Browser / Curl)
        |
        v
     Nginx
Reverse Proxy + SSL
Load Balancer
        |
   -------------
   |           |
Flask1       Flask2
Gunicorn     Gunicorn
   |           |
   ------+------
          |
      PostgreSQL
          |
        Redis
```

Nginx distributes incoming requests between the two Flask containers using load balancing.

---

# Tech Stack

* Docker
* Docker Compose
* Python Flask
* Gunicorn
* Nginx
* PostgreSQL
* Redis
* OpenSSL

---

# Project Structure

```
task-manager/
│
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env
│
├── conf/
│   └── nginx.conf
│
├── ssl/
│   └── generate_ssl.sh
│
├── static/
│   └── style.css
│
├── flask_app.py
├── init.sql
├── requirements.txt
│
└── README.md
```

---

# Services

The application is composed of **5 containers**.

### Nginx

Responsible for:

* Reverse proxy
* Load balancing
* SSL termination
* Serving static files

### Flask Containers

Two backend containers run the Flask API:

* flask1
* flask2

Each runs using **Gunicorn** as a production WSGI server.

### PostgreSQL

Stores all tasks data and initializes the schema using:

```
init.sql
```

### Redis

Used as a caching layer for improved performance.

---

# API Endpoints

| Method | Endpoint             | Description            |
| ------ | -------------------- | ---------------------- |
| GET    | /                    | Frontend page          |
| GET    | /api/health          | Health check           |
| GET    | /api/tasks           | List all tasks         |
| POST   | /api/tasks           | Create new task        |
| PATCH  | /api/tasks/<id>/done | Mark task as completed |

---

# Environment Variables

Sensitive configuration values are stored in the `.env` file.

Examples include:

* POSTGRES_DB
* POSTGRES_USER
* POSTGRES_PASSWORD
* REDIS_HOST
* REDIS_PORT

Important:
The `.env` file is **never committed to GitHub**.

---

# How to Run the Project

## 1 Generate SSL Certificates

Before starting the containers, generate a self-signed SSL certificate.

```
cd ssl
bash generate_ssl.sh
cd ..
```

---

## 2 Build and Start Containers

```
docker compose up -d --build
```

The first build may take a few minutes.

---

## 3 Verify Containers

```
docker compose ps
```

All services should show:

```
healthy
```

Expected services:

```
nginx
flask1
flask2
postgres
redis
```

---

# Access the Application

Open the application in your browser:

```
https://localhost
```

Because the certificate is self-signed you will see a warning.

Choose:

```
Advanced → Proceed
```

---

# Testing the API

## Health Check

```
curl -k https://localhost/api/health
```

Expected response:

```
{
  "status": "healthy",
  "db": true,
  "redis": true
}
```

---

## Create a Task

```
curl -k -X POST https://localhost/api/tasks \
-H "Content-Type: application/json" \
-d '{"title":"My Task","priority":"high"}'
```

---

## Mark Task as Completed

```
curl -k -X PATCH https://localhost/api/tasks/1/done
```

Expected response:

```
{"message":"Task 1 marked done"}
```

---

# Load Balancing

Nginx distributes requests between two Flask containers using an upstream configuration.

When running the health endpoint multiple times:

```
curl -k https://localhost/api/health
```

The responding worker alternates between:

```
flask1
flask2
```

This confirms load balancing is working correctly.

---

# Health Checks

Each container includes a health check.

| Service  | Health Check             |
| -------- | ------------------------ |
| Flask    | /api/health endpoint     |
| Postgres | pg_isready               |
| Redis    | redis-cli ping           |
| Nginx    | container running status |

Docker Compose uses:

```
depends_on:
  condition: service_healthy
```

to ensure services start in the correct order.

---

# Security Best Practices

The project follows several security best practices:

* Containers run as non-root users
* Environment variables stored in `.env`
* `.env` excluded from GitHub
* `.dockerignore` prevents secrets from entering images
* HTTPS enabled using SSL certificates
* Rate limiting configured in Nginx

---

# Bonus — Multi Stage Docker Build

The Dockerfile uses a **multi-stage build** to reduce the final image size and improve security.

Instead of a single build stage, the Dockerfile includes multiple `FROM` instructions.

Example structure:

```
FROM python:3.11-alpine AS builder
```

The builder stage installs dependencies and compiles packages.

```
FROM python:3.11-alpine AS runtime
```

The runtime stage copies only the necessary files from the builder stage.

Benefits:

* Smaller image size
* Faster deployments
* Cleaner production environment
* No build tools inside the final container

Using multi-stage builds reduced the image size from approximately:

```
~1GB → ~120MB
```

---

# Useful Docker Commands

Check running services:

```
docker compose ps
```

View logs:

```
docker compose logs -f
```

Check Flask container logs:

```
docker compose logs flask1
```

Restart everything:

```
docker compose down -v
docker compose up -d --build
```

---

# Troubleshooting

### 502 Bad Gateway

Check Flask container logs:

```
docker compose logs flask1
```

---

### SSL Certificate Not Found

Regenerate the certificate:

```
bash ssl/generate_ssl.sh
```

---

### Database Tables Missing

Ensure `init.sql` is mounted correctly in the PostgreSQL container.

---

# Author

Anas Mohamed Galal
DevOps Engineer (in progress)

Background in Telecommunications Engineering with a focus on:

* Linux
* Docker
* Kubernetes
* DevOps Automation
