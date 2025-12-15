---
title: Infrastructure pattern migration
description: Migration plan for adopting infra repo patterns in typescript-nix-template
---

This document tracks the migration of best practices from `~/projects/nix-workspace/infra` (vanixiets) to this repository.
The goal is wholesale adoption of proven patterns while acknowledging that infrastructure-specific features (machine configurations, clan orchestration) are not applicable to a project template.

## Motivation

The infra repository has evolved mature patterns for:
- Deferred module composition via import-tree
- Unified formatting with treefmt-nix
- Nix expression testing with nix-unit
- Category-based CI builds with cachix integration
- One-to-one mapping between justfile recipes and CI jobs

This template should adopt these patterns to ensure consistency across the nix-workspace ecosystem and provide a solid foundation for new TypeScript projects.

## Current state

| Aspect | Current | Target |
|--------|---------|--------|
| Module discovery | `builtins.readDir ./nix/modules` | `import-tree ./modules` |
| Module path | `nix/modules/` (5 flat files) | `modules/` (hierarchical) |
| Formatting | biome + pre-commit | treefmt-nix + biome |
| Nix testing | None | nix-unit via flake checks |
| CI structure | Single nix job, omnix | Category-based matrix, native nix |
| CI invocation | Mixed patterns | `nix develop -c just [cmd]` |

## Migration phases

Each phase is documented in a separate file with specific steps and verification commands.

### Phase 1: import-tree adoption

Migrate from inline `readDir` to import-tree for module discovery.
Restructure `nix/modules/` to `modules/` with proper hierarchy.

See: [phase-1-import-tree.md](./phase-1-import-tree.md)

### Phase 2: treefmt-nix integration

Add treefmt-nix for unified formatting across nix, TypeScript, and other file types.
Integrate with existing biome configuration.

See: [phase-2-treefmt-nix.md](./phase-2-treefmt-nix.md)

### Phase 3: nix-unit testing

Add nix-unit for testing nix expressions.
Create initial test suite for module validation.

See: [phase-3-nix-unit.md](./phase-3-nix-unit.md)

### Phase 4: CI workflow refactor

Restructure CI to use category-based builds.
Eliminate omnix dependency.
Ensure local-CI equivalence via justfile.

See: [phase-4-ci-refactor.md](./phase-4-ci-refactor.md)

### Phase 5: justfile synchronization

Align justfile recipes with CI jobs.
Add new recipes for nix-unit, treefmt, category builds.
Remove obsolete recipes.

See: [phase-5-justfile-sync.md](./phase-5-justfile-sync.md)

## Verification

Cross-cutting verification steps to confirm successful migration.

See: [verification-checklist.md](./verification-checklist.md)

## Dependencies

Phase dependency graph:

```
Phase 1 (import-tree)
    │
    ├──► Phase 2 (treefmt-nix) ──┐
    │                            │
    └──► Phase 3 (nix-unit) ─────┼──► Phase 4 (CI refactor)
                                 │          │
                                 │          ▼
                                 └────► Phase 5 (justfile)
```

Phases 2 and 3 can proceed in parallel after Phase 1 completes.
Phase 4 depends on both 2 and 3 (CI needs to run formatters and tests).
Phase 5 finalizes recipe alignment after CI structure is settled.

## Success criteria

1. `nix flake check` passes with all new checks
2. `just check` runs treefmt and reports cleanly
3. `just test-nix` runs nix-unit tests
4. CI workflow completes without omnix
5. Every CI job has a corresponding `just` recipe
6. Local `just [recipe]` produces same result as CI

## Reference repositories

- Source: `~/projects/nix-workspace/infra` (vanixiets)
- Related: `~/projects/nix-workspace/import-tree`
- Related: `~/projects/nix-workspace/flake-parts`
