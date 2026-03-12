from datetime import datetime

from pydantic import BaseModel


class WeeklyReportRead(BaseModel):
    generated_at: datetime
    title: str
    goal_status: list[dict[str, int | str | bool]]
    highlights: list[str]
    markdown_report: str
