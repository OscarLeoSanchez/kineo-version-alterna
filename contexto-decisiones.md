# Contexto de Decisiones

## 1. Arquitectura separada Flutter + FastAPI
- Que: se separo la app movil del backend.
- Como: `mobile/flutter_app` para Flutter y `backend/api` para FastAPI.
- Porque: facilita escalar, probar y desplegar por capas.
- Aprendido: separar desde temprano evita mezclar UI con logica de negocio.
- Mejora posible: agregar contrato OpenAPI documentado y cliente tipado compartido.

## 2. Docker como entorno local principal
- Que: backend y base de datos corren en contenedores.
- Como: `docker-compose.yml` con `api` y `postgres`.
- Porque: da consistencia local y evita depender de instalaciones manuales.
- Aprendido: acelera pruebas reales de red y estado.
- Mejora posible: agregar perfiles por entorno y volcado inicial de datos demo.

## 3. Autenticacion propia con JWT
- Que: se implemento registro, login y sesion propia.
- Como: FastAPI + JWT + hash de password, y sesion local en Flutter.
- Porque: permitia avanzar rapido sin depender de un tercero.
- Aprendido: fue util para iterar flujo completo temprano.
- Mejora posible: migrar luego a auth social o proveedor externo si se requiere.

## 4. Preferencias persistidas por usuario
- Que: estilo de coach, unidades, prioridad diaria y profundidad quedaron guardados por usuario.
- Como: tabla `user_preferences` y sincronizacion app-backend.
- Porque: la personalizacion debia sobrevivir entre sesiones y dispositivos.
- Aprendido: guardar esto en backend fue mejor que depender de headers o cache local.
- Mejora posible: versionar preferencias y agregar auditoria de cambios.

## 5. App sin planes comerciales visibles
- Que: se elimino lenguaje de `Pro`, `Trial` y upsell.
- Como: refactor visual y semantico en frontend y backend.
- Porque: el objetivo actual es construir experiencia completa sin restricciones artificiales.
- Aprendido: el lenguaje comercial estaba contaminando decisiones de producto.
- Mejora posible: renombrar internamente los ultimos restos de conceptos heredados si aun aparecen.

## 6. Navegacion principal con `PageView`
- Que: la navegacion entre tabs paso a `PageView`.
- Como: `PageController` en el shell principal.
- Porque: el enfoque anterior provocaba errores de widgets dependientes y no soportaba gesto lateral bien.
- Aprendido: para tabs persistentes, `PageView` fue mas estable que overlays conmutados.
- Mejora posible: agregar preservacion fina de scroll y transiciones mas pulidas por seccion.

## 7. Flujos guiados en vez de pantallas solo informativas
- Que: workout, nutricion y progreso pasaron a tener acciones guiadas.
- Como: formularios, detalles por bloque/comida y registros mas claros.
- Porque: la app era visualmente aceptable pero poco util.
- Aprendido: el usuario necesitaba hacer cosas, no solo leer tarjetas.
- Mejora posible: seguir reduciendo friccion con registros aun mas cortos y contextuales.

## 8. `Registrar sesion` como pantalla propia
- Que: el cierre de sesion de workout dejo de usar un bottom sheet complejo.
- Como: se movio a una pantalla/modal propia navegable.
- Porque: el bottom sheet estaba causando asserts al volver en Android.
- Aprendido: no todo flujo largo cabe bien en un sheet.
- Mejora posible: reutilizar este mismo patron en nutricion si aparece friccion similar.

## 9. Onboarding enriquecido
- Que: el onboarding ahora pide mucho mas contexto real.
- Como: se agregaron datos de entrenamiento, cocina, comidas, alergias, disgustos, medidas opcionales y notas libres.
- Porque: sin contexto suficiente no era posible personalizar de verdad.
- Aprendido: el plan mejora mucho cuando el usuario puede explicar su realidad.
- Mejora posible: dividirlo en secciones aun mas cortas y guardar progreso parcial.

## 10. Persistencia de medidas y contexto adicional
- Que: el perfil guarda medidas corporales opcionales y notas adicionales.
- Como: nuevos campos en `user_profiles` y migracion ligera en bootstrap.
- Porque: hacia falta material real para personalizar rutinas y alimentacion.
- Aprendido: las medidas deben ser opcionales para no bloquear onboarding.
- Mejora posible: normalizar medidas historicas y permitir comparativas por fecha.

## 11. Plan estructurado persistido como payload
- Que: el plan inicial ahora guarda un payload estructurado completo.
- Como: columna `plan_payload` en `initial_plans`.
- Porque: el resumen textual no alcanzaba para una app realmente util.
- Aprendido: persistir estructura evita recalcular y permite UI mucho mas rica.
- Mejora posible: versionar el esquema del payload para migraciones futuras.

## 12. Capa de IA desacoplada del proveedor
- Que: se creo un planner desacoplado del proveedor de IA.
- Como: `AIPlanningProvider`, proveedor OpenAI y provider deterministico.
- Porque: se queria cambiar modelo/proveedor por variables de entorno sin reescribir logica.
- Aprendido: desacoplar antes de integrar evita dependencia dura con un SDK concreto.
- Mejora posible: agregar soporte formal para otro proveedor y pruebas de contrato.

## 13. OpenAI por entorno, no acoplado en codigo
- Que: proveedor, modelo y key se leen por entorno.
- Como: variables `AI_PROVIDER`, `AI_MODEL`, `AI_API_KEY`, `AI_BASE_URL`, `AI_ENABLE_LIVE_GENERATION`.
- Porque: permite cambiar configuracion sin tocar codigo.
- Aprendido: la configuracion vacia o incorrecta rompe rapido si no se normaliza.
- Mejora posible: validar configuracion al arranque y exponer healthcheck de IA.

## 14. Fallback deterministico cuando la IA falla
- Que: si la IA externa falla, el sistema genera un plan local util.
- Como: `PlanService` captura excepciones y cae a `DeterministicPlanningProvider`.
- Porque: el onboarding no puede romperse por una dependencia externa.
- Aprendido: el fallback no es opcional cuando la IA esta en una ruta critica.
- Mejora posible: registrar trazas y motivos del fallback en una tabla o sistema de monitoreo.

## 15. Nutricion semanal por comida con 10 opciones
- Que: cada comida ahora puede mostrar semana completa y banco de 10 opciones.
- Como: el payload del plan trae `meal_slots`, `weekly_plan` y `option_bank`.
- Porque: el usuario pidio detalle real y variedad usable.
- Aprendido: la comida debe verse como plan accionable, no como sugerencia vaga.
- Mejora posible: permitir marcar favoritas, reemplazos usados y generacion regenerativa por comida.

## 16. Desarrollo validado constantemente con pruebas
- Que: se mantuvo validacion continua con `flutter analyze`, `flutter test` y `pytest`.
- Como: cada bloque importante se cerro con pruebas antes de instalar.
- Porque: habia muchos cambios sobre una base viva y era facil romper flujos.
- Aprendido: las pruebas evitaron regresiones repetidas.
- Mejora posible: agregar pruebas E2E de app y tests de snapshot para payload IA.
