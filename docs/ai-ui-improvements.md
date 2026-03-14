# Mejoras UI/UX — Aprovechamiento del Potencial de IA

> Generado: 2026-03-13
> Contexto: La IA genera datos muy ricos (planes, análisis de fotos, insights) pero el frontend no los muestra ni los usa correctamente. Este documento lista todas las mejoras priorizadas.

---

## Estado actual por módulo

| Módulo | Campos disponibles | Campos mostrados | Utilización |
|--------|-------------------|-----------------|-------------|
| Dashboard | 11 | 3–4 | ~27% |
| Nutrición (página) | 8 | 2–3 | ~30% |
| Análisis de foto | 10 | 3–4 | ~35% |
| Workout (bloque/sesión) | 8 | 4–5 | ~55% |
| Detalle de comida (sheet) | 14 | 8–10 | ~65% |
| Ejercicio (detalle) | 15+ | 10–11 | ~70% |

---

## 🔴 Prioridad Alta — Bajo esfuerzo (datos ya llegan, solo falta UI)

### T-01 — Header de nutrición: calorías y macros del día
- **Archivo:** `nutrition_page.dart` → `_TodaySummaryCard`
- **Datos disponibles:** `calorie_target`, `calories_consumed_today`, `protein_target_g`, `protein_consumed_g`, `carbs_target_g`, `carbs_consumed_g`, `fat_target_g`, `fat_consumed_g`
- **Qué hacer:**
  - [ ] Mostrar calorías consumidas vs. meta con barra de progreso circular
  - [ ] Tres mini-barras de progreso: proteínas, carbos, grasas (consumido/meta)
  - [ ] Mostrar `macro_focus` como chips de color debajo de la barra
  - [ ] Usar colores: verde si <90%, ámbar si 90–105%, rojo si >105%

### T-02 — `swap_tip` visible en nutrición
- **Archivo:** `nutrition_page.dart`
- **Datos disponibles:** `swap_tip` (string con sugerencia de la IA)
- **Qué hacer:**
  - [ ] Añadir tarjeta informativa debajo del header: "💡 Sugerencia del coach"
  - [ ] Mostrar el texto de `swap_tip` con botón "Ver opciones" que abra el option bank del meal slot

### T-03 — Chips de `macro_focus` en Dashboard
- **Archivo:** `dashboard_page.dart`
- **Datos disponibles:** `macro_focus: list[str]` (ej: ["Alta proteína", "Carbos moderados"])
- **Qué hacer:**
  - [ ] Mostrar chips horizontales en la sección de resumen nutricional del dashboard
  - [ ] Color de chip basado en tipo (proteína = azul, carbos = ámbar, grasa = verde)

### T-04 — Análisis de foto: mostrar todos los campos de la IA
- **Archivo:** `nutrition_page.dart` (sección `_PhotoAnalysisResultSheet` o similar)
- **Datos disponibles:** `confidence_note`, `serving_hint`, `coach_note`, `ingredients`, `detected_items`
- **Qué hacer:**
  - [ ] Mostrar `serving_hint` debajo del nombre del plato (ej: "1 plato mediano ~350g")
  - [ ] Mostrar `confidence_note` con ícono de información (ej: "±15% de variación")
  - [ ] Mostrar `coach_note` como tarjeta verde del coach al final del resultado
  - [ ] Mostrar `ingredients` como lista separada de `detected_items`
  - [ ] Añadir botón "Ajustar macros" que permita editar valores antes de registrar

### T-05 — Warmup y Cooldown en sesión de workout
- **Archivo:** `workout_page.dart` y `workout_detail_sheet.dart`
- **Datos disponibles:** `warmup: list[str]`, `cooldown: list[str]` por `DailyWorkoutPlan`
- **Qué hacer:**
  - [ ] Añadir sección "Calentamiento" expandible antes de los bloques
  - [ ] Añadir sección "Vuelta a la calma" expandible después de los bloques
  - [ ] Cada ítem como chip o lista con ícono de fuego/agua

