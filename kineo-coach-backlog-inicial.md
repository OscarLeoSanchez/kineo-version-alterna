# Backlog Inicial de Producto

## 1. Información General

### Producto
Kineo Coach

### Fecha
11 de marzo de 2026

### Propósito
Este documento organiza el backlog inicial del producto en épicas, historias de usuario, prioridades y criterios de aceptación de alto nivel para facilitar planeación, estimación y ejecución del MVP.

## 2. Escala de Prioridad

- P0: Imprescindible para lanzar MVP.
- P1: Muy importante para la propuesta de valor inicial.
- P2: Valioso, pero puede salir después del lanzamiento inicial.

## 3. Épicas del MVP

- EP-01 Autenticación y acceso.
- EP-02 Onboarding y perfil del usuario.
- EP-03 Motor de personalización.
- EP-04 Dashboard diario.
- EP-05 Entrenamiento guiado.
- EP-06 Función SOS y ajustes en sesión.
- EP-07 Nutrición integrada.
- EP-08 Progreso y adherencia.
- EP-09 Notificaciones y reactivación.
- EP-10 Suscripción y monetización.
- EP-11 Plataforma técnica, analítica y calidad.

## 4. Backlog por Épica

### EP-01 Autenticación y acceso

#### HU-001 Registro con email
Como usuario nuevo, quiero registrarme con correo y contraseña para crear mi cuenta y comenzar a usar la app.

Prioridad: P0

Criterios de aceptación:

- El usuario puede crear cuenta con correo válido y contraseña.
- El sistema valida errores comunes de formato.
- El usuario recibe confirmación de registro exitoso.

#### HU-002 Inicio de sesión
Como usuario registrado, quiero iniciar sesión para acceder a mi información y plan personalizado.

Prioridad: P0

Criterios de aceptación:

- El usuario puede autenticarse con credenciales válidas.
- El sistema muestra mensajes claros ante error.
- La sesión persiste de forma segura.

#### HU-003 Recuperación de contraseña
Como usuario, quiero recuperar mi contraseña para volver a entrar si la olvidé.

Prioridad: P1

Criterios de aceptación:

- El usuario puede solicitar restablecimiento.
- El sistema informa que el proceso fue iniciado.

#### HU-004 Login social
Como usuario, quiero iniciar sesión con Google o Apple para registrarme más rápido.

Prioridad: P1

Criterios de aceptación:

- El login social funciona según la plataforma.
- La cuenta queda asociada correctamente al usuario interno.

### EP-02 Onboarding y perfil del usuario

#### HU-005 Onboarding guiado
Como usuario nuevo, quiero un flujo guiado para contar mis objetivos y contexto sin sentir que lleno un formulario complejo.

Prioridad: P0

Criterios de aceptación:

- El flujo es paso a paso.
- Los campos obligatorios quedan claros.
- El usuario puede avanzar y retroceder sin perder progreso.

#### HU-006 Captura de datos físicos y objetivos
Como usuario, quiero registrar mi peso, estatura, meta y nivel de experiencia para recibir un plan relevante.

Prioridad: P0

Criterios de aceptación:

- Se capturan datos mínimos para generar el plan.
- El sistema valida rangos razonables.

#### HU-007 Captura de disponibilidad y equipamiento
Como usuario, quiero informar tiempo disponible, días de entrenamiento y equipo con el que cuento para que la rutina se ajuste a mi realidad.

Prioridad: P0

Criterios de aceptación:

- El usuario puede seleccionar frecuencia, duración y lugar.
- El sistema guarda el inventario básico de equipamiento.

#### HU-008 Captura de restricciones y preferencias
Como usuario, quiero declarar molestias, lesiones previas, restricciones alimentarias y preferencias para recibir recomendaciones seguras y útiles.

Prioridad: P0

Criterios de aceptación:

- El usuario puede registrar restricciones físicas y alimentarias.
- El sistema usa esta información en la personalización.

#### HU-009 Edición de perfil
Como usuario, quiero editar mi perfil después del onboarding para mantener mis datos actualizados.

Prioridad: P1

Criterios de aceptación:

- El usuario puede modificar información clave.
- El sistema recalcula o marca necesidad de recalcular el plan cuando aplique.

### EP-03 Motor de personalización

#### HU-010 Generación del plan inicial
Como usuario, quiero recibir un plan inicial de entrenamiento al terminar el onboarding para empezar de inmediato.

Prioridad: P0

Criterios de aceptación:

- El sistema genera un plan coherente con objetivo, experiencia y disponibilidad.
- El plan queda visible al finalizar el onboarding.

#### HU-011 Recomendación nutricional inicial
Como usuario, quiero recibir lineamientos o sugerencias nutricionales básicas para acompañar mi objetivo.

Prioridad: P0

Criterios de aceptación:

- El sistema entrega recomendaciones consistentes con objetivo y restricciones.
- El usuario puede consultar estas recomendaciones desde la app.

#### HU-012 Ajuste por tiempo disponible
Como usuario, quiero indicar que hoy tengo menos tiempo para recibir una versión adaptada de mi entrenamiento.

