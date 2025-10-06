# List all recipes
default:
    @just --list

# Contents
## CI/CD
## Cloudflare
## Docs
## Nix
## Secrets
## Testing

## CI/CD

# Format code with Biome
[group('CI/CD')]
format:
  bun run format

# Lint code with Biome
[group('CI/CD')]
lint:
  bun run lint

# Check and fix code with Biome
[group('CI/CD')]
check:
  bun run check:fix

# Run pre-commit hooks
[group('CI/CD')]
pre-commit:
  pre-commit run --all-files

# Update github vars for repo from environment variables
[group('CI/CD')]
ghvars repo="":
  #!/usr/bin/env bash
  REPO="${repo:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  echo "vars before updates:"
  echo
  PAGER=cat gh variable list --repo="$REPO"
  echo
  sops exec-env vars/shared.yaml '\
  gh variable set CACHIX_CACHE_NAME --repo='"$REPO"' --body="$CACHIX_CACHE_NAME"'
  echo
  echo "vars after updates (wait 3 seconds for github to update):"
  sleep 3
  echo
  PAGER=cat gh variable list --repo="$REPO"

# Update github secrets for repo from sops-encrypted secrets
[group('CI/CD')]
ghsecrets repo="":
  #!/usr/bin/env bash
  REPO="${repo:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  echo "secrets before updates:"
  echo
  PAGER=cat gh secret list --repo="$REPO"
  echo
  sops exec-env vars/shared.yaml '\
  gh secret set CACHIX_AUTH_TOKEN --repo='"$REPO"' --body="$CACHIX_AUTH_TOKEN" && \
  gh secret set GITGUARDIAN_API_KEY --repo='"$REPO"' --body="$GITGUARDIAN_API_KEY" && \
  gh secret set CLOUDFLARE_ACCOUNT_ID --repo='"$REPO"' --body="$CLOUDFLARE_ACCOUNT_ID" && \
  gh secret set CLOUDFLARE_API_TOKEN --repo='"$REPO"' --body="$CLOUDFLARE_API_TOKEN" && \
  gh secret set SOPS_AGE_KEY --repo='"$REPO"' --body="$CI_AGE_KEY"'
  echo
  echo "secrets after updates (wait 3 seconds for github to update):"
  sleep 3
  echo
  PAGER=cat gh secret list --repo="$REPO"

# List available workflows and associated jobs using act
[group('CI/CD')]
list-workflows:
  @act -l

# Test build job locally with act
[group('CI/CD')]
test-build branch=`git branch --show-current`:
  @echo "Testing build job locally (branch: {{branch}})..."
  @sops exec-env vars/shared.yaml 'act pull_request \
    -W .github/workflows/ci.yaml \
    -j build \
    -s CI_AGE_KEY -s CACHIX_AUTH_TOKEN \
    -s GITHUB_TOKEN="$(gh auth token)" \
    --var CACHIX_CACHE_NAME \
    --input debug_enabled=false'

# Test deploy job locally with act
[group('CI/CD')]
test-deploy branch=`git branch --show-current`:
  @echo "Testing deploy job locally (branch: {{branch}})..."
  @echo "Note: Cloudflare deployment may not work in local environment"
  @sops exec-env vars/shared.yaml 'act push \
    -W .github/workflows/ci.yaml \
    -j deploy \
    -s CI_AGE_KEY -s CACHIX_AUTH_TOKEN \
    -s SOPS_AGE_KEY="$CI_AGE_KEY" \
    -s CLOUDFLARE_API_TOKEN -s CLOUDFLARE_ACCOUNT_ID \
    -s GITHUB_TOKEN="$(gh auth token)" \
    --var CACHIX_CACHE_NAME \
    --input debug_enabled=false'

# Trigger CI workflow remotely on GitHub
[group('CI/CD')]
gh-ci-run branch=`git branch --show-current` debug="false" deploy="false":
  #!/usr/bin/env bash
  echo "Triggering CI workflow on GitHub (branch: {{branch}}, debug: {{debug}}, deploy: {{deploy}})..."
  gh workflow run ci.yaml \
    --repo ${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)} \
    --ref "{{branch}}" \
    --field debug_enabled="{{debug}}" \
    --field deploy_enabled="{{deploy}}"
  echo "Check workflow status with: just gh-workflow-status"

# View recent workflow runs status
[group('CI/CD')]
gh-workflow-status workflow="ci.yaml" branch=`git branch --show-current` limit="5":
  #!/usr/bin/env bash
  echo "Recent CI workflow runs:"
  gh run list \
    --workflow={{workflow}} \
    --branch={{branch}} \
    --limit={{limit}} \
    --repo ${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}

