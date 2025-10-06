# SOPS implementation notes

## Summary

Successfully implemented and tested end-to-end SOPS key management workflow for starlight-nix-template.

## Issues discovered and fixed

### 1. age-keygen temp file handling

**Problem:** age-keygen expects to create the output file itself and fails if it already exists.

**Solution:** Remove temp file after mktemp but before passing to age-keygen.

```bash
KEY_FILE=$(mktemp)
rm -f "$KEY_FILE"  # age-keygen expects to create the file itself
age-keygen -o "$KEY_FILE"
```

**Commit:** fix(secrets): remove temp file before age-keygen

### 2. Bootstrap vs rotation detection logic inverted

**Problem:** Script treated placeholder keys as rotation instead of bootstrap.

**Solution:** Inverted the logic - placeholder keys indicate bootstrap, real keys indicate rotation.

```bash
if [ "$CURRENT_KEY" = "age1dn8..." ] || [ "$CURRENT_KEY" = "age1m9m..." ]; then
  IS_ROTATION=false  # Placeholder = bootstrap
else
  IS_ROTATION=true   # Real key = rotation
fi
```

**Commit:** fix(secrets): correct bootstrap vs rotation detection logic

### 3. Case-sensitive grep for age-keygen output

**Problem:** age-keygen outputs "Public key:" (capital P) but script grepped for "public key:" (lowercase).

**Solution:** Use case-insensitive grep with -i flag.

```bash
PUBLIC_KEY=$(grep -i "public key:" /tmp/keygen-output.txt | cut -d: -f2 | xargs)
```

**Commit:** fix(secrets): use case-insensitive grep for age-keygen output

### 4. SOPS path_regex mismatch during bootstrap

**Problem:** Trying to encrypt /tmp/shared-template.yaml but path_regex only matches vars/*.yaml.

**Solution:** Move template to vars/ directory before encryption.

```bash
mv /tmp/shared-template.yaml vars/shared-template.yaml
sops --config /tmp/sops-bootstrap.yaml -e vars/shared-template.yaml > vars/shared.yaml
```

**Commit:** fix(secrets): move template to vars/ for sops path regex match

### 5. SOPS encrypting for placeholder CI key

**Problem:** During dev key bootstrap, SOPS tried to encrypt for both dev and placeholder CI keys, failing because CI key was invalid.

**Solution:** Create temporary .sops.yaml with only dev key for initial encryption.

```bash
cat > /tmp/sops-bootstrap.yaml << SOPSEOF
keys:
  - &dev ${PUBLIC_KEY}
creation_rules:
  - path_regex: vars/.*\.yaml$
    key_groups:
      - age:
          - *dev
SOPSEOF
```

**Commit:** fix(secrets): use temporary sops config for initial encryption

### 6. Interactive sops updatekeys during CI bootstrap

**Problem:** sops updatekeys prompts for confirmation, blocking automated workflow.

**Solution:** Add -y flag to updatekeys command in justfile.

```bash
sops updatekeys -y "$file"
```

**Commit:** fix(secrets): add -y flag to sops updatekeys for non-interactive use

## Workflow validation

Successfully completed full workflow:

1. ✅ Bootstrap dev key: `just sops-bootstrap dev`
   - Generated age keypair
   - Updated .sops.yaml with public key
   - Created vars/shared.yaml with template
   - Private key saved to Bitwarden

2. ✅ Install dev key locally: Manual installation to ~/.config/sops/age/keys.txt
   - sops-add-key recipe is interactive and doesn't work in automated environment
   - Manual installation worked perfectly

3. ✅ Verify dev key: `just show-secrets`
   - Successfully decrypted vars/shared.yaml
   - Showed REPLACE_ME placeholder values

4. ✅ Bootstrap CI key: `just sops-bootstrap ci`
   - Generated CI age keypair
   - Updated .sops.yaml with CI public key
   - Updated vars/shared.yaml keys with -y flag
   - Private key saved to Bitwarden

5. ✅ Populate secrets: Edited vars/shared.yaml with real values
   - CACHIX_AUTH_TOKEN
   - CACHIX_CACHE_NAME
   - GITGUARDIAN_API_KEY
   - CLOUDFLARE_API_TOKEN
   - CLOUDFLARE_ACCOUNT_ID
   - CI_AGE_KEY (auto-populated)

6. ✅ Verify secrets: `just sops-check-requirements`
   - All secrets populated (no REPLACE_ME values)
   - Identified required GitHub secrets/variables

7. ✅ Upload SOPS_AGE_KEY: Manual gh secret set
   - Extracted CI_AGE_KEY from vars/shared.yaml
   - Uploaded as SOPS_AGE_KEY to GitHub

8. ✅ Upload other secrets: `just ghvars` + sops exec-env
   - CACHIX_CACHE_NAME variable uploaded
   - All other secrets uploaded to GitHub

9. ✅ Verify GitHub setup
   - All 5 secrets present
   - 1 variable present

## Recommendations

### Script improvements

1. **Non-interactive mode flag**: Add --yes/-y flag to all interactive scripts for automation support

2. **Better error messages**: Include more context about what failed and suggested fixes

3. **Idempotency**: Scripts should be safe to run multiple times (currently some fail if key exists)

### Documentation improvements

1. **Add troubleshooting section** to SOPS-WORKFLOW-GUIDE.md with these fixes

2. **Document manual fallbacks** for interactive recipes like sops-add-key

3. **Add validation steps** after each major operation to catch errors early

### Workflow improvements

1. **Atomic commits**: Successfully used atomic commits throughout (per user preferences)

2. **Test coverage**: Consider adding integration tests for the full workflow

3. **Key rotation testing**: Test the rotation workflow to ensure dev-next/ci-next anchors work correctly

## Git commit summary

To see all commits created during this session:

```bash
git log --oneline eeba247..8015ea1
```

## Files created

- `.sops.yaml` - Updated with real public keys (committed)
- `vars/shared.yaml` - Encrypted secrets (committed)
- `scripts/sops-*.sh` - Six bash scripts for key management (committed)
- `SOPS-IMPLEMENTATION-NOTES.md` - This file (to be committed)

## Next steps

1. Test CI workflow: `just gh-ci-run` to verify SOPS_AGE_KEY works in GitHub Actions

2. Test key rotation: Follow rotation workflow in SOPS-WORKFLOW-GUIDE.md

3. Clean up temporary documentation:
   - IMPLEMENTATION-PLAN.md
   - SOPS-QUICK-REFERENCE.md (consider keeping)
   - SOPS-WORKFLOW-GUIDE.md (consider keeping)
   - justfile-ghsecrets-update.patch
   - sops-recipes-to-add.just
