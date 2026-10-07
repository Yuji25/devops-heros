# Lecture 16 Graded Homework

## Short Description

This project demonstrates a complete CI/CD workflow using GitHub Actions.

The pipeline performs:

```text
Git Push
   ↓
GitHub Actions
   ↓
Tests
   ↓
Security Check
   ↓
Build
   ↓
Build Artifact
   ↓
Docker Image
   ↓
Delivery Artifact
```

The application used is a simple Python calculator with automated pytest tests.

---

# CI vs CD

**Continuous Integration (CI)** automatically checks new code by running tests, security checks and builds whenever code is pushed.

**Continuous Delivery (CD)** prepares a tested application so that it is ready to be deployed. In this project, the tested application is packaged as a Docker image artifact.

---

# Project Setup

Run this block from:

```text
session-16-github-actions/session-16-github-actions
```

```bash id="j0g62c"
echo "=== CREATING LECTURE 16 PROJECT ==="

rm -rf graded-homework/cicd-demo
cp -r 10-final-cicd-pipeline graded-homework/cicd-demo

# Remove nested example workflow because GitHub Actions needs the
# workflow at the repository-level .github/workflows directory.
rm -rf graded-homework/cicd-demo/.github

cat > graded-homework/cicd-demo/Dockerfile <<'EOF'
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

CMD ["python", "app/calculator.py"]
EOF

mkdir -p ../../.github/workflows

cat > ../../.github/workflows/l16-cicd.yml <<'EOF'
name: Lecture 16 CI/CD Pipeline

on:
  push:
    branches:
      - L16_GitAct
    paths:
      - "session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo/**"
      - ".github/workflows/l16-cicd.yml"
  workflow_dispatch:

permissions:
  contents: read

jobs:
  test:
    name: Test Application
    runs-on: ubuntu-latest

    steps:
      - name: Checkout source code
        uses: actions/checkout@v6

      - name: Setup Python
        uses: actions/setup-python@v7
        with:
          python-version: "3.12"

      - name: Install dependencies
        working-directory: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run tests
        working-directory: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo
        run: pytest -v

  security-check:
    name: Security Check
    needs: test
    runs-on: ubuntu-latest

    steps:
      - name: Checkout source code
        uses: actions/checkout@v6

      - name: Verify GitHub Actions secret
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          test -n "$GH_TOKEN"
          echo "GITHUB_TOKEN is available securely."

      - name: Check for sensitive files
        working-directory: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo
        run: |
          if find . -type f \( -name ".env" -o -name "*.pem" -o -name "*.key" \) | grep -q .; then
            echo "Sensitive file found."
            exit 1
          fi
          echo "No common sensitive files found."

  build:
    name: Build Application
    needs: test
    runs-on: ubuntu-latest

    steps:
      - name: Checkout source code
        uses: actions/checkout@v6

      - name: Build application
        working-directory: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo
        run: |
          chmod +x build.sh
          ./build.sh

      - name: Show build output
        working-directory: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo
        run: cat build/build-info.txt

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: calculator-build
          path: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo/build/

  delivery:
    name: CD - Package Docker Image
    needs:
      - build
      - security-check
    runs-on: ubuntu-latest

    steps:
      - name: Checkout source code
        uses: actions/checkout@v6

      - name: Build Docker image
        working-directory: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo
        run: |
          docker build -t l16-calculator:${GITHUB_SHA} .

      - name: Test Docker image
        run: |
          docker run --rm l16-calculator:${GITHUB_SHA} \
            python -c "from app.calculator import add, divide; assert add(10,5) == 15; assert divide(10,5) == 2; print('Docker smoke test passed')"

      - name: Package Docker image
        working-directory: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo
        run: |
          mkdir -p dist
          docker save l16-calculator:${GITHUB_SHA} | gzip > dist/l16-calculator-image.tar.gz
          ls -lh dist/

      - name: Upload Docker delivery artifact
        uses: actions/upload-artifact@v4
        with:
          name: calculator-docker-image
          path: session-16-github-actions/session-16-github-actions/graded-homework/cicd-demo/dist/l16-calculator-image.tar.gz
EOF

chmod +x graded-homework/cicd-demo/build.sh

echo ""
echo "=== PROJECT FILES ==="
find graded-homework/cicd-demo -maxdepth 2 -type f | sort

echo ""
echo "=== WORKFLOW FILE ==="
test -f ../../.github/workflows/l16-cicd.yml && \
  echo "GitHub Actions workflow created successfully"
```

---

# Application Source Code

The application contains basic calculator operations:

- Addition
- Subtraction
- Multiplication
- Division
- Division-by-zero handling

Automated tests verify all of these operations.

---

# Dockerfile

The Dockerfile:

- Uses Python 3.12
- Installs application dependencies
- Copies the calculator application
- Runs the Python calculator

The Docker image is also tested inside the CD stage before being packaged.

---

# GitHub Actions Concepts

### Workflow

The workflow is stored at:

```text
.github/workflows/l16-cicd.yml
```

It runs automatically when relevant files are pushed to the `L16_GitAct` branch. It can also be started manually using `workflow_dispatch`.

### Jobs

The workflow contains four jobs:

```text
1. Test Application
2. Security Check
3. Build Application
4. CD - Package Docker Image
```

### Steps

Each job consists of smaller steps such as:

```text
Checkout code
Setup Python
Install dependencies
Run tests
Build application
Upload artifact
Build Docker image
Test Docker image
Package Docker image
```

### Runner

All jobs run using:

```text
ubuntu-latest
```

