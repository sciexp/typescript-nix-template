# Secrets Management with SOPS

This directory contains encrypted secrets managed by [SOPS](https://github.com/getsops/sops) for CI/CD workflows.

## Required Secrets

Create a file `shared.yaml` in this directory with the following secrets:

```yaml
CLOUDFLARE_ACCOUNT_ID: your-cloudflare-account-id
CLOUDFLARE_API_TOKEN: your-cloudflare-api-token
GITGUARDIAN_API_KEY: your-gitguardian-api-key
CACHIX_AUTH_TOKEN: your-cachix-auth-token
CACHIX_CACHE_NAME: your-cachix-cache-name
CI_AGE_KEY: your-ci-age-private-key
```

## Cloudflare Secrets

To deploy to Cloudflare Workers, you need:

1. **CLOUDFLARE_ACCOUNT_ID**: Your Cloudflare account ID
   - Find at: https://dash.cloudflare.com/ → (select account) → Workers & Pages → Overview (right sidebar)

2. **CLOUDFLARE_API_TOKEN**: API token with Workers deployment permissions
   - Create at: https://dash.cloudflare.com/profile/api-tokens
   - Required permissions: Account.Workers Scripts (Edit), Account.Workers Routes (Edit)

## CI/CD Secrets

3. **GITGUARDIAN_API_KEY**: API key for GitGuardian secret scanning
   - Get from: https://dashboard.gitguardian.com/api/personal-access-tokens

4. **CACHIX_AUTH_TOKEN**: Auth token for Nix binary cache
   - Get from: https://app.cachix.org/cache/YOUR_CACHE/settings

5. **CACHIX_CACHE_NAME**: Name of your Cachix cache

6. **CI_AGE_KEY**: Private age key for CI to decrypt secrets
   - This should be the private key corresponding to the CI public key in `.sops.yaml`
   - The public key in `.sops.yaml` is: `age1m9m8h5vqr7dqlmvnzcwshmm4uk8umcllazum6eaulkdp3qc88ugs22j3p8`

## Encrypting Secrets

After creating `shared.yaml` with unencrypted values:

```bash
# Encrypt the file in place
sops --encrypt --in-place vars/shared.yaml

# Or encrypt to a new file
sops --encrypt vars/shared.yaml > vars/shared.yaml.enc
mv vars/shared.yaml.enc vars/shared.yaml
```

## Editing Encrypted Secrets

```bash
# Edit encrypted file
sops vars/shared.yaml
```

SOPS will decrypt, open in your editor, and re-encrypt on save.

## Uploading to GitHub

After encrypting `shared.yaml`, upload the CI_AGE_KEY to GitHub:

```bash
# Set the CI_AGE_KEY as a GitHub secret
gh secret set SOPS_AGE_KEY < <(sops --decrypt --extract '["CI_AGE_KEY"]' vars/shared.yaml)
```

Or manually at: https://github.com/YOUR_USERNAME/typescript-nix-template/settings/secrets/actions

## Security Notes

- Never commit unencrypted secrets
- The `.gitignore` is configured to only allow encrypted files
- Encrypted files can be safely committed to the repository
- Only users with the age private keys in `.sops.yaml` can decrypt
