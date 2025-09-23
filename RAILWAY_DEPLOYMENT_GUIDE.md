# Railway Deployment Safeguards

## 🚨 CRITICAL: Prevent Wrong Branch Deployment

### What Happened:
Railway was deploying from `working-iphone-x-version` branch instead of `main`, causing old data to be served despite updates to main branch.

### Required Railway Settings:
1. **Go to Railway Dashboard** → Project → Backend Service
2. **Settings → Source**
3. **VERIFY these settings:**
   - Repository: `mnavar-evidence/skillvergence-ev-coach`
   - Branch: **`main`** (MUST be main!)
   - Auto-deploy: ON
   - Root Directory: `ev-transition-coach-backend` (if using subdirectory)

### Before Any Deployment:
- [ ] Confirm Railway source branch is `main`
- [ ] Verify no stale branches exist in repository
- [ ] Test API response after deployment: `curl -s "https://api.mindsherpa.ai/api/courses" | jq '.courses[0].videos[0].muxPlaybackId'`

### Red Flags:
- ❌ Railway shows different branch than `main`
- ❌ API returns data that doesn't match main branch
- ❌ Deployment succeeds but content doesn't update
- ❌ Multiple branches exist in repository

### Emergency Fix:
1. Delete all branches except `main`: `git push origin --delete <branch-name>`
2. Force Railway redeploy from main
3. Verify API response matches code in main branch

## Current Correct MUX Playback IDs:
- Course 1.1: `Tkk1BFdFi1hlKZSMqosuhoNExgghDyqv5rBMup02bSes`
- Course 1.2: `zTOywHrdACjLFt35Qv802wk8BN8m8gV7C01flvbPQrOCw`
- Course 1.3: `ng2Lphh1xBIphzI2CQ5M7g1Qbg34ZhbP3Cqqn49srug`

## Test Command:
```bash
curl -s "https://api.mindsherpa.ai/api/courses" | jq '.courses[0].videos[0].muxPlaybackId'
# Should return: "Tkk1BFdFi1hlKZSMqosuhoNExgghDyqv5rBMup02bSes"
```