### T-06 — `adaptation_hint` como consejo del coach en workout
- **Archivo:** `workout_page.dart`
- **Datos disponibles:** `adaptation_hint: str` por sesión
- **Qué hacer:**
  - [ ] Tarjeta destacada al inicio de la sesión con ícono de coach
  - [ ] Fondo diferenciado (ej: teal oscuro) para que destaque
  - [ ] Texto: "Tu coach dice: [adaptation_hint]"

### T-07 — `intensity` visible en sesión de workout
- **Archivo:** `workout_page.dart`
- **Datos disponibles:** `intensity: str` (ej: "Moderada", "Alta", "Baja")
- **Qué hacer:**
  - [ ] Chip de intensidad junto al título de la sesión
  - [ ] Colores: rojo=Alta, ámbar=Moderada, verde=Baja

### T-08 — `best_for` y reasoning en detalle de comida
- **Archivo:** `nutrition_detail_sheet.dart`
- **Datos disponibles:** `best_for: str` (ej: "Post-entrenamiento, alta proteína")
- **Qué hacer:**
  - [ ] Añadir badge/chip "Ideal para:" al inicio del sheet
  - [ ] Tooltip o ExpansionTile "¿Por qué esta comida?" con el texto de `best_for`

---

## 🟡 Prioridad Media — Esfuerzo medio

### T-09 — Score de adherencia semanal en Dashboard
- **Archivo:** `dashboard_page.dart`
- **Datos disponibles:** `weekly_adherence: int`, `completed_sessions: int`, `workout_completion_rate: int`
- **Qué hacer:**
  - [ ] Fila de métricas debajo del header: "Adherencia X%", "X sesiones completadas"
  - [ ] `weekly_adherence` con ProgressIndicator circular pequeño
  - [ ] Color basado en valor: verde ≥80%, ámbar 50–79%, rojo <50%

### T-10 — Racha de días (`streak_days`) con motivación
- **Archivo:** `dashboard_page.dart`
- **Datos disponibles:** `streak_days: int`
- **Qué hacer:**
  - [ ] Badge de llama 🔥 con número de días en el header del dashboard
  - [ ] Mensaje motivacional según racha: 1–6 días, 7–13, 14–29, 30+
  - [ ] Animación suave al cargar

### T-11 — Panel de insights de la IA
- **Archivo:** `dashboard_page.dart`
- **Datos disponibles:** `insights: list[dict]` (insights accionables generados por la IA)
- **Qué hacer:**
  - [ ] Sección "Insights de tu coach" con cards deslizables (PageView horizontal)
  - [ ] Cada insight: ícono, título corto, texto, botón de acción opcional
  - [ ] Máximo 3 insights visibles, resto ocultos bajo "Ver más"

### T-12 — Tracking de macros acumulado del día en Nutrición
- **Archivo:** `nutrition_page.dart`
- **Qué hacer:**
  - [ ] Sumar macros de todas las comidas registradas en el día
  - [ ] Mostrar acumulado vs. meta en `_TodaySummaryCard` (ya existe la card)
  - [ ] Actualizar en tiempo real al registrar una comida sin recargar toda la página
  - [ ] Requiere: endpoint o cálculo client-side sumando `nutrition_logs` del día

### T-13 — Ajuste de macros detectados en análisis de foto
- **Archivo:** `nutrition_page.dart`
- **Qué hacer:**
  - [ ] En el resultado de análisis de foto, añadir botón "✏️ Ajustar"
  - [ ] Sheet con campos editables: calorías, proteínas, carbos, grasas
  - [ ] Al registrar, usar los valores ajustados en lugar de los de la IA

### T-14 — "¿Por qué esta comida?" en Nutrition Detail Sheet
- **Archivo:** `nutrition_detail_sheet.dart`
- **Qué hacer:**
  - [ ] ExpansionTile al final del sheet: "¿Por qué la IA recomienda esto?"
  - [ ] Mostrar `best_for`, macros vs. target del usuario, contexto de la franja horaria
  - [ ] Requiere: pasar `calorie_target` y `macro_focus` al sheet