Prioridad: P1

Criterios de aceptación:

- El sistema recibe el nuevo tiempo disponible.
- La rutina se ajusta conservando intención de entrenamiento.

#### HU-013 Ajuste por energía o fatiga
Como usuario, quiero indicar cómo me siento hoy para que la intensidad del plan sea más realista.

Prioridad: P1

Criterios de aceptación:

- El usuario puede reportar energía o fatiga.
- El sistema adapta la recomendación del día.

### EP-04 Dashboard diario

#### HU-014 Ver resumen del día
Como usuario, quiero abrir la app y ver rápidamente qué me corresponde hoy para actuar sin pensar demasiado.

Prioridad: P0

Criterios de aceptación:

- El dashboard muestra acción principal del día.
- También muestra progreso resumido y estado general.

#### HU-015 Ver mensajes contextuales
Como usuario, quiero ver sugerencias según el momento del día para sentir acompañamiento útil.

Prioridad: P1

Criterios de aceptación:

- El contenido cambia según contexto horario o estado del usuario.
- Los mensajes no bloquean acciones principales.

### EP-05 Entrenamiento guiado

#### HU-016 Iniciar rutina diaria
Como usuario, quiero iniciar mi rutina desde el dashboard para entrenar sin fricción.

Prioridad: P0

Criterios de aceptación:

- El botón de inicio es visible.
- La app abre la sesión de entrenamiento correspondiente al día.

#### HU-017 Ver detalle de ejercicios
Como usuario, quiero ver instrucciones y datos clave de cada ejercicio para ejecutarlo correctamente.

Prioridad: P0

Criterios de aceptación:

- Cada ejercicio muestra nombre, series, repeticiones y material.
- La vista presenta indicaciones de ejecución básicas.

#### HU-018 Registrar desempeño
Como usuario, quiero registrar repeticiones, peso o duración para llevar seguimiento real de mi entrenamiento.

Prioridad: P0

Criterios de aceptación:

- El usuario puede guardar datos por ejercicio.
- La sesión conserva el progreso registrado.

#### HU-019 Usar temporizadores
Como usuario, quiero contar descansos y tiempos para llevar el ritmo de la sesión.

Prioridad: P1

Criterios de aceptación:

- El usuario puede iniciar y detener temporizadores.
- El estado del temporizador no se pierde durante la sesión.

#### HU-020 Finalizar entrenamiento
Como usuario, quiero terminar mi sesión y ver un resumen para sentir cierre y avance.

Prioridad: P0

Criterios de aceptación:

- El sistema marca la sesión como completada.
- El usuario visualiza un resumen básico del trabajo realizado.

### EP-06 Función SOS y ajustes en sesión

#### HU-021 Reportar dolor o molestia
Como usuario, quiero indicar que un ejercicio me molesta para recibir una alternativa más segura.

Prioridad: P0

Criterios de aceptación:

- El usuario puede activar la función SOS desde el ejercicio actual.
- El sistema ofrece al menos una alternativa válida.

#### HU-022 Reportar equipo no disponible
Como usuario, quiero indicar que la máquina o implemento no está disponible para no detener mi entrenamiento.

Prioridad: P0

Criterios de aceptación:

- El usuario puede elegir la razón del cambio.
- El sistema propone sustitución acorde al contexto.

#### HU-023 Registrar motivo de sustitución
Como equipo de producto, queremos guardar la razón de sustitución para mejorar la personalización futura.

Prioridad: P1

Criterios de aceptación:

- El motivo queda almacenado.
- Puede consultarse a nivel analítico.

### EP-07 Nutrición integrada

#### HU-024 Ver recomendaciones nutricionales
Como usuario, quiero ver recomendaciones o comidas sugeridas para acompañar mi plan.

Prioridad: P0

Criterios de aceptación:

- Las recomendaciones son visibles desde la app.
- Están alineadas con el objetivo principal.

#### HU-025 Reemplazar una comida sugerida
Como usuario, quiero cambiar una comida que no me gusta por otra equivalente para mantener adherencia.

Prioridad: P1

Criterios de aceptación:

- El usuario puede pedir alternativa.
- El sistema ofrece una opción consistente con restricciones y objetivo.

#### HU-026 Ver lista de compras
Como usuario, quiero consultar una lista de compras básica para organizar mejor mi alimentación.

Prioridad: P2

Criterios de aceptación:

- La lista agrupa ingredientes requeridos.
- Se genera desde las sugerencias visibles para el usuario.

### EP-08 Progreso y adherencia

#### HU-027 Registrar peso y medidas
Como usuario, quiero registrar mi peso y medidas para saber si estoy avanzando.

Prioridad: P0

Criterios de aceptación:

- El usuario puede guardar mediciones manualmente.
- El historial queda disponible para consulta.

#### HU-028 Ver evolución de progreso
Como usuario, quiero visualizar mis avances para mantener motivación.

Prioridad: P1

Criterios de aceptación:

- La app muestra evolución básica de peso, entrenamientos y consistencia.
- La información es entendible para usuarios no técnicos.

