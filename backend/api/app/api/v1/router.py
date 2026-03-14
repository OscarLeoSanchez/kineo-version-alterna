from fastapi import APIRouter

from app.api.v1.endpoints import activity
from app.api.v1.endpoints import auth
from app.api.v1.endpoints import exercises
from app.api.v1.endpoints import experience
from app.api.v1.endpoints import goals
from app.api.v1.endpoints import health
from app.api.v1.endpoints import onboarding
from app.api.v1.endpoints import plan_modifications
from app.api.v1.endpoints import plans
from app.api.v1.endpoints import preferences
from app.api.v1.endpoints import reports

router = APIRouter()
router.include_router(activity.router, tags=["activity"])
router.include_router(auth.router, tags=["auth"])
router.include_router(exercises.router)
router.include_router(experience.router, tags=["experience"])
router.include_router(goals.router, tags=["goals"])
router.include_router(health.router, tags=["health"])
router.include_router(onboarding.router, tags=["onboarding"])
router.include_router(plan_modifications.router)
router.include_router(plans.router, tags=["plans"])
router.include_router(preferences.router, tags=["preferences"])
router.include_router(reports.router, tags=["reports"])