# Watch a specific workflow run
[group('CI/CD')]
gh-watch run_id="":
  #!/usr/bin/env bash
  if [ -z "{{run_id}}" ]; then
    echo "Getting latest workflow run..."
    RUN_ID=$(gh run list --workflow=ci.yaml --limit=1 --json databaseId -q '.[0].databaseId' \
      --repo ${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)})
    echo "Watching run: $RUN_ID"
    gh run watch $RUN_ID --repo ${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}
  else
    gh run watch {{run_id}} --repo ${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}
  fi

# View logs for a specific workflow run
[group('CI/CD')]
gh-logs run_id="" job="":
  #!/usr/bin/env bash
  REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  if [ -z "{{run_id}}" ]; then
    echo "Getting latest workflow run..."
    RUN_ID=$(gh run list --workflow=ci.yaml --limit=1 --json databaseId -q '.[0].databaseId' --repo $REPO)
  else
    RUN_ID="{{run_id}}"
  fi

  if [ -z "{{job}}" ]; then
    echo "Available jobs in run $RUN_ID:"
    gh run view $RUN_ID --repo $REPO --json jobs -q '.jobs[].name'
    echo ""
    echo "Viewing full run logs..."
    gh run view $RUN_ID --log --repo $REPO
  else
    echo "Viewing logs for job '{{job}}' in run $RUN_ID..."
    gh run view $RUN_ID --log --repo $REPO | grep -A 100 "{{job}}"
  fi

# Re-run a failed workflow
[group('CI/CD')]
gh-rerun run_id="" failed_only="true":
  #!/usr/bin/env bash
  REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  if [ -z "{{run_id}}" ]; then
    echo "Getting latest workflow run..."
    RUN_ID=$(gh run list --workflow=ci.yaml --limit=1 --json databaseId -q '.[0].databaseId' --repo $REPO)
  else
    RUN_ID="{{run_id}}"
  fi

  if [ "{{failed_only}}" = "true" ]; then
    echo "Re-running failed jobs in run $RUN_ID..."
    gh run rerun --failed $RUN_ID --repo $REPO
  else
    echo "Re-running all jobs in run $RUN_ID..."
    gh run rerun $RUN_ID --repo $REPO
  fi

# Cancel a running workflow
[group('CI/CD')]
gh-cancel run_id="":
  #!/usr/bin/env bash
  REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  if [ -z "{{run_id}}" ]; then
    echo "Getting latest workflow run..."
    RUN_ID=$(gh run list --workflow=ci.yaml --limit=1 --json databaseId -q '.[0].databaseId' --repo $REPO)
    echo "Canceling run: $RUN_ID"
    gh run cancel $RUN_ID --repo $REPO
  else
    gh run cancel {{run_id}} --repo $REPO
  fi

## Cloudflare

# Preview the site locally with Cloudflare Workers
[group('cloudflare')]
cf-preview:
  bun run preview

# Deploy the site to Cloudflare Workers
[group('cloudflare')]
cf-deploy:
  bun run deploy

# Generate Cloudflare Worker types
[group('cloudflare')]
cf-types:
  bun run cf-typegen

## Docs

# Start development server
[group('docs')]
dev:
  bun run dev

# Build the documentation site
[group('docs')]
build:
  bun run build

# Preview the built site
[group('docs')]
preview:
  bun run preview

# Install dependencies
[group('docs')]
install:
  bun install

## Nix

# Enter the Nix development shell
[group('nix')]
nix-dev:
    nix develop

# Validate the Nix flake configuration
[group('nix')]
flake-check:
    nix flake check --impure

# Update all flake inputs to their latest versions
[group('nix')]
flake-update:
    nix flake update --impure

# Build the documentation package with Nix
[group('nix')]
nix-build:
    nix build .#docs

## Secrets

# Show existing secrets using sops
[group('secrets')]
show-secrets:
  @echo "=== Shared secrets (vars/shared.yaml) ==="
  @sops -d vars/shared.yaml
  @echo

# Edit shared secrets file
[group('secrets')]
edit-secrets:
  @sops vars/shared.yaml

# Create a new sops encrypted file
[group('secrets')]
new-secret file:
  @sops {{ file }}