#### HU-029 Ver rachas y cumplimiento
Como usuario, quiero ver mi consistencia semanal para sentir progreso más allá del peso corporal.

Prioridad: P1

Criterios de aceptación:

- El sistema muestra entrenamientos completados por periodo.
- Puede resaltar hitos o rachas simples.

### EP-09 Notificaciones y reactivación

#### HU-030 Recordatorio de entrenamiento
Como usuario, quiero recibir recordatorios de mi sesión para no olvidarla.

Prioridad: P1

Criterios de aceptación:

- El sistema envía notificaciones en horarios configurables.
- El usuario puede activarlas o desactivarlas.

#### HU-031 Recordatorio de hábitos básicos
Como usuario, quiero recibir recordatorios simples de hidratación o seguimiento para mantener consistencia.

Prioridad: P2

Criterios de aceptación:

- Los recordatorios pueden activarse opcionalmente.
- No saturan al usuario con frecuencia excesiva.

#### HU-032 Reactivación por inactividad
Como equipo de producto, queremos enviar mensajes cuando el usuario disminuye su uso para recuperar adherencia.

Prioridad: P2

Criterios de aceptación:

- El sistema detecta periodos básicos de inactividad.
- Puede disparar comunicación simple de reenganche.

### EP-10 Suscripción y monetización

#### HU-033 Ver beneficios de premium
Como usuario free, quiero entender claramente qué gano al pasar a premium.

Prioridad: P0

Criterios de aceptación:

- El paywall presenta beneficios claros.
- El usuario entiende qué funciones están bloqueadas.

#### HU-034 Comprar suscripción
Como usuario, quiero poder suscribirme fácilmente desde la app.

Prioridad: P0

Criterios de aceptación:

- El flujo de compra funciona en la plataforma correspondiente.
- El estado premium se refleja tras la compra.

#### HU-035 Restaurar compra
Como usuario premium, quiero restaurar mi suscripción si cambio de dispositivo o reinstalo la app.

Prioridad: P1

Criterios de aceptación:

- El usuario puede restaurar acceso según la tienda.
- El sistema sincroniza correctamente el estado de la cuenta.

### EP-11 Plataforma técnica, analítica y calidad

#### HU-036 Instrumentar eventos clave
Como equipo de producto, queremos medir onboarding, uso y conversión para tomar decisiones basadas en datos.

Prioridad: P0

Criterios de aceptación:

- Se registran eventos clave del funnel.
- Los eventos permiten análisis por cohorte básica.

#### HU-037 Manejo de errores y crash reporting
Como equipo técnico, queremos rastrear fallos para mantener estabilidad del producto.

Prioridad: P0

Criterios de aceptación:

- Los errores críticos quedan registrados.
- Los fallos pueden agruparse por entorno y versión.

#### HU-038 Configuración modular del proyecto
Como equipo de desarrollo, queremos una arquitectura ordenada por features para escalar el producto sin degradar mantenibilidad.

Prioridad: P0

Criterios de aceptación:

- El proyecto sigue una estructura modular.
- La lógica de negocio no depende directamente de la UI.

#### HU-039 Validación de recomendaciones
Como equipo técnico, queremos validar las salidas del motor antes de mostrarlas al usuario para reducir errores graves.

Prioridad: P0

Criterios de aceptación:

- Existen reglas mínimas de validación.
- Recomendaciones incompatibles con restricciones no se publican.

## 5. Priorización Recomendada para Primer Release

### Release 1

- HU-001 a HU-008
- HU-010
- HU-011
- HU-014
- HU-016 a HU-018
- HU-020
- HU-021
- HU-022
- HU-024
- HU-027
- HU-033
- HU-034
- HU-036 a HU-039

### Release 1.1

- HU-009
- HU-012
- HU-013
- HU-015
- HU-019
- HU-023
- HU-025
- HU-028
- HU-029
- HU-030
- HU-035

### Release 1.2

- HU-003
- HU-004
- HU-026
- HU-031
- HU-032

## 6. Dependencias del Backlog

- El onboarding depende de autenticación estable.
- El dashboard depende de que exista un plan generado.
- El modo entrenamiento depende del catálogo mínimo de ejercicios.
- La función SOS depende de reglas de sustitución y alternativas válidas.
- La monetización depende de definición clara de features premium.
- La analítica debe implementarse desde las primeras historias del MVP.

## 7. Definición de Terminado Recomendada

Una historia se considera terminada cuando:

- Cumple sus criterios de aceptación.
- Tiene validación funcional básica.
- Maneja estados de carga, error y vacío cuando aplique.
- Incluye instrumentación analítica si corresponde.
- No rompe restricciones declaradas por el usuario.
- Está documentada lo suficiente para continuar iterando.

## 8. Siguientes Pasos Recomendados

- Estimar las historias P0.
- Convertir las historias en tareas técnicas por frontend, backend y diseño.
- Definir el catálogo mínimo de ejercicios y reglas de sustitución.
- Diseñar el onboarding de menor fricción posible.
- Alinear qué parte del motor se resuelve con reglas y qué parte con IA.
