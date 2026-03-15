# Mejoras Pendientes — Kineo Coach

> Generado: 2026-03-15
> Basado en: auditoría completa de todas las pantallas y widgets

---

## 🚨 Críticos — Rompen funcionalidad

### C-01 — WorkoutSessionScreen sin ruta nombrada
- **Problema:** La pantalla de sesión guiada se abre con `MaterialPageRoute` directo, no con ruta nombrada. Imposible navegar desde otras pantallas, notificaciones o deep links.
- **Archivos:** `workout_page.dart`, `app_router.dart`
- **Fix:**
  - [ ] Añadir ruta `/workout-session` en `app_router.dart`
  - [ ] Reemplazar `Navigator.push(MaterialPageRoute(...))` por `context.push('/workout-session', extra: workoutDay)`
  - [ ] Eliminar import directo de `workout_session_screen.dart` en `workout_page.dart`

### C-02 — Imagen de perfil no se sube al backend
- **Problema:** El usuario puede seleccionar foto de perfil (cámara/galería) pero `_profileImagePath` nunca se envía al backend. La foto se pierde al reiniciar.
- **Archivos:** `dashboard_page.dart`, `profile_api_service.dart` (si existe)
- **Fix:**
  - [ ] Crear o usar endpoint `PATCH /api/v1/users/me/avatar` (multipart)
  - [ ] Hacer upload al backend después de seleccionar imagen
  - [ ] Mostrar indicador de carga durante el upload
  - [ ] Guardar URL devuelta por el backend y mostrarla en el header

### C-03 — Stream de plan generation sin cancelar
- **Problema:** Al salir de `PlanGenerationPage`, el stream SSE sigue activo. Si el usuario navega hacia atrás, el stream corre en background indefinidamente.
- **Archivo:** `plan_generation_page.dart`
- **Fix:**
  - [ ] Añadir `StreamSubscription` y cancelarla en `dispose()`
  - [ ] Añadir timeout de 120s: si no llega `done` event, mostrar error con retry

### C-04 — Timer de WorkoutSession sigue corriendo al navegar
- **Problema:** El timer de cuenta regresiva de la sesión sigue corriendo si el usuario sale de la pantalla (minimiza app, cambia de pestaña, etc.).
- **Archivo:** `workout_session_screen.dart`
- **Fix:**
  - [ ] Pausar timer en `didChangeAppLifecycleState(paused)`
  - [ ] Añadir diálogo "¿Salir de la sesión?" al presionar back con sesión activa
  - [ ] Reanudar timer en `resumed`

### C-05 — Validación de argumentos de ruta sin tipo
- **Problema:** `/shopping-list` y `/workout-mode` reciben argumentos como `dynamic` y hacen cast sin validar. Si la estructura cambia, crash silencioso.
- **Archivo:** `app_router.dart`
- **Fix:**
  - [ ] Definir clases de argumentos tipadas (`ShoppingListArgs`, `WorkoutModeArgs`)
  - [ ] Validar en el builder y mostrar error claro si estructura incorrecta

---

## 🔴 Alta prioridad — Design system y consistencia visual

### D-01 — Colores hardcodeados en toda la app
- **Problema:** Más de 20 colores hex distintos (`Color(0xFF143C3A)`, `Color(0xFFD6EEE6)`, `Color(0xFFE8F4EE)`, etc.) dispersos en todos los archivos. Cambiar el color principal requiere editar 15+ archivos.
- **Archivos:** Todos
- **Fix:**
  - [ ] Crear `lib/core/theme/app_colors.dart`:
    ```dart
    class AppColors {
      static const primary = Color(0xFF143C3A);
      static const primaryLight = Color(0xFFD6EEE6);
      static const surface = Color(0xFFF5F0E6);
      static const surfaceAlt = Color(0xFFF1ECE3);
      static const accent = Color(0xFF2E7D52);
      // ... etc
    }
    ```
  - [ ] Reemplazar todos los `Color(0xFF...)` por `AppColors.X`
  - [ ] Crear constantes para gradientes frecuentes

