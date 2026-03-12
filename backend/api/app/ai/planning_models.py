from pydantic import BaseModel, Field


class WorkoutExercisePlan(BaseModel):
    name: str
    sets: str
    reps: str
    rest: str
    notes: str = ""


class WorkoutBlockPlan(BaseModel):
    title: str
    description: str
    time_box: str
    goal: str
    exercises: list[WorkoutExercisePlan] = Field(default_factory=list)


class DailyWorkoutPlan(BaseModel):
    day_label: str
    session_title: str
    focus: str
    objective: str
    duration_minutes: int = Field(ge=20, le=180)
    intensity: str
    warmup: list[str] = Field(default_factory=list)
    blocks: list[WorkoutBlockPlan] = Field(default_factory=list)
    cooldown: list[str] = Field(default_factory=list)
    adaptation_hint: str


class MealOptionPlan(BaseModel):
    name: str
    summary: str
    macros: str
    ingredients: list[str] = Field(default_factory=list)
    preparation: str
    best_for: str


class WeeklyMealPlanEntry(BaseModel):
    day_label: str
    meal_name: str
    detail: str
    macros: str
    components: list[str] = Field(default_factory=list)
    preparation: str
    swap_options: list[str] = Field(default_factory=list)


class MealSlotPlan(BaseModel):
    title: str
    objective: str
    weekly_plan: list[WeeklyMealPlanEntry] = Field(default_factory=list)
    option_bank: list[MealOptionPlan] = Field(default_factory=list, min_length=10, max_length=10)


class GeneratedProgram(BaseModel):
    plan_name: str
    workout_focus: str
    workout_summary: str
    nutrition_summary: str
    habits_summary: str
    calorie_target: str
    macro_focus: list[str] = Field(default_factory=list)
    weekly_workouts: list[DailyWorkoutPlan] = Field(default_factory=list, min_length=7, max_length=7)
    meal_slots: list[MealSlotPlan] = Field(default_factory=list, min_length=4, max_length=4)
