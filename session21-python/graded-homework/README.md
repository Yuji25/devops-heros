# Lecture 21 — DevSecOps Python TaskBoard

## Homework Overview

In this session I deployed the provided three-tier TaskBoard application using two approaches:

```text
Manual Deployment
Frontend + Backend + PostgreSQL

        ↓

Docker Deployment
Frontend Dockerfile
Backend Dockerfile
PostgreSQL Image

        ↓

Docker Compose
Frontend + Backend + PostgreSQL
```

The application uses:

- React + Vite frontend
- FastAPI Python backend
- PostgreSQL database
- SQLAlchemy and Alembic
- Docker
- Docker Compose

The backend provides REST APIs as well as health and Prometheus metrics endpoints. The supplied application exposes `/health`, `/ready`, `/metrics`, Swagger `/docs`, and CRUD task APIs. 

---

# Architecture

```text
Browser
   |
   v
Frontend
React + Vite / Nginx
   |
   v
FastAPI Backend
   |
   v
PostgreSQL
```

For Docker Compose:

```text
localhost:3000
      |
      v
Frontend Container
      |
      | /api
      v
Backend Container :8000
      |
      v
PostgreSQL Container :5432
      |
      v
Persistent Docker Volume
```

---

# Task 1 — Environment Setup

Ran this from:

```text
devops-heros/session21-python
```

```bash
set -e

echo "=== DOCKER ==="
docker info >/dev/null
docker --version
docker compose version

echo ""
echo "=== PYTHON ==="
python3 --version

echo ""
echo "=== NODE ==="
node --version
npm --version

echo ""
echo "=== POSTGRESQL ==="

if ! command -v psql >/dev/null 2>&1; then
  echo "PostgreSQL not found - installing..."
  sudo apt-get update -qq
  sudo apt-get install -y postgresql postgresql-contrib
fi

sudo systemctl start postgresql

psql --version

mkdir -p graded-homework/screenshots

echo ""
echo "LECTURE 21 PREFLIGHT PASSED"
```

---

# Task 2 — Manual Deployment

For the manual deployment:

```text
PostgreSQL → Local service
Backend    → FastAPI on port 8080
Frontend   → Vite on port 5173
```

Port `8080` is used for the manual backend because the supplied Vite development proxy points `/api` to `localhost:8080`. 

## Task 2.1 — Start PostgreSQL, Backend and Frontend

Ran this entire block:

