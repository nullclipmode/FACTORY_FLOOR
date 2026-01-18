---
description: Deploy app to production with all checks
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Production Deployment

## Pre-Deployment (Automatic)

Run all checks before deploying:
- All tests passing
- Security scan clean
- No console.log/print statements
- Environment variables configured
- Legal pages in place (privacy, terms)
- Analytics configured
- Error monitoring configured

If any check fails, fix it before proceeding.

## Deploy

### Web (Vercel):
1. Merge to main branch
2. Trigger production deployment
3. Verify deployment successful
4. Run smoke tests on production URL

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

## Report

Respond with:
- ✅ Deployed: [what and where]
- 🔗 Links: [production URLs]
- 📊 Status: [any pending reviews]
- ➡️ Post-launch: [monitoring, next steps]
