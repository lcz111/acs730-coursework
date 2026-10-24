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