# Export secrets to dotenv format using sops
[group('secrets')]
export-secrets:
  @echo "# Exported from sops secrets" > .secrets.env
  @sops -d vars/shared.yaml | grep -E '^[A-Z_]+:' | sed 's/: /=/' >> .secrets.env
  @sort -u .secrets.env -o .secrets.env

# Run command with all shared secrets as environment variables
[group('secrets')]
run-with-secrets +command:
  @sops exec-env vars/shared.yaml '{{ command }}'

# Check secrets are available in sops environment
[group('secrets')]
check-secrets:
  @printf "Check sops environment for secrets\n\n"
  @sops exec-env vars/shared.yaml 'env | grep -E "GITHUB|CACHIX|CLOUDFLARE|GITGUARDIAN" | sed "s/=.*$/=***REDACTED***/"'

# Show specific secret value from shared secrets
[group('secrets')]
get-secret key:
  @sops -d vars/shared.yaml | grep "^{{ key }}:" | cut -d' ' -f2-

# Validate all sops encrypted files can be decrypted
[group('secrets')]
validate-secrets:
  @echo "Validating sops encrypted files..."
  @for file in $(find vars -name "*.yaml" -o -name "*.json"); do \
    echo "Testing: $file"; \
    sops -d "$file" > /dev/null && echo "  ✅ Valid" || echo "  ❌ Failed"; \
  done

# Initialize sops age key for new developers
[group('secrets')]
sops-init:
  @echo "Checking sops configuration..."
  @if [ ! -f ~/.config/sops/age/keys.txt ]; then \
    echo "Generating age key..."; \
    mkdir -p ~/.config/sops/age; \
    age-keygen -o ~/.config/sops/age/keys.txt; \
    echo ""; \
    echo "✅ Age key generated. Add this public key to .sops.yaml:"; \
    grep "public key:" ~/.config/sops/age/keys.txt; \
  else \
    echo "✅ Age key already exists"; \
    grep "public key:" ~/.config/sops/age/keys.txt; \
  fi

# Add existing age key to local configuration
[group('secrets')]
sops-add-key:
  #!/usr/bin/env bash
  set -euo pipefail

  # Ensure keys.txt exists and has proper permissions
  mkdir -p ~/.config/sops/age
  touch ~/.config/sops/age/keys.txt
  chmod 600 ~/.config/sops/age/keys.txt

  # Prompt for key description
  printf "Enter age key description (e.g., 'starlight-nix-template [dev|ci]'): "
  read -r key_description
  [[ -z "${key_description}" ]] && { echo "❌ Description cannot be empty"; exit 1; }

  # Prompt for public key
  printf "Enter age public key (age1...): "
  read -r public_key
  if [[ ! "${public_key}" =~ ^age1[a-z0-9]{58}$ ]]; then
    echo "❌ Invalid age public key format (must start with 'age1' and be 62 chars)"
    exit 1
  fi

  # Prompt for private key (hidden input)
  printf "Enter age private key (AGE-SECRET-KEY-...): "
  read -rs private_key
  echo  # New line after hidden input
  if [[ ! "${private_key}" =~ ^AGE-SECRET-KEY-[A-Z0-9]{59}$ ]]; then
    echo "❌ Invalid age private key format"
    exit 1
  fi

  # Check if key already exists
  if grep -q "${private_key}" ~/.config/sops/age/keys.txt 2>/dev/null; then
    echo "⚠️  This private key already exists in keys.txt"
    exit 1
  fi

  # Append to keys.txt with proper formatting
  {
    echo ""
    echo "# ${key_description}"
    echo "# public key: ${public_key}"
    echo "${private_key}"
  } >> ~/.config/sops/age/keys.txt

  echo "✅ Age key added successfully for: ${key_description}"
  echo "   Public key: ${public_key}"

# Add or update a secret non-interactively
[group('secrets')]
set-secret secret_name secret_value:
  @sops set vars/shared.yaml '["{{ secret_name }}"]' '"{{ secret_value }}"'
  @echo "✅ {{ secret_name }} has been set/updated"

# Rotate a specific secret interactively
[group('secrets')]
rotate-secret secret_name:
  @echo "Rotating {{ secret_name }}..."
  @echo "Enter new value for {{ secret_name }}:"
  @read -s NEW_VALUE && \
    sops set vars/shared.yaml '["{{ secret_name }}"]' "\"$NEW_VALUE\"" && \
    echo "✅ {{ secret_name }} rotated successfully"

