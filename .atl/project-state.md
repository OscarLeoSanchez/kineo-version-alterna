# Project State — kineo-coah

Last updated: 2026-03-13

## Current state

- Repository branch: `main`
- Local working tree contains uncommitted changes
- Main active feature in progress: `interactive-coaching`
- `.atl/` was recreated from the live repository state plus Engram context

## Backend status

- Stack: FastAPI
- SSE endpoint present at `/api/v1/plans/generate-stream`
- Plan schema is enriched with `schema_version = 2`
- `PlanService.generate_stream()` emits progress events and a final `done` event
- Docker compose points the API to a remote PostgreSQL instance

## Flutter status

- Stack: Flutter
- Route `/plan-generation` exists
- SSE client exists in `features/plans/data/services/plan_sse_api_service.dart`
- Real-time plan generation page exists in `features/plans/presentation/pages/plan_generation_page.dart`
- New reusable/shared/detail widgets exist for workout and nutrition flows

## Divergences detected

- Engram remembered old `.atl/locks/general-project-work.json`, but `.atl/` was missing in the live repo before this reconstruction
- Engram recorded a locale fix for Spanish date formatting, but `mobile/flutter_app/lib/main.dart` currently does not show that fix

## Working tree snapshot

Modified files observed:

- `backend/api/.env.example`
- `backend/api/app/ai/planner.py`
- `backend/api/app/ai/planning_models.py`
- `backend/api/app/api/v1/endpoints/plans.py`
- `backend/api/app/services/plan_service.py`
- `docker-compose.yml`
- `mobile/flutter_app/lib/core/router/app_router.dart`
- `mobile/flutter_app/lib/features/nutrition/presentation/pages/nutrition_page.dart`
- `mobile/flutter_app/lib/features/workout/presentation/pages/workout_page.dart`

Untracked additions observed:

- `.claude/`
- `mobile/flutter_app/lib/features/nutrition/presentation/widgets/`
- `mobile/flutter_app/lib/features/plans/data/services/plan_sse_api_service.dart`
- `mobile/flutter_app/lib/features/plans/presentation/pages/`
- `mobile/flutter_app/lib/features/workout/presentation/widgets/`
- `mobile/flutter_app/lib/shared/widgets/app_bottom_sheet.dart`
- `mobile/flutter_app/lib/shared/widgets/pressable_card.dart`
- `mobile/flutter_app/lib/shared/widgets/shimmer_box.dart`

## Relevant Engram topics

- `sdd/interactive-coaching/proposal`
- `sdd/interactive-coaching/spec`
- `sdd/interactive-coaching/design`
- `SDD tasks: interactive-coaching`
- discovery about repo/Engram divergence on 2026-03-13

## Suggested next step

- Compare live code against the `interactive-coaching` SDD artifacts and decide what to finish, commit, or revert
