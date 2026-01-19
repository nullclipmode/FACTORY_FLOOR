# Factory Floor - Disaster Recovery Guide

**If your computer dies, follow this guide to get back up and running.**

---

## Quick Recovery (30 minutes)

### Step 1: Install Prerequisites

```bash
# Homebrew (macOS package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Essential tools
brew install git node python3 jq

# Google Cloud CLI
brew install google-cloud-sdk

# GitHub CLI
brew install gh

# Terraform
brew install terraform

# Vercel CLI
npm install -g vercel

# Supabase CLI
brew install supabase/tap/supabase
```

### Step 2: Authenticate Everything

```bash
# GitHub
gh auth login

# Google Cloud
gcloud auth login
gcloud auth application-default login
gcloud config set project core-infra-484804

# Vercel
vercel login

# Supabase
supabase login
```

### Step 3: Clone Factory Floor

```bash
cd ~/Documents
mkdir -p ____CLAUDE_PROJECTS/_FACTORY_FLOOR
cd ____CLAUDE_PROJECTS/_FACTORY_FLOOR
git clone https://github.com/nullclipmode/FACTORY_FLOOR.git
cd FACTORY_FLOOR
```

### Step 4: Install Beads

```bash
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

### Step 5: Restore Claude Code Config

```bash
# Create .claude directory
mkdir -p ~/.claude/{commands,agents,skills,scripts,plugins}

# Copy from backup
cp -r system-backup/commands/* ~/.claude/commands/
cp -r system-backup/agents/* ~/.claude/agents/
cp -r system-backup/skills/* ~/.claude/skills/
cp -r system-backup/scripts/* ~/.claude/scripts/
cp -r system-backup/ralph/* ~/.claude/
cp system-backup/settings.json ~/.claude/
cp system-backup/CLAUDE.md ~/.claude/

# Make scripts executable
chmod +x ~/.claude/scripts/*.sh
chmod +x ~/.claude/ralph-loop.sh
```

### Step 6: Install Claude Code

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

### Step 7: Verify Everything Works

```bash
# Check beads
bd ready

# Check Claude commands
ls ~/.claude/commands/

# Check GCP access
gcloud projects describe core-infra-484804
```

---

## What's Stored Where

| Data | Location | Backed Up To |
|------|----------|--------------|
| **Claude commands** | `~/.claude/commands/` | `system-backup/commands/` |
| **Claude agents** | `~/.claude/agents/` | `system-backup/agents/` |
| **Claude skills** | `~/.claude/skills/` | `system-backup/skills/` |
| **Claude scripts** | `~/.claude/scripts/` | `system-backup/scripts/` |
| **Ralph loop files** | `~/.claude/ralph-*.md` | `system-backup/ralph/` |
| **Settings** | `~/.claude/settings.json` | `system-backup/settings.json` |
| **Global instructions** | `~/.claude/CLAUDE.md` | `system-backup/CLAUDE.md` |
| **Beads CLI** | `~/.local/bin/bd` | Reinstall from script |
| **Project beads** | `.beads/` | In each git repo |
| **Infrastructure** | GCP | `infra/` Terraform files |

---

## What's NOT in Git (Secrets)

These need to be re-added manually:

| Secret | How to Get It |
|--------|---------------|
| **Anthropic API key** | https://console.anthropic.com |
| **GCP credentials** | `gcloud auth login` |
| **GitHub token** | `gh auth login` |
| **Vercel token** | `vercel login` |
| **Supabase credentials** | `supabase login` |
| **Sentry DSN** | https://sentry.io |
| **Mixpanel token** | https://mixpanel.com |

---

## Infrastructure Recovery

The GCP infrastructure is already deployed. If you need to redeploy:

```bash
cd infra/global
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with: gcp_project_id = "core-infra-484804"

terraform init
terraform plan  # Review changes
terraform apply
```

### Current Live Infrastructure

| Resource | Value |
|----------|-------|
| GCP Project | `core-infra-484804` |
| Load Balancer IP | `34.8.93.231` |
| Domain | `nullclipmode.xyz` |
| SSL Cert | `factory-floor-cert` |

---

## Per-App Recovery

Each app you build has its own:
- GitHub repo
- Vercel project
- Supabase project
- `.beads/` directory

To recover an app:

```bash
# Clone the app repo
git clone https://github.com/YOU/app-name
cd app-name

# Beads auto-recovers from .beads/issues.jsonl
bd ready

# Restore Vercel link
vercel link

# Supabase is cloud-hosted, just reconnect
supabase link --project-ref YOUR_PROJECT_REF
```

---

## Backup Checklist

Run this periodically to ensure backups are current:

```bash
# From Factory Floor directory
cd /Users/kitfieldgrass/Documents/____CLAUDE_PROJECTS/_FACTORY_FLOOR/FACTORY_FLOOR

# Copy latest Claude config to backup
cp -r ~/.claude/commands/* system-backup/commands/
cp -r ~/.claude/agents/* system-backup/agents/
cp -r ~/.claude/skills/* system-backup/skills/
cp -r ~/.claude/scripts/* system-backup/scripts/
cp ~/.claude/ralph-*.md system-backup/ralph/
cp ~/.claude/settings.json system-backup/
cp ~/.claude/CLAUDE.md system-backup/

# Commit
git add -A
git commit -m "chore: Backup Claude config"
git push
```

---

## Verification Script

Save this as `verify-setup.sh` and run after recovery:

```bash
#!/bin/bash
echo "=== Factory Floor Setup Verification ==="

echo -n "Git: "
git --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "Node: "
node --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "Python: "
python3 --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "gcloud: "
gcloud --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "gh: "
gh --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "terraform: "
terraform --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "vercel: "
vercel --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "supabase: "
supabase --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "beads (bd): "
~/.local/bin/bd version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo -n "claude: "
claude --version > /dev/null 2>&1 && echo "✓" || echo "✗ MISSING"

echo ""
echo "=== Claude Config ==="
echo -n "Commands: "
ls ~/.claude/commands/*.md > /dev/null 2>&1 && echo "✓ $(ls ~/.claude/commands/*.md | wc -l | tr -d ' ') files" || echo "✗ MISSING"

echo -n "Agents: "
ls ~/.claude/agents/*.md > /dev/null 2>&1 && echo "✓ $(ls ~/.claude/agents/*.md | wc -l | tr -d ' ') files" || echo "✗ MISSING"

echo -n "Scripts: "
ls ~/.claude/scripts/*.sh > /dev/null 2>&1 && echo "✓ $(ls ~/.claude/scripts/*.sh | wc -l | tr -d ' ') files" || echo "✗ MISSING"

echo -n "Settings: "
[ -f ~/.claude/settings.json ] && echo "✓" || echo "✗ MISSING"

echo ""
echo "=== Done ==="
```

---

## Emergency Contacts / Links

- **GitHub Repo**: https://github.com/nullclipmode/FACTORY_FLOOR
- **GCP Console**: https://console.cloud.google.com/home/dashboard?project=core-infra-484804
- **Vercel Dashboard**: https://vercel.com/dashboard
- **Supabase Dashboard**: https://app.supabase.com
- **Beads Docs**: https://github.com/steveyegge/beads
- **Claude Code Docs**: https://docs.anthropic.com/claude-code
