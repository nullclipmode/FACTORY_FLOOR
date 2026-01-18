---
description: Add Python backend to existing project - ML, data processing, automation
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Add Python Component

Add Python capabilities to an existing project.

## Phase 1: Understand Requirements

Ask about:
1. What does this need to do? (ML, data processing, automation, file processing, API)
2. How is it triggered? (user action, webhook, schedule, background)
3. Performance needs? (real-time, fast, background, batch)
4. Expected load? (light, medium, heavy)
5. Specific libraries needed?

## Phase 2: Choose Architecture

Option A: Vercel Python Functions
- Best for processing under 10 seconds, stateless, light dependencies
- Limitations: 10s timeout, 250MB size

Option B: FastAPI on Railway
- Best for longer processing, ML models, complex dependencies
- Deploy to Railway, Render, or Fly.io

Option C: Background Workers (Celery/Redis)
- Best for long jobs, scheduled tasks, queues, retries

Confirm approach before proceeding.

## Phase 3: Implementation

Based on chosen option, create:
- Directory structure
- Core files (requirements.txt, Dockerfile)
- Feature implementation
- Frontend API client
- Update CLAUDE.md
- Update CI/CD

## Phase 4: Deployment

Railway: railway init and railway up
Vercel: Auto-deploys api folder
Connect frontend with environment variables

## Phase 5: Report

Completed items, endpoints, integration location, deployment URL, testing commands, next steps.
