# Skill Registry — kineo-coah

Generated: 2026-03-13

This registry mirrors the skills currently available in this session and most relevant to this repository.

## Project workflow skills

- `engram-lock` — coordinate substantial work with `.atl/locks/{change}.json` plus Engram recovery
- `sdd-init` — initialize SDD context
- `sdd-explore` — investigate and clarify a change
- `sdd-propose` — write/update a proposal
- `sdd-spec` — write/update specifications
- `sdd-design` — write/update technical design
- `sdd-tasks` — create/update implementation tasks
- `sdd-apply` — implement tasks in code
- `sdd-verify` — verify implementation against specs/design/tasks
- `sdd-archive` — archive a completed change

## Skill management

- `skill-registry` — refresh this registry
- `skill-creator` — create or improve a skill
- `skill-installer` — install Codex skills
- `find-skills` — discover suitable skills for a capability

## Infra / platform

- `azure-postgres` — Azure PostgreSQL Flexible Server + Entra ID authentication

## Current recommendation for this repo

- Use `engram-lock` before substantial changes
- Use the `sdd-*` chain for large features/refactors
- Treat Engram + `.atl/project-state.md` as the fastest recovery path for future sessions
