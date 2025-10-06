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
# Note: SOPS_AGE_KEY is uploaded separately via sops-upload-github-key
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
  gh secret set CLOUDFLARE_API_TOKEN --repo='"$REPO"' --body="$CLOUDFLARE_API_TOKEN"'
  echo
  echo "secrets after updates (wait 3 seconds for github to update):"
  sleep 3
  echo
  PAGER=cat gh secret list --repo="$REPO"
  echo
  echo "ℹ️  SOPS_AGE_KEY not uploaded (requires special handling)"
  echo "   Upload with: just sops-upload-github-key"

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

# Test specific CI job remotely on GitHub
[group('CI/CD')]
gh-ci-job job branch=`git branch --show-current` debug="false":
  #!/usr/bin/env bash
  echo "Triggering CI job '{{job}}' on GitHub (branch: {{branch}}, debug: {{debug}})..."
  gh workflow run ci.yaml \
    --repo ${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)} \
    --ref "{{branch}}" \
    --field job="{{job}}" \
    --field debug_enabled="{{debug}}"
  echo "Check workflow status with: just gh-workflow-status"

# Test deploy workflow remotely on GitHub
[group('CI/CD')]
gh-deploy branch=`git branch --show-current` env="preview" debug="false":
  #!/usr/bin/env bash
  echo "Triggering deploy-docs workflow on GitHub (branch: {{branch}}, env: {{env}}, debug: {{debug}})..."
  gh workflow run deploy-docs.yaml \
    --repo ${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)} \
    --ref "{{branch}}" \
    --field branch="{{branch}}" \
    --field environment="{{env}}" \
    --field debug_enabled="{{debug}}"
  echo "Check workflow status with: just gh-workflow-status deploy-docs.yaml"

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

# Build and deploy the site to Cloudflare Workers
[group('cloudflare')]
cf-build-deploy: install
  bun run deploy

# Deploy preview version to Cloudflare Pages (does not affect production)
[group('cloudflare')]
cf-deploy-preview branch=`git branch --show-current`:
  #!/usr/bin/env bash
  sops exec-env vars/shared.yaml "
    echo 'Deploying preview for branch: {{branch}}'
    bunx wrangler pages deploy dist/ \
      --project-name=starlight-nix-template \
      --branch={{branch}} \
      --commit-dirty=true
  "

# Deploy to production on Cloudflare Pages
[group('cloudflare')]
cf-deploy-production branch=`git branch --show-current`:
  #!/usr/bin/env bash
  sops exec-env vars/shared.yaml "
    echo 'Deploying production version for branch: {{branch}}'
    bunx wrangler pages deploy dist/ \
      --project-name=starlight-nix-template \
      --branch={{branch}} \
      --commit-dirty=true
  "

# List recent Cloudflare Pages deployments
[group('cloudflare')]
cf-deployments limit="10":
  sops exec-env vars/shared.yaml "bunx wrangler pages deployment list --project-name=starlight-nix-template"

# Get latest deployment ID from Cloudflare Pages
[group('cloudflare')]
cf-deployment-latest:
  @sops exec-env vars/shared.yaml "bunx wrangler pages deployment list --project-name=starlight-nix-template --json | jq -r '.[0].id'"

# Promote a specific deployment to production
[group('cloudflare')]
cf-promote deployment_id:
  sops exec-env vars/shared.yaml "bunx wrangler pages deployment promote {{deployment_id}} --project-name=starlight-nix-template"

# Rollback to previous deployment (promote the second most recent)
[group('cloudflare')]
cf-rollback:
  #!/usr/bin/env bash
  sops exec-env vars/shared.yaml "
    PREV_DEPLOYMENT=\$(bunx wrangler pages deployment list --project-name=starlight-nix-template --json | jq -r '.[1].id')
    echo \"Rolling back to deployment: \$PREV_DEPLOYMENT\"
    bunx wrangler pages deployment promote \$PREV_DEPLOYMENT --project-name=starlight-nix-template
  "

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
    sops updatekeys -y "$file"; \
  done
  @echo "✅ Keys updated for all secrets files"

# Bootstrap or rotate SOPS age keys (unified recipe for first-time and rotation)
[group('secrets')]
sops-bootstrap role='dev' method='age':
  @scripts/sops-bootstrap.sh "{{ role }}" "{{ method }}"

# Upload SOPS_AGE_KEY to GitHub (separate from other secrets to avoid chicken-and-egg)
[group('secrets')]
sops-upload-github-key repo="":
  @scripts/sops-upload-github-key.sh "{{ repo }}"

# Enumerate required secrets by parsing GitHub workflows
[group('secrets')]
sops-check-requirements:
  @scripts/sops-check-requirements.sh

# Comprehensive GitHub setup (uploads everything except SOPS_AGE_KEY)
[group('secrets')]
sops-setup-github repo="":
  @scripts/sops-setup-github.sh "{{ repo }}"

# Finalize key rotation by removing old keys
[group('secrets')]
sops-finalize-rotation role='dev':
  @scripts/sops-finalize-rotation.sh "{{ role }}"

# Quick rotation workflow (combines bootstrap + finalize after verification)
[group('secrets')]
sops-rotate role='dev':
  @scripts/sops-rotate.sh "{{ role }}"


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

# Install playwright browsers (only needed outside Nix environment)
# The Nix devshell provides browsers via playwright-driver.browsers
# See: nix/modules/devshell.nix lines 36, 47-48
[group('testing')]
playwright-install:
  @echo "Note: When using 'nix develop', browsers are provided by Nix"
  @echo "This command is only needed in non-Nix environments"
  bunx playwright install --with-deps