The runners are temporary machines provided by GitHub Actions.

### Secrets

The pipeline uses:

```text
secrets.GITHUB_TOKEN
```

GitHub automatically provides this secret to workflows. Its actual value is never printed in the pipeline.

### Artifacts

Two artifacts are generated:

```text
calculator-build
calculator-docker-image
```

The first contains the normal application build and the second contains the packaged Docker image.

---

# Local Verification

Before pushing to GitHub, run:

```bash id="t9my8n"
echo "=== LOCAL TEST USING DOCKER ==="

docker build \
  -t l16-calculator:local \
  graded-homework/cicd-demo

echo ""
echo "=== CALCULATOR SMOKE TEST ==="

docker run --rm l16-calculator:local \
  python -c "from app.calculator import add, subtract, multiply, divide; assert add(10,5)==15; assert subtract(10,5)==5; assert multiply(10,5)==50; assert divide(10,5)==2; print('All calculator checks passed')"

echo ""
echo "=== DOCKER IMAGE ==="
docker images l16-calculator:local
```

**Screenshot:**
> ![alt text](image.png)
> ![alt text](image-1.png)

---

# Pipeline Execution

Pushed the completed project and workflow:

```bash id="vugm4k"
echo "=== CURRENT BRANCH ==="
git branch --show-current

echo "=== ADDING LECTURE 16 FILES ==="
git add graded-homework/cicd-demo
git add graded-homework/README.md
git add ../../.github/workflows/l16-cicd.yml

git status --short

echo "=== COMMITTING ==="
git commit -m "Complete Lecture 16 GitHub Actions homework"

echo "=== PUSHING ==="
git push origin L16_GitAct

echo "=== PUSH COMPLETE ==="
git log -1 --oneline
```

---

# GitHub Actions Pipeline Result

### GitHub Screenshot 1 — Workflow Run

This screenshot is **not from the terminal**.

After pushing:

1. Open the repository on GitHub.
2. Open the **Actions** tab.
3. Select **Lecture 16 CI/CD Pipeline**.
4. Open the latest run.
5. Wait until the complete workflow becomes green.

The successful pipeline should show:

```text
✓ Test Application
✓ Security Check
✓ Build Application
✓ CD - Package Docker Image
```

**Screenshot:** Take a screenshot of this complete GitHub Actions run with all four jobs green.

> ![Successful CI CD Pipeline](screenshots/github-actions-success.png)

---

# CI Pipeline

The CI part of the workflow performs:

```text
Source Code
   ↓
Automated Tests
   ↓
Security Check
   ↓
Application Build
   ↓
Build Artifact
```

Tests run first. The Build and Security jobs only continue after testing succeeds.

---

# CD Pipeline

The CD stage starts only after the CI jobs succeed.

```text
Successful CI
   ↓
Build Docker Image
   ↓
Test Docker Image
   ↓
Package Docker Image
   ↓
Upload Delivery Artifact
```

The resulting Docker image artifact is ready to be downloaded and deployed to a target environment.

---

# Build Artifact

### GitHub Screenshot 2 — Artifacts

This screenshot is also **from GitHub, not the terminal**.

On the successful workflow run page, scroll to the **Artifacts** section.

It should contain:

```text
calculator-build
calculator-docker-image
```

**Screenshot:** Take a screenshot showing both artifacts.

> ![GitHub Actions Artifacts](screenshots/github-actions-artifacts.png)

---

# Pipeline Job Details

### GitHub Screenshot 3 — CD Job

Open:

```text
Actions
→ Lecture 16 CI/CD Pipeline
→ latest successful run
→ CD - Package Docker Image
```

The job should show successful steps for:

```text
Build Docker image
Test Docker image
Package Docker image
Upload Docker delivery artifact
```

**Screenshot:** Take one screenshot showing these steps with green check marks.

> ![CD Job](screenshots/github-actions-cd-job.png)

---

# Pipeline Execution Result

The complete pipeline successfully:

- Checked out the source code
- Installed dependencies
- Ran automated tests
- Checked for sensitive files
- Used a GitHub Actions secret securely
- Built the application
- Uploaded the build artifact
- Built a Docker image
- Tested the Docker image
- Packaged the Docker image
- Uploaded the image as a delivery artifact

This demonstrates both CI and CD using GitHub Actions.

---

# Project Structure

```text
graded-homework/
├── README.md
└── cicd-demo/
    ├── app/
    │   ├── __init__.py
    │   └── calculator.py
    ├── tests/
    │   └── test_calculator.py
    ├── Dockerfile
    ├── build.sh
    ├── requirements.txt
    └── README.md

Repository Root/
└── .github/
    └── workflows/
        └── l16-cicd.yml
```

---

# Conclusion

In this lecture I practiced:

- CI vs CD
- GitHub Actions
- Workflows
- Jobs and steps
- GitHub-hosted runners
- Secrets
- Automated tests
- Application builds
- Docker builds
- Artifacts
- CI pipeline execution
- CD pipeline execution

The pipeline runs automatically after a push and produces tested application and Docker artifacts ready for delivery.

---

# Cleanup After Lecture 16

There are **no Kubernetes resources to clean for this lecture**.

Only remove the local Docker image after taking your terminal screenshot:

```bash id="g2m9be"
echo "=== CLEANING LOCAL LECTURE 16 IMAGE ==="

docker image rm l16-calculator:local 2>/dev/null || true

echo ""
echo "=== CLEANUP COMPLETE ==="
docker images l16-calculator:local
```

The final `docker images` output should simply show no `l16-calculator:local` image.