### T-15 — `weight_trend` en Dashboard
- **Archivo:** `dashboard_page.dart`
- **Datos disponibles:** `weight_trend: str` ("subiendo", "bajando", "estable")
- **Qué hacer:**
  - [ ] Indicador visual junto al peso actual: ↑ rojo, ↓ verde, → gris
  - [ ] Mini texto: "Tendencia esta semana"

---

## 🟠 Prioridad Transformacional — Alto esfuerzo, gran impacto

### T-16 — Modo guiado de sesión de workout (paso a paso)
- **Archivos:** nuevo `workout_session_screen.dart`
- **Qué hacer:**
  - [ ] Pantalla dedicada que guía al usuario bloque por bloque
  - [ ] Pantalla de calentamiento → bloque 1 → bloque 2 → enfriamiento
  - [ ] Timer por ejercicio/descanso con vibración al terminar
  - [ ] Progreso visual (paso X de Y)
  - [ ] Al terminar: sheet de confirmación con resumen de la sesión

### T-17 — Dashboard de tendencias semanales
- **Archivos:** nuevo `progress_page.dart` o sección en dashboard
- **Qué hacer:**
  - [ ] Gráfico de adherencia nutricional por día (7 días)
  - [ ] Gráfico de sesiones de workout completadas
  - [ ] Gráfico de peso (si el usuario lo registra)
  - [ ] Usar `fl_chart` (ya disponible en pubspec) o similar
  - [ ] Datos: `/api/v1/activity/nutrition` y `/api/v1/activity/exercise-logs`

### T-18 — Notificaciones inteligentes basadas en el plan
- **Qué hacer:**
  - [ ] Recordatorio de comida según horario del plan (desayuno, almuerzo, cena)
  - [ ] Recordatorio de sesión de workout según días del plan
  - [ ] Mensaje motivacional basado en `adaptation_hint` del día
  - [ ] Requiere: fix del bug `exact_alarms_not_permitted` (ver T-19)

### T-19 — Fix: `exact_alarms_not_permitted` en Goals Settings
- **Archivo:** `goals_settings_page.dart:65`, `local_notification_service.dart:50`
- **Qué hacer:**
  - [ ] Verificar permisos antes de llamar `zonedSchedule`
  - [ ] Usar `canScheduleExactAlarms()` y pedir permiso si no está concedido
  - [ ] Fallback: usar `periodicallyShow` en lugar de exact alarm si no hay permiso

### T-20 — Lista de compras desde el plan nutricional
- **Archivos:** nuevo `shopping_list_page.dart`
- **Qué hacer:**
  - [ ] Agregar botón "🛒 Lista de compras" en la pestaña de nutrición
  - [ ] Consolidar `ingredients_with_quantities` de todas las comidas de la semana
  - [ ] Agrupar por categoría (proteínas, verduras, lácteos, etc.)
  - [ ] Checkboxes para marcar lo que ya se tiene
  - [ ] Compartir lista como texto plano

---

## Bugs pendientes a corregir

### B-01 — `TextEditingController` used after dispose
- **Archivo:** pendiente de identificar (error en log de workout/nutrition)
- Añadir `dispose()` correcto o verificar `mounted` antes de usarlo

### B-02 — `RenderFlex overflowed by 99594 pixels`
- **Causa:** algún Column sin `Expanded` o `Flexible` dentro de un scrollable
- Identificar el widget específico en el stack trace y agregar constraints

### B-03 — `_dependents.isEmpty` assertion en framework.dart
- Probablemente un `InheritedWidget` accedido después de dispose
- Revisar si algún Provider/Theme lookup ocurre en async callbacks

---

## Notas de arquitectura

- Todos los datos de IA ya llegan al cliente Flutter a través de la API — los gaps son 100% de UI, no de backend
- `macro_focus`, `warmup`, `cooldown`, `adaptation_hint`, `swap_tip`, `insights`, `streak_days` están en los modelos JSON pero nunca se parsean ni muestran
- El `_TodaySummaryCard` ya tiene la estructura correcta para T-01, solo necesita alimentar con datos reales del día
- Para T-12 (tracking acumulado), el endpoint `/api/v1/activity/nutrition` ya existe y devuelve logs del día
- Usar `fl_chart` para T-17 — ya está en `pubspec.yaml`
