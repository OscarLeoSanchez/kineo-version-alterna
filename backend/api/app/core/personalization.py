from dataclasses import dataclass

from fastapi import Header


@dataclass(frozen=True)
class PersonalizationContext:
    coach_style: str = ""
    experience_mode: str = ""
    units: str = ""
    daily_priority: str = ""
    recommendation_depth: str = ""
    proactive_adjustments: bool | None = None

    @property
    def full_access_active(self) -> bool:
        return bool(self.experience_mode) and self.experience_mode.lower() != "free"

    @property
    def pro_active(self) -> bool:
        return self.full_access_active


def get_personalization_context(
    coach_style: str | None = Header(default=None, alias="X-Coach-Style"),
    experience_mode: str | None = Header(default=None, alias="X-Experience-Mode"),
    membership_plan: str | None = Header(default=None, alias="X-Membership-Plan"),
    units: str | None = Header(default=None, alias="X-Units"),
) -> PersonalizationContext:
    return PersonalizationContext(
        coach_style=coach_style or "",
        experience_mode=experience_mode or membership_plan or "",
        units=units or "",
    )


def merge_personalization_context(
    *,
    stored: PersonalizationContext,
    incoming: PersonalizationContext,
) -> PersonalizationContext:
    return PersonalizationContext(
        coach_style=incoming.coach_style or stored.coach_style,
        experience_mode=incoming.experience_mode or stored.experience_mode,
        units=incoming.units or stored.units,
        daily_priority=incoming.daily_priority or stored.daily_priority,
        recommendation_depth=incoming.recommendation_depth or stored.recommendation_depth,
        proactive_adjustments=(
            incoming.proactive_adjustments
            if incoming.proactive_adjustments is not None
            else stored.proactive_adjustments
        ),
    )
