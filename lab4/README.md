# Lab 4 - Docker Image Optimization

## 1. Docker Image Comparison

| Image | Base Image | Image Size | Rebuild Time |
|---|---|---|---|
| Naive | python:latest | 1.15 GB | 4.363 seconds |
| Slim | python:3.12-slim-bookworm | 130 MB | 0.581 seconds |

The optimized image reduced the image size by approximately 88.7%.
The code-only rebuild was approximately 7.5 times faster.

## 2. Analysis

- Base Image: Most of the size difference came from the base image. The naive image used python:latest, while the optimized image used python:3.12-slim-bookworm. The dependency layers were 17.8 MB and 6.38 MB, respectively.

- Dependency Caching: In the naive Dockerfile, COPY . . came before pip install, so changing app.py caused dependencies to be installed again. In the optimized Dockerfile, requirements.txt was copied and installed first, allowing the dependency layer to remain cached during code-only changes.

- Dockerignore: The .dockerignore file excluded .git, .github, Python cache files, pytest cache, evidence screenshots, Markdown files, and Dockerfile files. The build context decreased from 830 B to 472 B.

## 3. Security Improvements

The naive container ran as root, while the optimized container ran as appuser (UID 10001).

The optimized Dockerfile also used a pinned Python base image, an exec-form CMD, and EXPOSE 8000.

## 4. Evidence

- evidence/image-sizes.png: Screenshot comparing naive and optimized Docker image sizes.



## 5. CI Cache Performance Comparison

The GitHub Actions workflow was measured before enabling caching, during the initial cache population, and during two subsequent cache-hit runs.

| Measurement | Baseline | Cache Miss | Cache Hit #1 | Cache Hit #2 | Worth It? |
|---|---:|---:|---:|---:|---|
| pip install (Python 3.11) | 4s | 3s | 2s | 1s | Limited benefit |
| pip install (Python 3.12) | 2s | 4s | 1s | 3s | Limited benefit |
| Docker build | 10s | 13s | 5s | 5s | Yes |
| Whole workflow | 55s | 61s | 57s | 58s | Not yet |

### Pip Cache Analysis

The pip cache successfully restored dependencies for both Python 3.11 and Python 3.12, as confirmed by the "Cache restored from key" messages in the GitHub Actions logs.

However, pip installation was already fast, and the results varied between runs. The pip cache provides only a limited performance benefit for this small project.

### Docker Layer Cache Analysis

Docker Buildx successfully reused cached image layers, as confirmed by the "CACHED" messages in the build logs.

The Docker build step decreased from 10 seconds in the baseline to 5 seconds in both cache-hit runs. This suggests that Docker layer caching is useful, especially as the project grows.

The baseline used a regular docker build command, while the cached runs used docker/build-push-action, so the measured steps are not perfectly identical.

### Overall Workflow Analysis

The baseline workflow completed in 55 seconds, while the cache-hit workflows completed in 57 and 58 seconds.

Although individual build steps became faster, the overall workflow did not improve. Cache setup, upload/download operations, and other workflow overhead may offset the time saved in this small project.

Therefore, Docker layer caching is worth keeping for future development, while pip caching offers a smaller and less consistent benefit.

### GitHub Actions Measurement Evidence

- Baseline: https://github.com/lcz111/acs730-coursework/actions/runs/40040851696
- Cache Miss: https://github.com/lcz111/acs730-coursework/actions/runs/40043339884
- Cache Hit #1: https://github.com/lcz111/acs730-coursework/actions/runs/40043594945
- Cache Hit #2: https://github.com/lcz111/acs730-coursework/actions/runs/40044231487

All measurements were calculated from GitHub Actions job and step timestamps.


## Part 10 — Composite Action and Reusable Workflow

I used a composite action for Python dependency setup because Python installation, pip caching, and dependency installation must run on the same runner as the tests.

I used a reusable workflow for Docker image building and publishing because it represents a complete job that requires its own runner and `packages: write` permission, which the test job does not need.

## Build and Run Instructions

Build the optimized image:

    docker build -t acs730-lab4:local lab4/

Run the container:

    docker run -d --name acs730-lab4-app -p 8000:8000 acs730-lab4:local

Check the health endpoint:

    curl http://localhost:8000/healthz

The application listens on port 8000. The `/healthz` endpoint is used by the CI smoke test.

Remove the container:

    docker rm -f acs730-lab4-app

## Why GHCR Uses SHA Tags

The workflow publishes Docker images to GitHub Container Registry (GHCR) using tags derived from the Git commit SHA rather than `latest`.

SHA-based tags identify the source commit, improve traceability, and make rollback easier. The `latest` tag can change over time and does not identify the exact source version.

## GitHub Actions vs AWS-Native CI/CD

GitHub Actions uses GitHub-hosted runners to execute tests, build Docker images, and publish images to GHCR. Publishing uses the temporary GITHUB_TOKEN with limited permissions.

An AWS-native alternative would use AWS CodePipeline to coordinate stages, AWS CodeBuild to execute tests and Docker builds, and Amazon ECR to store container images.

GitHub-hosted runners execute outside AWS and can use GITHUB_TOKEN for GHCR or OIDC-based temporary AWS credentials. CodeBuild uses AWS-managed build environments and normally authenticates to AWS services through an IAM service role.

AWS Academy restricts IAM write operations, making it difficult to create the service roles required for a complete AWS-native pipeline. Therefore, GitHub Actions and GHCR were more practical for this lab. With appropriate IAM permissions, CodePipeline, CodeBuild, and ECR would be a suitable alternative for AWS-hosted workloads.

## Experiments

### Experiment 1: Invert the Layer Order

**Prediction:** Moving `COPY app.py ./` before dependency installation would invalidate the pip installation layer after a code-only change, making subsequent rebuilds slower.

**Observation:** After modifying `app.py`, Docker reran `pip install` instead of using the cached layer; dependency installation took 3.8 seconds, compared with 4.9 seconds during the initial build.

**Explanation:** Because Docker cache depends on preceding layers, changing `app.py` invalidated all subsequent layers, including dependency installation. Keeping application code after the dependency layer avoids this unnecessary work.

### Experiment 2: Remove the .dockerignore

**Prediction:** Removing `.dockerignore` would allow more files into the build context, but I expected the optimized image size to remain nearly unchanged because its Dockerfile copies only specific files.

**Observation:** The rebuilt optimized image remained 130 MB, and `ls -a /app` showed only `app.py` and `requirements.txt`. BuildKit reported 181 B of transferred context during the no-cache build, so an increase in transferred context was not observed.

**Explanation:** Unlike the naive Dockerfile, which uses `COPY . .`, the optimized Dockerfile explicitly copies only the application and requirements files. Therefore, excluding unrelated files is less important for the final image size, although `.dockerignore` remains useful for reducing unnecessary build-context exposure.
