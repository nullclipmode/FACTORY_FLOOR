---
description: Deploy app to production with all checks
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Production Deployment

## Pre-Deployment Checks (Automatic)

Run all checks before deploying:
- All tests passing
- Build succeeds
- Security scan clean
- No console.log/print statements
- Environment variables configured
- Legal pages in place (privacy, terms)

If any check fails, fix it before proceeding.

## Setup Services (First Deploy Only)

### Sentry (Error Monitoring)

```bash
# Install Sentry CLI
npm install -g @sentry/cli

# Login (one-time)
sentry-cli login

# Create project for this app
sentry-cli projects create ${APP_NAME} --org YOUR_ORG

# Get DSN and add to environment
# Vercel: vercel env add SENTRY_DSN production
# Cloud Run: add to Secret Manager
```

**Add to app code:**

Next.js:
```bash
npx @sentry/wizard@latest -i nextjs
```

React:
```bash
npm install @sentry/react
```

Python:
```bash
pip install sentry-sdk
```

### Mixpanel (Analytics)

```bash
# Get token from mixpanel.com/settings
# Add MIXPANEL_TOKEN to environment variables
```

## Deploy

### Web (Vercel + Cloud Run):

1. **Vercel (Frontend)**
   ```bash
   vercel --prod
   ```

2. **Cloud Run (Backend)** - if applicable
   ```bash
   gcloud run deploy ${APP_NAME} \
     --source . \
     --region us-central1 \
     --project core-infra-484804 \
     --service-account factory-floor-run@core-infra-484804.iam.gserviceaccount.com
   ```

3. **Add to Load Balancer URL map** - if new backend
   ```bash
   gcloud compute url-maps add-path-matcher factory-floor-urlmap \
     --path-matcher-name=${APP_NAME}-matcher \
     --default-service=ff-${APP_NAME}-backend \
     --path-rules="/${APP_NAME}/*=ff-${APP_NAME}-backend"
   ```

4. **Wire Sentry DSN**
   ```bash
   # Vercel
   vercel env add SENTRY_DSN production

   # Cloud Run (via Secret Manager)
   echo -n "YOUR_DSN" | gcloud secrets versions add ${APP_NAME}-sentry-dsn --data-file=-
   ```

5. **Verify**
   - Hit production URL
   - Trigger test error → check Sentry dashboard
   - Check analytics → Mixpanel dashboard

### iOS (App Store):
1. Increment version number
2. Build release version
3. Upload to App Store Connect
4. Submit for review
5. Report expected review timeline (24-48 hours typical)

### Android (Play Store):
1. Increment version number
2. Build release AAB
3. Upload to Play Console
4. Submit for review
5. Report expected review timeline (few hours to 3 days)

## Post-Deploy Verification

```bash
# Check Sentry is receiving events
sentry-cli releases list --org YOUR_ORG

# Trigger a test error in production
curl https://your-app.com/api/sentry-test

# Verify in Sentry dashboard
```

## Report

Respond with:
- ✅ Deployed: [what and where]
- 🔗 Links: [production URLs]
- 📊 Monitoring:
  - Sentry: [project URL]
  - Mixpanel: [dashboard URL]
- ➡️ Post-launch: [next steps]