### D-02 — Espaciado sin sistema de tokens
- **Problema:** `SizedBox(height: 8)`, `SizedBox(height: 12)`, `SizedBox(height: 16)`, `SizedBox(height: 20)` sin patrón. Algunos usan `EdgeInsets` directos.
- **Fix:**
  - [ ] Crear `lib/core/theme/app_spacing.dart`:
    ```dart
    class Spacing {
      static const xs = 4.0;
      static const sm = 8.0;
      static const md = 16.0;
      static const lg = 24.0;
      static const xl = 32.0;
    }
    ```
  - [ ] Aplicar sistemáticamente en los archivos más grandes primero (dashboard, nutrition, workout)

### D-03 — Archivos masivos ilegibles
- **Problema:** `dashboard_page.dart` (~2000 líneas) y `nutrition_page.dart` (~2500 líneas) con widgets anidados, sheets, helpers y modelos mezclados. Inmantenibles.
- **Fix — dashboard_page.dart:**
  - [ ] Extraer `_AdherenceMetricsRow` → `widgets/adherence_metrics_row.dart`
  - [ ] Extraer `_StreakBadge` → `widgets/streak_badge.dart`
  - [ ] Extraer `_InsightsPanel` → `widgets/insights_panel.dart`
  - [ ] Extraer sheets de "Ruta de hoy" → `widgets/today_route_sheet.dart`
  - [ ] Extraer `_CoachReportSheet` → `widgets/coach_report_sheet.dart`
- **Fix — nutrition_page.dart:**
  - [ ] Extraer `_TodaySummaryCard` → `widgets/today_summary_card.dart`
  - [ ] Extraer flujo de análisis de foto → `widgets/photo_analysis_flow.dart`
  - [ ] Extraer `_ManualRegistrationSheet` → `widgets/manual_registration_sheet.dart`
  - [ ] Extraer `_OptionBankSheet` → `widgets/option_bank_sheet.dart`
  - [ ] Extraer `_MealTimelineCard` → `widgets/meal_timeline_card.dart`

### D-04 — Empty states faltantes
- **Problema:** Si el usuario no tiene plan, historial, actividad o progreso, la mayoría de pantallas muestran espacio en blanco o errores silenciosos.
- **Pantallas afectadas:** dashboard, workout, nutrition, progress, shopping list
- **Fix:**
  - [ ] Crear widget reutilizable `EmptyStateWidget(icon, title, subtitle, [actionLabel, onAction])`
  - [ ] Dashboard sin plan → "Aún no tienes plan. Pulsa 'Mi Plan' para crear uno"
  - [ ] Workout sin sesión → "No hay entrenamiento programado para hoy"
  - [ ] Nutrition sin registros → "No has registrado comidas hoy"
  - [ ] Progress sin datos → "Registra tu peso para ver tu progreso"
  - [ ] Shopping list sin ingredientes → "Tu plan no tiene ingredientes definidos aún"

### D-05 — Estados de carga inconsistentes
- **Problema:** Algunas pantallas usan shimmer, otras `CircularProgressIndicator`, otras nada. Sin patrón.
- **Fix:**
  - [ ] Definir regla: shimmer solo para listas/cards de contenido; spinner para acciones puntuales (submit, upload)
  - [ ] Shimmer en workout blocks, meal timeline, insights panel
  - [ ] Spinner + overlay en: submit registro, upload foto, generación de plan
  - [ ] Añadir `ShimmerBox` en progress_page mientras cargan los gráficos

---

## 🟡 Media prioridad — UX y funcionalidad incompleta

### U-01 — Flujos de registro de workout confusos
- **Problema:** El usuario ve 3 opciones: "Sesión adaptativa", "Sesión guiada" y "Registro manual" sin saber cuándo usar cada una.
- **Fix:**
  - [ ] Cambiar nombres: "Registrar sesión rápida" / "Modo entrenamiento paso a paso" / "Registrar manualmente"
  - [ ] Añadir subtítulo descriptivo debajo de cada opción en la selección
  - [ ] Hacer que "Modo entrenamiento" sea el CTA principal (botón grande) y las otras opciones secundarias

### U-02 — Sesión guiada: UX del timer
- **Problema:** El timer muestra número contando pero sin indicación visual de progreso (no hay arco/círculo animado). El botón pause/play no tiene estado claro.
- **Fix:**
  - [ ] Reemplazar número plano por `CircularProgressIndicator` grande con tiempo en el centro
  - [ ] Botón pause: icono cambia a play/pause claramente; fondo cambia de color
  - [ ] Añadir vibración a los últimos 3 segundos (ya hay `HapticFeedback`, extender)
  - [ ] Mostrar nombre del ejercicio actual en grande, no solo el bloque

