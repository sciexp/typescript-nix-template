# SOPS quick reference

## Common operations

### First-time setup

```bash
# 1. Generate and install dev key
just sops-bootstrap dev
just sops-add-key  # Paste private key

# 2. Generate CI key
just sops-bootstrap ci
# Save private key to Bitwarden

# 3. Edit secrets
just edit-secrets
# Replace all REPLACE_ME values

# 4. Upload to GitHub
just sops-upload-github-key  # Option 2: from vars/shared.yaml
just sops-setup-github       # Other secrets and variables

# 5. Verify
just sops-check-requirements
gh secret list
just gh-ci-run
```

### Daily usage

```bash
# View secrets
just show-secrets

# Edit secrets
just edit-secrets

# Set specific secret
just set-secret CLOUDFLARE_API_TOKEN "new-value"

# Run command with secrets
just run-with-secrets 'echo $CLOUDFLARE_API_TOKEN'

# Validate all secrets decrypt
just validate-secrets
```

### Key rotation

```bash
# Quick rotation (guided)
just sops-rotate dev    # or 'ci'

# Manual rotation
just sops-bootstrap dev
just sops-add-key
just show-secrets  # Verify works
just sops-finalize-rotation dev
```

### GitHub sync

```bash
# Check what secrets are needed
just sops-check-requirements

# Upload SOPS_AGE_KEY
just sops-upload-github-key

# Upload all other secrets
just sops-setup-github

# Or upload individually
just ghsecrets  # Secrets from vars/shared.yaml
just ghvars     # Variables from environment
```

### Troubleshooting

```bash
# Can't decrypt?
grep "public key:" ~/.config/sops/age/keys.txt
cat .sops.yaml  # Is your key listed?

# Update keys after changing .sops.yaml
just updatekeys

# CI failing?
gh secret list | grep SOPS_AGE_KEY
just gh-logs  # Check error message
```

## Recipe quick reference

| Recipe | Purpose |
|--------|---------|
| `sops-bootstrap <role>` | Generate new dev/ci key |
| `sops-rotate <role>` | Quick rotation workflow |
| `sops-finalize-rotation <role>` | Remove old key after rotation |
| `sops-add-key` | Install key locally |
| `sops-init` | Generate new age key |
| `edit-secrets` | Edit vars/shared.yaml |
| `show-secrets` | View decrypted secrets |
| `set-secret <name> <value>` | Set specific secret |
| `rotate-secret <name>` | Rotate specific secret value |
| `validate-secrets` | Verify all files decrypt |
| `updatekeys` | Update encrypted files after key changes |
| `sops-check-requirements` | Show required secrets from workflows |
| `sops-upload-github-key` | Upload SOPS_AGE_KEY to GitHub |
| `sops-setup-github` | Upload all secrets/vars to GitHub |
| `ghsecrets [repo]` | Upload secrets from SOPS |
| `ghvars [repo]` | Upload variables |

## File locations

| File | Purpose |
|------|---------|
| `.sops.yaml` | SOPS config (public keys only) |
| `vars/shared.yaml` | Encrypted secrets (committed) |
| `~/.config/sops/age/keys.txt` | Your private keys (NOT committed) |
| GitHub Secrets: `SOPS_AGE_KEY` | CI private key |

## Key public keys (from .sops.yaml)

- **Dev**: `age1dn8w7y4t4h23fmeenr3dghfz5qh53jcjq9qfv26km3mnv8l44g0sghptu3`
- **CI**: `age1m9m8h5vqr7dqlmvnzcwshmm4uk8umcllazum6eaulkdp3qc88ugs22j3p8`

## Required secrets (from ci.yaml)

| Secret | Location | Purpose |
|--------|----------|---------|
| `SOPS_AGE_KEY` | GitHub Secret | CI age private key |
| `CACHIX_AUTH_TOKEN` | vars/shared.yaml → GitHub Secret | Nix cache auth |
| `CACHIX_CACHE_NAME` | vars/shared.yaml → GitHub Variable | Nix cache name |
| `GITGUARDIAN_API_KEY` | vars/shared.yaml → GitHub Secret | Secret scanning |
| `CLOUDFLARE_API_TOKEN` | vars/shared.yaml | Cloudflare deploy |
| `CLOUDFLARE_ACCOUNT_ID` | vars/shared.yaml | Cloudflare account |
| `CI_AGE_KEY` | vars/shared.yaml | Backup of SOPS_AGE_KEY |

## Emergency contacts

- Bitwarden: CI key backup
- `.sops.yaml.backup`: Rollback point
- `vars/shared.yaml.backup`: Rollback point
- SOPS-WORKFLOW-GUIDE.md: Full documentation