# Update keys for existing secrets files after adding new recipients
[group('secrets')]
updatekeys:
  @for file in $(find vars -name "*.yaml" -o -name "*.json"); do \
    echo "Updating keys for: $file"; \
    sops updatekeys "$file"; \
  done
  @echo "✅ Keys updated for all secrets files"

# Bootstrap or rotate SOPS age keys (unified recipe for first-time and rotation)
[group('secrets')]
sops-bootstrap role='dev' method='age':
  #!/usr/bin/env bash
  set -euo pipefail

  ROLE="{{ role }}"  # 'dev' or 'ci'
  METHOD="{{ method }}"  # 'age' or 'ssh'

  echo "🔐 SOPS Key Bootstrap/Rotation"
  echo "   Role: $ROLE"
  echo "   Method: $METHOD"
  echo

  # Verify .sops.yaml exists
  if [ ! -f .sops.yaml ]; then
    echo "❌ .sops.yaml not found. Cannot proceed."
    exit 1
  fi

  # Check if this is rotation (key already exists) or bootstrap (placeholder)
  CURRENT_KEY=$(grep "^  - &${ROLE} " .sops.yaml | awk '{print $3}')

  if [ "$CURRENT_KEY" = "age1dn8w7y4t4h23fmeenr3dghfz5qh53jcjq9qfv26km3mnv8l44g0sghptu3" ] || \
     [ "$CURRENT_KEY" = "age1m9m8h5vqr7dqlmvnzcwshmm4uk8umcllazum6eaulkdp3qc88ugs22j3p8" ]; then
    IS_ROTATION=true
    echo "🔄 Detected existing key - this is a ROTATION"
  else
    IS_ROTATION=false
    echo "🆕 No existing key - this is BOOTSTRAP"
  fi

  # Generate new key
  if [ "$METHOD" = "ssh" ]; then
    echo "🔑 Generating SSH key pair..."
    KEY_FILE=$(mktemp)
    trap "rm -f $KEY_FILE ${KEY_FILE}.pub" EXIT

    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "${ROLE}@starlight-nix-template"
    PUBLIC_KEY=$(ssh-to-age < "${KEY_FILE}.pub")
    PRIVATE_KEY=$(cat "$KEY_FILE")
    PRIVATE_AGE_KEY=$(ssh-to-age -private-key -i "$KEY_FILE")

    echo "   SSH public key: $(cat ${KEY_FILE}.pub)"
    echo "   Age public key: $PUBLIC_KEY"
  else
    echo "🔑 Generating age key pair..."
    KEY_FILE=$(mktemp)
    trap "rm -f $KEY_FILE" EXIT

    age-keygen -o "$KEY_FILE" 2>&1 | tee /tmp/keygen-output.txt
    PUBLIC_KEY=$(grep "public key:" /tmp/keygen-output.txt | cut -d: -f2 | xargs)
    PRIVATE_KEY=$(cat "$KEY_FILE")
    rm -f /tmp/keygen-output.txt
  fi

  echo
  echo "📋 Generated key:"
  echo "   Public:  $PUBLIC_KEY"
  echo

  # Check if key already exists in .sops.yaml
  if grep -q "$PUBLIC_KEY" .sops.yaml; then
    echo "⚠️  This public key already exists in .sops.yaml"
    exit 1
  fi

  # Update .sops.yaml based on rotation or bootstrap
  cp .sops.yaml .sops.yaml.backup

  if [ "$IS_ROTATION" = true ]; then
    echo "📝 Adding new key as ${ROLE}-next for rotation..."

    # Add new key anchor after current key
    sed -i.tmp "/^  - &${ROLE} /a\\  - \&${ROLE}-next ${PUBLIC_KEY}" .sops.yaml

    # Add to creation_rules (both yaml and json)
    sed -i.tmp "/- \*${ROLE}$/a\\          - \*${ROLE}-next" .sops.yaml

    rm .sops.yaml.tmp
    echo "✅ Added ${ROLE}-next to .sops.yaml"
  else
    echo "📝 Replacing ${ROLE} key in .sops.yaml..."
    sed -i.tmp "s|^  - \&${ROLE} .*|  - \&${ROLE} ${PUBLIC_KEY}|" .sops.yaml
    rm .sops.yaml.tmp
    echo "✅ Updated ${ROLE} key in .sops.yaml"
  fi

  # Create or update encrypted files
  if [ ! -f vars/shared.yaml ]; then
    echo
    echo "📝 Creating vars/shared.yaml template..."
    mkdir -p vars
    cat > /tmp/shared-template.yaml << 'EOF'