### U-03 — Historial de nutrición sin agrupación por fecha
- **Problema:** Los logs de nutrición se muestran como lista plana sin separadores de fecha. Para ver qué comí ayer tengo que hacer scroll sin saber dónde empieza.
- **Fix:**
  - [ ] Añadir separadores `_DateHeader` entre grupos de días en la lista de historial
  - [ ] Mostrar resumen diario junto al separador: "Lunes 10 mar — 1840 kcal"
  - [ ] Swipe-to-delete ya implementado; asegurar que refresca el resumen del día

### U-04 — Formulario de registro manual de nutrición desordenado
- **Problema:** Todos los campos (nombre, calorías, proteínas, carbos, grasas, hidratación, adherencia, notas) están en columna sin agrupación visual.
- **Fix:**
  - [ ] Sección 1 — "Información básica": nombre del plato + franja horaria
  - [ ] Sección 2 — "Macronutrientes": calorías + proteínas + carbos + grasas en grid 2×2
  - [ ] Sección 3 — "Extras": hidratación + notas
  - [ ] Slider de adherencia con etiquetas: Malo / Regular / Bueno / Excelente

### U-05 — Confirmación en acciones destructivas
- **Problema:** No hay diálogo de confirmación al: finalizar sesión de workout (perder progreso), eliminar registro de nutrición, salir del plan en generación.
- **Fix:**
  - [ ] Diálogo "¿Finalizar sesión?" con resumen de lo completado antes de cerrar `WorkoutSessionScreen`
  - [ ] Diálogo "¿Eliminar este registro?" en swipe-to-delete de nutrition
  - [ ] Diálogo "¿Cancelar generación?" al presionar back en `PlanGenerationPage`

### U-06 — Shopping list: persistir estado de marcados
- **Problema:** Al salir y volver a la lista de compras, todos los checkboxes se resetean. El usuario pierde su progreso de compras.
- **Fix:**
  - [ ] Usar `SharedPreferences` para guardar los ítems marcados (clave: `shopping_checked_items`)
  - [ ] Limpiar automáticamente si el plan cambia (comparar fecha del plan)
  - [ ] Botón "Limpiar marcados" en AppBar

### U-07 — Sin feedback visual al enviar formularios
- **Problema:** Al pulsar "Guardar" o "Registrar", el botón no cambia de estado. El usuario no sabe si su acción fue procesada.
- **Afecta:** registro de nutrición, registro de workout, guardar ajustes, subir foto
- **Fix:**
  - [ ] Mientras `_isSubmitting == true`: botón deshabilitado + spinner pequeño dentro del botón
  - [ ] Al completar: animación de check verde + auto-cerrar sheet tras 800ms
  - [ ] Al error: botón vuelve a estado normal + SnackBar rojo con mensaje

### U-08 — Plan generation: timeout y recuperación
- **Problema:** Si la IA tarda >90s o hay error de red, el spinner corre indefinidamente.
- **Fix:**
  - [ ] Timeout explícito de 90s con mensaje "La generación está tardando más de lo esperado. ¿Reintentar?"
  - [ ] Si ya existe un plan, mostrar opción "Usar plan anterior"
  - [ ] Guardar estado parcial en `SharedPreferences` por si se cierra la app

### U-09 — Progress page: 10 controladores, solo 2 se usan
- **Problema:** Se crean `TextEditingController` para peso, cintura, cadera, pecho, etc. pero al guardar solo se envía peso y cintura. El resto se descarta.
- **Fix:**
  - [ ] Implementar submit completo de todas las medidas corporales al endpoint correspondiente
  - [ ] O eliminar los campos que no se usan para reducir confusión
  - [ ] Añadir validación: campos numéricos aceptan solo números, no texto libre

### U-10 — Insights del dashboard no tienen acciones
- **Problema:** El panel de insights muestra cards con texto pero el botón "Ver" no está conectado a ninguna pantalla.
- **Fix:**
  - [ ] Si insight es de tipo workout → navega a pestaña workout
  - [ ] Si insight es de nutrición → navega a pestaña nutrición
  - [ ] Si insight es de progreso → navega a `/progress`
  - [ ] Si no hay acción clara, ocultar el botón

---

## 🟢 Mejoras de calidad de código