```bash
set -e

echo "=== PREPARE POSTGRESQL ==="

sudo systemctl start postgresql

if ! sudo -u postgres psql -tAc \
  "SELECT 1 FROM pg_roles WHERE rolname='taskboard'" |
  grep -q 1; then

  sudo -u postgres psql \
    -c "CREATE ROLE taskboard LOGIN PASSWORD 'taskboard';"
fi

sudo -u postgres psql \
  -c "ALTER ROLE taskboard WITH LOGIN PASSWORD 'taskboard';" \
  >/dev/null

if ! sudo -u postgres psql -tAc \
  "SELECT 1 FROM pg_database WHERE datname='taskboard'" |
  grep -q 1; then

  sudo -u postgres createdb \
    -O taskboard \
    taskboard
fi

echo "PostgreSQL database READY"

echo ""
echo "=== PREPARE BACKEND ==="

rm -rf /tmp/l21-venv
python3 -m venv /tmp/l21-venv

/tmp/l21-venv/bin/python \
  -m pip install --upgrade pip \
  >/dev/null

# Starter repo pins psycopg 3.2.3, which has no compatible
# binary build for the current Python version.
# Use a temporary requirements file without changing the repo.

sed \
  's/psycopg\[binary\]==3\.2\.3/psycopg[binary]==3.3.6/' \
  backend/requirements.txt \
  >/tmp/l21-requirements.txt

/tmp/l21-venv/bin/pip install \
  -r /tmp/l21-requirements.txt \
  >/dev/null

echo "Backend dependencies installed"

cd backend

echo ""
echo "=== DATABASE MIGRATION ==="

DATABASE_URL='postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard' \
  /tmp/l21-venv/bin/alembic upgrade head

if [ -f /tmp/l21-backend.pid ]; then
  kill "$(cat /tmp/l21-backend.pid)" 2>/dev/null || true
fi

echo ""
echo "=== START BACKEND ==="

nohup env \
  DATABASE_URL='postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard' \
  /tmp/l21-venv/bin/uvicorn \
  app.main:app \
  --host 127.0.0.1 \
  --port 8080 \
  >/tmp/l21-backend.log 2>&1 &

echo $! >/tmp/l21-backend.pid

cd ..

echo ""
echo "=== PREPARE FRONTEND ==="

cd frontend

npm install \
  --no-package-lock \
  --silent

if [ -f /tmp/l21-frontend.pid ]; then
  kill "$(cat /tmp/l21-frontend.pid)" 2>/dev/null || true
fi

nohup npm run dev -- \
  --host 127.0.0.1 \
  >/tmp/l21-frontend.log 2>&1 &

echo $! >/tmp/l21-frontend.pid

cd ..

echo ""
echo "=== WAITING FOR BACKEND AND FRONTEND ==="

SUCCESS=0

for i in {1..40}; do
  if curl -fsS \
       http://127.0.0.1:8080/ready \
       >/dev/null 2>&1 &&
     curl -fsS \
       http://127.0.0.1:5173 \
       >/dev/null 2>&1; then

    SUCCESS=1
    break
  fi

  sleep 2
done

if [ "$SUCCESS" -ne 1 ]; then
  echo "Manual deployment failed"

  echo ""
  echo "=== BACKEND LOG ==="
  tail -n 25 /tmp/l21-backend.log

  echo ""
  echo "=== FRONTEND LOG ==="
  tail -n 25 /tmp/l21-frontend.log

  exit 1
fi

echo ""
echo "=== BACKEND HEALTH ==="
curl -fsS http://127.0.0.1:8080/health
echo

echo ""
echo "=== DATABASE READINESS ==="
curl -fsS http://127.0.0.1:8080/ready
echo

echo ""
echo "=== CREATE TEST TASK ==="

curl -fsS \
  -X POST \
  http://127.0.0.1:8080/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{
        "title":"Lecture 21 Manual Demo",
        "description":"Manual three-tier deployment verified",
        "priority":"HIGH",
        "status":"TODO",
        "assignee":"Student"
      }'

echo

echo ""
echo "=== TASK STATISTICS ==="
curl -fsS http://127.0.0.1:8080/api/tasks/stats
echo

echo ""
echo "=== MANUAL DEPLOYMENT ==="
echo "Frontend : http://localhost:5173"
echo "Backend  : http://localhost:8080"
echo "Swagger  : http://localhost:8080/docs"

echo ""
echo "MANUAL DEPLOYMENT VERIFIED"
```

**Screenshot:**
> ![alt text](screenshots/image.png)

---

## Task 2.2 — Manual Application UI

Opened:

```text
http://localhost:5173
```

The TaskBoard dashboard loaded and the task created by the previous command appeared.

**Screenshot:**

> ![alt text](screenshots/image-1.png)

---

# Task 3 — Stop Manual Frontend and Backend

After confirming the previous commands :

```bash
echo "=== STOP MANUAL APPLICATION ==="

if [ -f /tmp/l21-backend.pid ]; then
  kill "$(cat /tmp/l21-backend.pid)" 2>/dev/null || true
fi

if [ -f /tmp/l21-frontend.pid ]; then
  kill "$(cat /tmp/l21-frontend.pid)" 2>/dev/null || true
fi

rm -f \
  /tmp/l21-backend.pid \
  /tmp/l21-frontend.pid

echo "Manual frontend and backend stopped"
```

---

# Task 4 — Docker Images