CACHIX_AUTH_TOKEN: REPLACE_ME
CACHIX_CACHE_NAME: REPLACE_ME
GITGUARDIAN_API_KEY: REPLACE_ME
CLOUDFLARE_API_TOKEN: REPLACE_ME
CLOUDFLARE_ACCOUNT_ID: REPLACE_ME
CI_AGE_KEY: REPLACE_ME
EOF

    # For bootstrap, we can encrypt immediately
    if [ "$ROLE" = "dev" ]; then
      echo "$PRIVATE_KEY" > /tmp/bootstrap-key.txt
      SOPS_AGE_KEY_FILE=/tmp/bootstrap-key.txt sops -e /tmp/shared-template.yaml > vars/shared.yaml
      rm /tmp/bootstrap-key.txt
      echo "✅ Created vars/shared.yaml (edit with: just edit-secrets)"
    else
      echo "⚠️  Cannot encrypt without dev key. Create dev key first."
      echo "   Unencrypted template at: /tmp/shared-template.yaml"
      echo "   Run: just sops-bootstrap dev"
    fi
    rm -f /tmp/shared-template.yaml
  else
    echo
    echo "🔄 Updating keys for existing encrypted files..."
    just updatekeys
    echo "✅ Keys updated"
  fi

  # Display private key and next steps
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 SAVE THIS PRIVATE KEY SECURELY!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ "$METHOD" = "ssh" ]; then
    echo
    echo "SSH Private Key:"
    echo "$PRIVATE_KEY"
    echo
    echo "Age Private Key (for SOPS):"
    echo "$PRIVATE_AGE_KEY"
  else
    echo
    echo "Age Private Key:"
    echo "$PRIVATE_KEY"
  fi

  echo
  echo "Public Key (safe to share):"
  echo "$PUBLIC_KEY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo

  # Role-specific instructions
  if [ "$ROLE" = "dev" ]; then
    echo "📥 To install this dev key locally:"
    echo
    echo "   Option 1: Use sops-add-key recipe (interactive)"
    echo "   just sops-add-key"
    echo
    echo "   Option 2: Manual installation"
    echo "   mkdir -p ~/.config/sops/age"
    echo "   cat >> ~/.config/sops/age/keys.txt << EOF"
    echo "   # starlight-nix-template dev key"
    echo "   # public key: ${PUBLIC_KEY}"
    echo "   ${PRIVATE_KEY}"
    echo "   EOF"
    echo
    echo "   Then test: just show-secrets"
  elif [ "$ROLE" = "ci" ]; then
    echo "📤 To use this CI key:"
    echo
    echo "   1. Save private key to Bitwarden (for backup/recovery)"
    echo
    echo "   2. Add to vars/shared.yaml as CI_AGE_KEY:"
    echo "   just edit-secrets"
    echo "   # Add line: CI_AGE_KEY: ${PRIVATE_KEY}"
    echo
    echo "   3. Upload to GitHub secrets:"
    echo "   just sops-upload-github-key"
    echo "   # Paste the private key when prompted"
  fi

  echo
  echo "📋 Next steps:"
  if [ "$IS_ROTATION" = true ]; then
    echo "   1. Install/upload the new key (see instructions above)"
    echo "   2. Test decryption works: just show-secrets"
    echo "   3. Test CI workflow: just gh-ci-run"
    echo "   4. After verification, remove old key: just sops-finalize-rotation ${ROLE}"
  else
    echo "   1. Install/upload the key (see instructions above)"
    echo "   2. If bootstrapping dev key, generate CI key: just sops-bootstrap ci"
    echo "   3. Edit secrets: just edit-secrets"
    echo "   4. Check requirements: just sops-check-requirements"
    echo "   5. Upload to GitHub: just sops-setup-github"
  fi

  echo
  echo "💾 Backup saved: .sops.yaml.backup"