### Q-01 — Crear archivos de utilidades compartidas
- [ ] `lib/core/utils/formatters.dart`: `formatTime(seconds)`, `formatDate(date)`, `formatMacro(value)`
- [ ] `lib/core/utils/validators.dart`: validación de números, campos requeridos
- [ ] `lib/core/utils/safe_cast.dart`: `toDouble(dynamic)`, `toInt(dynamic)`, `toStringList(dynamic)`

### Q-02 — Estandarizar manejo de errores de API
- **Problema:** Cada pantalla maneja errores de forma diferente. Algunas ignoran, otras muestran en rojo, otras fallan silenciosamente.
- [ ] Crear `ApiError` con `message`, `statusCode`, `isNetworkError`
- [ ] Crear `ErrorBanner` widget reutilizable con retry
- [ ] Aplicar en: dashboard, workout, nutrition, progress

### Q-03 — Eliminar código muerto
- [ ] `progress_page.dart`: eliminar los 8 TextEditingControllers que no se envían
- [ ] `workout_page.dart`: revisar si `_WorkoutRegistrationPage` está definida ahí y extraerla
- [ ] `nutrition_page.dart`: verificar si el análisis de foto está duplicado en algún path

### Q-04 — Mejorar seguridad de tipos en navegación
- [ ] Crear `AppRoutes` con constantes: `static const workout = '/workout-session'`
- [ ] Eliminar strings de rutas dispersos en el código
- [ ] Usar `go_router`'s `extra` con tipos seguros

### Q-05 — Dispose correcto en stateful widgets
- [ ] `WorkoutSessionScreen`: cancelar timer en dispose
- [ ] `PlanGenerationPage`: cancelar stream en dispose
- [ ] `NutritionPage`: cancelar Timer del shimmer en dispose
- [ ] Auditar todos los `AnimationController` tienen `dispose()`

---

## 📊 Funcionalidades nuevas sugeridas

### F-01 — Modo offline básico
- Mostrar datos en caché si no hay red (en lugar de error)
- Indicador sutil "Sin conexión — datos desde caché" en el header
- Cola de registros para sincronizar al reconectar (ya existe `offline_activity_queue_service.dart`)

### F-02 — Onboarding de nuevas funcionalidades
- Tooltip/overlay de primer uso para: análisis de foto, sesión guiada, lista de compras
- Usar `SharedPreferences` para marcar si el feature fue mostrado

### F-03 — Compartir progreso
- En `progress_page.dart`, botón "📤 Compartir" genera una imagen/card con las métricas del usuario
- Formato: nombre, foto, peso actual, adherencia semanal, días de racha

### F-04 — Historial de sesiones de entrenamiento
- En workout, sección "Últimas sesiones" con fecha, duración, bloques completados
- Tocar una sesión pasada muestra el detalle

### F-05 — Widget de resumen semanal en dashboard
- Card que muestra la semana en curso: días con workout ✓, días con nutrición ✓, días sin actividad ○
- 7 iconos/círculos de lunes a domingo con color

---

## 🐛 Bugs conocidos aún pendientes

### B-01 — TextEditingController used after dispose
- **Archivos:** identificar origen exacto (probablemente workout o nutrition)
- [ ] Auditar todos los controllers en formularios con `mounted` check

### B-02 — RenderFlex overflow en pantallas pequeñas
- [ ] Identificar Column/Row sin `Expanded`/`Flexible` en dialogs y sheets
- [ ] Añadir `overflow: TextOverflow.ellipsis` a textos largos en chips

### B-03 — `_dependents.isEmpty` assertion
- [ ] Identificar Provider/Theme lookup en async callbacks
- [ ] Añadir `if (!mounted) return` antes de `setState` en async

### B-04 — Tiempo de primer render ~1200ms (Davey)
- [ ] Mover carga inicial de dashboard a splash screen o init route
- [ ] Usar `RepaintBoundary` en secciones complejas del dashboard
- [ ] Considerar `const` constructors en widgets pesados

---

## Priorización recomendada para próxima sesión

```
Sprint 1 (críticos + design system):
  C-01, C-03, C-04, D-01, D-04, D-05

Sprint 2 (UX funcional):
  U-01, U-02, U-05, U-07, U-08, C-02

Sprint 3 (calidad + features):
  D-03, Q-01, Q-02, Q-05, F-05, U-03
```