The project already contains separate Dockerfiles for the backend and frontend.

The backend Dockerfile uses Python 3.12 and starts FastAPI after running Alembic migrations. 

The frontend uses a multi-stage Node build followed by an Nginx runtime image. 

Ran:

```bash
set -e

echo "=== BUILD BACKEND IMAGE ==="

docker build \
  -q \
  -t l21-taskboard-backend:local \
  ./backend

echo "Backend image built successfully"

echo ""
echo "=== BUILD FRONTEND IMAGE ==="

docker build \
  -q \
  -t l21-taskboard-frontend:local \
  ./frontend

echo "Frontend image built successfully"

echo ""
echo "=== DOCKER IMAGES ==="

docker image ls \
  --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' |
grep -E 'REPOSITORY|l21-taskboard'

echo ""
echo "DOCKER IMAGE BUILD VERIFIED"
```

**Screenshot:**
> ![alt text](screenshots/image-2.png) 

---

# Task 5 — Docker Compose Deployment

The provided Compose stack contains three services:

```text
postgres
backend
frontend
```

and uses a named volume for persistent PostgreSQL data. 

The frontend's Nginx configuration proxies `/api` traffic to the backend container on port 8000. 

## Task 5.1 — Start Complete Stack

The following block also handles the PostgreSQL/backend startup race automatically.

```bash
set -e

echo "=== STOP LOCAL POSTGRES PORT CONFLICT ==="

sudo systemctl stop postgresql 2>/dev/null || true

echo ""
echo "=== CLEAN OLD COMPOSE STACK ==="

docker compose down \
  -v \
  --remove-orphans \
  >/dev/null 2>&1 || true

echo ""
echo '$ docker compose up -d --build'

docker compose up \
  -d \
  --build \
  >/tmp/l21-compose-up.log 2>&1

echo "Docker Compose build completed"

echo ""
echo "=== WAITING FOR COMPLETE APPLICATION ==="

SUCCESS=0

for i in {1..50}; do

  if curl -fsS \
       http://127.0.0.1:8000/ready \
       >/dev/null 2>&1 &&
     curl -fsS \
       http://127.0.0.1:3000 \
       >/dev/null 2>&1; then

    SUCCESS=1
    break
  fi

  # If backend started before PostgreSQL was ready,
  # this automatically retries the affected services.
  docker compose up \
    -d \
    backend \
    frontend \
    >/dev/null 2>&1 || true

  sleep 3
done

if [ "$SUCCESS" -ne 1 ]; then
  echo "Compose stack did not become ready"

  docker compose ps

  echo ""
  echo "=== BACKEND LOGS ==="

  docker compose logs \
    --tail=30 \
    backend

  exit 1
fi

echo ""
echo "=== DOCKER COMPOSE PS ==="

docker compose ps

echo ""
echo "=== BACKEND HEALTH ==="

curl -fsS http://127.0.0.1:8000/health
echo

echo ""
echo "=== BACKEND READY ==="

curl -fsS http://127.0.0.1:8000/ready
echo

echo ""
echo "=== CREATE COMPOSE TEST TASK ==="

curl -fsS \
  -X POST \
  http://127.0.0.1:8000/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{
        "title":"Lecture 21 Docker Compose Demo",
        "description":"Frontend backend and PostgreSQL are working together",
        "priority":"HIGH",
        "status":"TODO",
        "assignee":"Student"
      }'

echo

echo ""
echo "=== TASK STATISTICS ==="

curl -fsS \
  http://127.0.0.1:8000/api/tasks/stats

echo

echo ""
echo "=== APPLICATION URLS ==="

echo "Frontend : http://localhost:3000"
echo "Swagger  : http://localhost:8000/docs"
echo "Health   : http://localhost:8000/health"
echo "Metrics  : http://localhost:8000/metrics"

echo ""
echo "DOCKER COMPOSE DEPLOYMENT VERIFIED"
```