# Upload SOPS_AGE_KEY to GitHub (separate from other secrets to avoid chicken-and-egg)
[group('secrets')]
sops-upload-github-key repo="":
  #!/usr/bin/env bash
  set -euo pipefail

  REPO="{{ repo }}"
  if [ -z "$REPO" ]; then
    REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  fi

  echo "🔐 Upload SOPS_AGE_KEY to GitHub Secrets"
  echo "   Repository: $REPO"
  echo
  echo "This uploads the CI age private key so GitHub Actions can decrypt secrets."
  echo
  echo "You have two options:"
  echo "  1. Paste the CI_AGE_KEY from Bitwarden (recommended for rotation)"
  echo "  2. Extract from vars/shared.yaml (requires dev key to decrypt)"
  echo
  printf "Choose option (1/2): "
  read -r OPTION

  if [ "$OPTION" = "1" ]; then
    echo
    echo "Paste the AGE-SECRET-KEY (input will be hidden):"
    read -rs PRIVATE_KEY
    echo

    if [[ ! "$PRIVATE_KEY" =~ ^AGE-SECRET-KEY- ]]; then
      echo "❌ Invalid age private key format (must start with AGE-SECRET-KEY-)"
      exit 1
    fi
  elif [ "$OPTION" = "2" ]; then
    if [ ! -f vars/shared.yaml ]; then
      echo "❌ vars/shared.yaml not found"
      exit 1
    fi

    echo "Extracting CI_AGE_KEY from vars/shared.yaml..."
    PRIVATE_KEY=$(sops -d vars/shared.yaml | grep "^CI_AGE_KEY:" | cut -d: -f2- | xargs)

    if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "REPLACE_ME" ]; then
      echo "❌ CI_AGE_KEY not set in vars/shared.yaml"
      echo "   Run: just edit-secrets"
      exit 1
    fi
  else
    echo "❌ Invalid option"
    exit 1
  fi

  echo "Uploading to GitHub..."
  echo "$PRIVATE_KEY" | gh secret set SOPS_AGE_KEY --repo="$REPO"

  echo "✅ SOPS_AGE_KEY uploaded successfully"
  echo
  echo "Verify with:"
  echo "  gh secret list --repo=$REPO | grep SOPS_AGE_KEY"
  echo
  echo "Test with:"
  echo "  just gh-ci-run --debug=true"

# Enumerate required secrets by parsing GitHub workflows
[group('secrets')]
sops-check-requirements:
  #!/usr/bin/env bash
  set -euo pipefail

  echo "🔍 Analyzing required secrets for GitHub workflows"
  echo

  # Find all secrets and vars referenced in workflows
  if [ ! -d .github/workflows ]; then
    echo "❌ .github/workflows not found"
    exit 1
  fi

  WORKFLOW_SECRETS=$(grep -rh '\${{ secrets\.' .github/workflows/*.yaml 2>/dev/null | \
    grep -oP 'secrets\.\K[A-Z_]+' | sort -u || true)

  WORKFLOW_VARS=$(grep -rh '\${{ vars\.' .github/workflows/*.yaml 2>/dev/null | \
    grep -oP 'vars\.\K[A-Z_]+' | sort -u || true)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 REQUIRED GITHUB SECRETS (set via gh secret set)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  for secret in $WORKFLOW_SECRETS; do
    if [ "$secret" = "GITHUB_TOKEN" ]; then
      echo "   ✓ $secret (automatic, provided by GitHub)"
    elif [ "$secret" = "SOPS_AGE_KEY" ]; then
      echo "   ! $secret (CI age key - upload with: just sops-upload-github-key)"
    else
      echo "   → $secret (can be in vars/shared.yaml and uploaded via just ghsecrets)"
    fi
  done

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 REQUIRED GITHUB VARIABLES (set via gh variable set)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ -z "$WORKFLOW_VARS" ]; then
    echo "   (none found)"
  else
    for var in $WORKFLOW_VARS; do
      echo "   → $var (upload with: just ghvars)"
    done
  fi

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 SOPS-MANAGED SECRETS (in vars/shared.yaml)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ ! -f vars/shared.yaml ]; then
    echo "   ❌ vars/shared.yaml not found"
    echo "   Run: just sops-bootstrap dev"
  else
    # Try to decrypt and check contents
    if ! SOPS_SECRETS=$(sops -d vars/shared.yaml 2>/dev/null); then
      echo "   ❌ Cannot decrypt vars/shared.yaml"
      echo "   Ensure you have the dev key installed: just sops-add-key"
    else
      # Check each secret
      SECRET_KEYS=$(echo "$SOPS_SECRETS" | grep -E '^[A-Z_]+:' | cut -d: -f1 || true)

      for key in $SECRET_KEYS; do
        VALUE=$(echo "$SOPS_SECRETS" | grep "^$key:" | cut -d: -f2- | xargs)
        if [ "$VALUE" = "REPLACE_ME" ] || [ -z "$VALUE" ]; then
          echo "   ❌ $key (NOT SET - edit with: just edit-secrets)"
        else
          # Show first/last few chars for verification
          DISPLAY="${VALUE:0:4}...${VALUE: -4}"
          echo "   ✓ $key ($DISPLAY)"
        fi
      done

      # Check for missing secrets that workflows need
      echo
      echo "   Missing from vars/shared.yaml but found in workflows:"
      FOUND_MISSING=false
      for secret in $WORKFLOW_SECRETS; do
        if [ "$secret" != "GITHUB_TOKEN" ] && [ "$secret" != "SOPS_AGE_KEY" ]; then
          if ! echo "$SECRET_KEYS" | grep -q "^$secret$"; then
            echo "   ❌ $secret"
            FOUND_MISSING=true
          fi
        fi
      done
      if [ "$FOUND_MISSING" = false ]; then
        echo "   ✓ All workflow secrets present in vars/shared.yaml"
      fi
    fi
  fi

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "💡 NEXT STEPS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  echo "1. Ensure dev key is installed:"
  echo "   just sops-add-key"
  echo
  echo "2. Edit secrets to add missing values:"
  echo "   just edit-secrets"
  echo
  echo "3. Upload SOPS_AGE_KEY to GitHub:"
  echo "   just sops-upload-github-key"
  echo
  echo "4. Upload other secrets and variables to GitHub:"
  echo "   just sops-setup-github"
  echo
  echo "5. Verify GitHub secrets are set:"
  echo "   gh secret list"
  echo "   gh variable list"

# Comprehensive GitHub setup (uploads everything except SOPS_AGE_KEY)
[group('secrets')]
sops-setup-github repo="":
  #!/usr/bin/env bash
  set -euo pipefail

  REPO="{{ repo }}"
  if [ -z "$REPO" ]; then
    REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  fi

  echo "🚀 Comprehensive GitHub Secrets & Variables Setup"
  echo "   Repository: $REPO"
  echo
  echo "This will:"
  echo "  1. Upload GitHub variables (from environment or vars/shared.yaml)"
  echo "  2. Upload GitHub secrets (from vars/shared.yaml)"
  echo "  3. Skip SOPS_AGE_KEY (use sops-upload-github-key separately)"
  echo
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi

  # Check if SOPS_AGE_KEY is set
  echo "Checking SOPS_AGE_KEY status..."
  if gh secret list --repo="$REPO" 2>/dev/null | grep -q "SOPS_AGE_KEY"; then
    echo "✅ SOPS_AGE_KEY already set in GitHub"
  else
    echo "⚠️  SOPS_AGE_KEY not set in GitHub"
    echo "   This is required for CI to decrypt secrets."
    echo
    read -p "Upload SOPS_AGE_KEY now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      just sops-upload-github-key "$REPO"
    else
      echo "   Skipping SOPS_AGE_KEY upload."
      echo "   Run later: just sops-upload-github-key"
    fi
  fi

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📤 Uploading GitHub variables..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  just ghvars "$REPO"

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📤 Uploading GitHub secrets (except SOPS_AGE_KEY)..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Upload secrets from vars/shared.yaml
  sops exec-env vars/shared.yaml "
    set -euo pipefail

    if [ -n \"\${CACHIX_AUTH_TOKEN:-}\" ] && [ \"\$CACHIX_AUTH_TOKEN\" != \"REPLACE_ME\" ]; then
      gh secret set CACHIX_AUTH_TOKEN --repo='$REPO' --body=\"\$CACHIX_AUTH_TOKEN\"
      echo '   ✅ CACHIX_AUTH_TOKEN'
    fi

    if [ -n \"\${GITGUARDIAN_API_KEY:-}\" ] && [ \"\$GITGUARDIAN_API_KEY\" != \"REPLACE_ME\" ]; then
      gh secret set GITGUARDIAN_API_KEY --repo='$REPO' --body=\"\$GITGUARDIAN_API_KEY\"
      echo '   ✅ GITGUARDIAN_API_KEY'
    fi

    if [ -n \"\${CLOUDFLARE_API_TOKEN:-}\" ] && [ \"\$CLOUDFLARE_API_TOKEN\" != \"REPLACE_ME\" ]; then
      gh secret set CLOUDFLARE_API_TOKEN --repo='$REPO' --body=\"\$CLOUDFLARE_API_TOKEN\"
      echo '   ✅ CLOUDFLARE_API_TOKEN'
    fi

    if [ -n \"\${CLOUDFLARE_ACCOUNT_ID:-}\" ] && [ \"\$CLOUDFLARE_ACCOUNT_ID\" != \"REPLACE_ME\" ]; then
      gh secret set CLOUDFLARE_ACCOUNT_ID --repo='$REPO' --body=\"\$CLOUDFLARE_ACCOUNT_ID\"
      echo '   ✅ CLOUDFLARE_ACCOUNT_ID'
    fi

    echo
    echo '   ℹ️  SOPS_AGE_KEY skipped (upload separately with: just sops-upload-github-key)'
  "

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ GitHub setup complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  echo "Verification:"
  echo "  gh secret list --repo=$REPO"
  echo "  gh variable list --repo=$REPO"
  echo
  echo "Test CI:"
  echo "  just gh-ci-run"

# Finalize key rotation by removing old keys
[group('secrets')]
sops-finalize-rotation role='dev':
  #!/usr/bin/env bash
  set -euo pipefail

  ROLE="{{ role }}"

  echo "🧹 Finalize SOPS key rotation for role: $ROLE"
  echo
  echo "This will:"
  echo "  1. Remove old ${ROLE} key from .sops.yaml"
  echo "  2. Rename ${ROLE}-next to ${ROLE}"
  echo "  3. Update all encrypted files"
  echo
  echo "⚠️  Only proceed if you have verified the new key works!"
  echo
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi

  # Check if -next key exists
  if ! grep -q "\&${ROLE}-next" .sops.yaml; then
    echo "❌ No ${ROLE}-next key found in .sops.yaml"
    echo "   Nothing to finalize. Run rotation first: just sops-bootstrap $ROLE"
    exit 1
  fi

  # Backup
  cp .sops.yaml .sops.yaml.pre-finalize

  # Get old and new keys
  OLD_KEY=$(grep "^  - &${ROLE} " .sops.yaml | awk '{print $3}')
  NEW_KEY=$(grep "^  - &${ROLE}-next " .sops.yaml | awk '{print $3}')

  echo "Old ${ROLE} key: $OLD_KEY"
  echo "New ${ROLE} key: $NEW_KEY"
  echo

  # Remove old key line
  sed -i.tmp "/^  - &${ROLE} ${OLD_KEY}/d" .sops.yaml

  # Rename -next to regular
  sed -i.tmp "s/&${ROLE}-next/${ROLE}/g" .sops.yaml
  sed -i.tmp "s/\*${ROLE}-next/*${ROLE}/g" .sops.yaml

  rm .sops.yaml.tmp

  echo "📝 Updated .sops.yaml"
  echo
  echo "🔄 Updating encrypted files to remove old key..."
  just updatekeys

  echo
  echo "✅ Rotation finalized!"
  echo "   Old key: $OLD_KEY (REMOVED)"
  echo "   New key: $NEW_KEY (now $ROLE)"
  echo
  echo "💾 Backup saved: .sops.yaml.pre-finalize"
  echo
  echo "⚠️  Update Bitwarden/key storage:"
  echo "   - Mark old $ROLE key as 'revoked' or delete"
  echo "   - Ensure new key is saved"

# Quick rotation workflow (combines bootstrap + finalize after verification)
[group('secrets')]
sops-rotate role='dev':
  #!/usr/bin/env bash
  echo "🔄 Quick rotation workflow for {{ role }} key"
  echo
  echo "Step 1/3: Bootstrap new key..."
  just sops-bootstrap {{ role }}
  echo
  read -p "Install/upload the new key, then press Enter to continue..." _
  echo
  echo "Step 2/3: Verify new key works..."
  echo "Testing decryption..."
  if just show-secrets > /dev/null 2>&1; then
    echo "✅ Decryption works!"
  else
    echo "❌ Decryption failed. Fix the issue before finalizing."
    exit 1
  fi
  echo
  read -p "Step 3/3: Finalize rotation? This removes the old key. (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    just sops-finalize-rotation {{ role }}
  else
    echo "Rotation not finalized. Run manually when ready:"
    echo "  just sops-finalize-rotation {{ role }}"
  fi

## Testing

# Run all tests (unit and E2E)
[group('testing')]
test:
  bun run test

# Run unit tests with vitest
[group('testing')]
test-unit:
  bun run test:unit

# Run E2E tests with playwright
[group('testing')]
test-e2e:
  bun run test:e2e

# Run vitest in watch mode
[group('testing')]
test-watch:
  bun run test:watch

# Run playwright in UI mode
[group('testing')]
test-ui:
  bun run test:ui

# Generate test coverage report
[group('testing')]
test-coverage:
  bun run test:coverage

# Install playwright browsers
[group('testing')]
playwright-install:
  bunx playwright install --with-deps