**Screenshot:** 
> ![alt text](screenshots/image-3.png)

---

# Task 6 — Frontend UI

Opened:

```text
http://localhost:3000
```

The TaskBoard UI loaded and displayed the task created through the backend.

**Screenshot:**

> ![alt text](screenshots/image-4.png)

---

# Task 7 — Swagger API Documentation

Opened:

```text
http://localhost:8000/docs
```

Swagger displayed the TaskBoard backend API operations.

These included:

```text
GET    /api/tasks
GET    /api/tasks/{id}
POST   /api/tasks
PUT    /api/tasks/{id}
DELETE /api/tasks/{id}
GET    /api/tasks/stats
```

**Screenshot:**

> ![alt text](screenshots/image-5.png)

---

# Task 8 — Backend Health Endpoint

Opened:

```text
http://localhost:8000/health
```

**Screenshot:**

> ![alt text](screenshots/image-6.png)

---

# Task 9 — Backend Metrics Endpoint

Opened:

```text
http://localhost:8000/metrics
```

The endpoint displayed Prometheus-formatted application metrics.

**Screenshot:**

> ![alt text](screenshots/image-7.png)

---

# Application Verification

The completed Docker Compose deployment verifies:

```text
Frontend
   ✓

Backend
   ✓

PostgreSQL
   ✓

REST API
   ✓

Health endpoint
   ✓

Metrics endpoint
   ✓

Persistent database volume
   ✓
```

---

# Manual Deployment vs Docker Compose

| Manual Deployment | Docker Compose |
|---|---|
| Services started separately | Complete stack starts together |
| Local Python environment | Backend container |
| Local Node/Vite server | Frontend Nginx container |
| Local PostgreSQL | PostgreSQL container |
| Frontend port 5173 | Frontend port 3000 |
| Backend port 8080 | Backend port 8000 |

Docker Compose makes the application easier to reproduce because all three services are described and started together.

---

# What I Practiced

- Running PostgreSQL manually
- Running FastAPI manually
- Running React/Vite manually
- Backend database connectivity
- Docker image building
- Frontend Dockerfile
- Backend Dockerfile
- Docker Compose
- Container networking
- PostgreSQL persistent volume
- FastAPI Swagger
- REST API verification
- Application health checks
- Prometheus metrics endpoint

---

# Result

The TaskBoard application was successfully deployed manually and through Docker Compose.

The complete Docker deployment contained:

```text
React Frontend
      ↓
FastAPI Backend
      ↓
PostgreSQL Database
```

The frontend successfully communicated with the backend and database, and the backend's Swagger documentation, health endpoint and metrics endpoint were verified.

---

# Cleanup After Lecture 21

```bash
echo "=== STOP MANUAL PROCESSES ==="

if [ -f /tmp/l21-backend.pid ]; then
  kill "$(cat /tmp/l21-backend.pid)" 2>/dev/null || true
fi

if [ -f /tmp/l21-frontend.pid ]; then
  kill "$(cat /tmp/l21-frontend.pid)" 2>/dev/null || true
fi

rm -f \
  /tmp/l21-backend.pid \
  /tmp/l21-frontend.pid

echo ""
echo "=== REMOVE DOCKER COMPOSE STACK ==="

docker compose down \
  -v \
  --remove-orphans

echo ""
echo "=== REMOVE LECTURE 21 LOCAL IMAGES ==="

docker image rm \
  l21-taskboard-backend:local \
  l21-taskboard-frontend:local \
  2>/dev/null || true

echo ""
echo "=== REMOVE TEMPORARY PYTHON ENVIRONMENT ==="

rm -rf /tmp/l21-venv

echo ""
echo "=== RESTORE LOCAL POSTGRESQL ==="

sudo systemctl start postgresql \
  2>/dev/null || true

echo ""
echo "=== VERIFY COMPOSE CLEANUP ==="

docker compose ps

echo ""
echo "LECTURE 21 CLEANUP COMPLETE"
```