# Especificación de Requerimientos de Software (SRS)

## 1. Información General

### 1.1 Nombre del producto
Kineo Coach

### 1.2 Versión del documento
Versión 1.0

### 1.3 Fecha
11 de marzo de 2026

### 1.4 Estado
Borrador detallado para validación funcional, técnica y comercial

### 1.5 Propósito del documento
Este documento define de forma detallada los objetivos de negocio, alcance, actores, reglas, requerimientos funcionales y no funcionales de Kineo Coach, una aplicación móvil enfocada en entrenamiento, nutrición y acompañamiento adaptativo basado en inteligencia artificial. Su propósito es servir como base para diseño de producto, estimación, desarrollo en Flutter, backend, QA y futuras iteraciones.

### 1.6 Alcance del documento
El SRS cubre:

- La visión de negocio del producto.
- El alcance funcional inicial y futuro.
- Los perfiles de usuario y sus necesidades.
- Los módulos funcionales y reglas de negocio.
- Los requisitos técnicos y no funcionales.
- Las integraciones externas esperadas.
- La propuesta de MVP y evolución por fases.

No cubre:

- Diseño visual definitivo de UI.
- Contratos API detallados a nivel de endpoint.
- Especificación legal final redactada por abogado.
- Costeo final de infraestructura y operación.

## 2. Resumen Ejecutivo

Kineo Coach es una aplicación móvil de fitness y nutrición personalizada cuyo diferenciador principal es la capacidad de adaptar en tiempo real el plan del usuario según su contexto diario. En lugar de entregar rutinas o dietas estáticas, el sistema ajusta entrenamiento, alimentación y recomendaciones a partir de variables como tiempo disponible, energía, sueño, dolor, equipamiento, adherencia y preferencias.

El producto apunta a usuarios que desean resultados reales sin depender de un entrenador humano permanente, pero con una experiencia percibida como cercana, inteligente y flexible. La app se construirá inicialmente en Flutter para acelerar salida multiplataforma y mantener una experiencia premium en iOS y Android.

## 3. Visión del Negocio

### 3.1 Problema que resuelve
Las aplicaciones tradicionales de entrenamiento y nutrición fallan en tres puntos:

- Entregan planes rígidos que no se ajustan a la vida real del usuario.
- Separan entrenamiento y nutrición en experiencias desconectadas.
- No reaccionan a condiciones cotidianas como fatiga, falta de tiempo, dolor o ausencia de equipo.

### 3.2 Oportunidad
Existe demanda creciente de productos digitales de salud y bienestar que combinen personalización, practicidad y seguimiento continuo. Kineo Coach puede posicionarse como un coach digital accesible con una experiencia más dinámica que una app genérica y más escalable que un servicio 1 a 1.

### 3.3 Propuesta de valor
Kineo Coach ofrece hiper-personalización dinámica: un sistema que ajusta entrenamiento, nutrición y recomendaciones diarias según el estado y contexto real del usuario.

### 3.4 Objetivos del negocio

- Lanzar un MVP funcional para validar interés de mercado y retención.
- Monetizar mediante un modelo freemium con suscripción premium.
- Construir una base de datos de comportamiento que permita mejorar personalización y segmentación.
- Posicionar la marca como coach digital integral de entrenamiento y hábitos.

### 3.5 Métricas de éxito del negocio

- Tasa de activación: porcentaje de usuarios que completan onboarding y reciben su primer plan.
- Retención D7, D30 y D90.
- Porcentaje de usuarios que completan al menos 3 entrenamientos por semana.
- Porcentaje de usuarios premium sobre usuarios activos mensuales.
- Tasa de adherencia al plan nutricional.
- Tiempo promedio semanal dentro de la app.
- Tasa de sustitución exitosa de ejercicios sin abandono de la sesión.

## 4. Objetivos del Producto

### 4.1 Objetivo general
Crear una aplicación móvil que funcione como entrenador y nutricionista virtual adaptativo, capaz de generar, ajustar y dar seguimiento a planes de entrenamiento y alimentación personalizados.

### 4.2 Objetivos específicos

- Capturar un perfil completo del usuario mediante onboarding guiado.
- Generar planes personalizados de entrenamiento y nutrición.
- Ajustar recomendaciones diarias según contexto y respuesta del usuario.
- Guiar sesiones de entrenamiento paso a paso.
- Facilitar adherencia con recordatorios, motivación y seguimiento visual del progreso.
- Permitir una experiencia fluida, confiable y escalable en Flutter.

## 5. Stakeholders

### 5.1 Stakeholders principales

- Fundador / dueño del producto.
- Equipo de producto.
- Equipo de diseño UX/UI.
- Equipo de desarrollo móvil.
- Equipo de backend e IA.
- Equipo de QA.
- Usuarios finales.
- Posibles coaches o nutricionistas aliados en futuras fases.

### 5.2 Intereses clave

- Negocio: validación, monetización, retención y diferenciación.
- Producto: simplicidad, personalización y experiencia premium.
- Tecnología: escalabilidad, mantenibilidad y portabilidad.
- Usuario: utilidad real, motivación, confianza y resultados.

## 6. Perfiles de Usuario

### 6.1 Usuario principiante
Persona con poca experiencia en entrenamiento y nutrición, necesita guía clara, lenguaje simple, seguridad y acompañamiento.

### 6.2 Usuario intermedio
Persona que ya entrena pero carece de consistencia o estructura. Busca optimización, flexibilidad y seguimiento.

### 6.3 Usuario ocupado
Persona con poco tiempo diario, agenda cambiante y alta necesidad de adaptación.

### 6.4 Usuario con restricciones
Persona con molestias, lesiones previas, limitaciones de movilidad, alergias o restricciones alimentarias.

### 6.5 Usuario premium aspiracional
Persona dispuesta a pagar por personalización avanzada, acompañamiento continuo y funciones más inteligentes.

## 7. Supuestos del Producto

- El usuario usará principalmente la aplicación desde su teléfono móvil.
- La primera versión se enfocará en entrenamiento general, recomposición corporal, pérdida de grasa, ganancia muscular y hábitos básicos.
- La IA será asistiva y no sustituirá diagnóstico médico.
- El usuario podrá introducir datos manualmente aunque algunas integraciones no estén disponibles.
- El MVP no dependerá obligatoriamente de wearables, pero deberá poder integrarlos más adelante.

## 8. Restricciones

- El producto debe poder desarrollarse con un equipo pequeño y una arquitectura modular.
- La primera versión debe evitar complejidad clínica o médica de alto riesgo.
- La experiencia inicial debe funcionar con baja fricción y tiempos rápidos de respuesta.
- Los costos de operación de IA deben mantenerse bajo control.
- La arquitectura debe minimizar dependencia irreversible de un proveedor específico.

## 9. Alcance del Producto

### 9.1 Incluido en alcance MVP

- Registro e inicio de sesión.
- Onboarding de perfil y objetivos.
- Generación inicial de plan de entrenamiento.
- Generación inicial de lineamientos nutricionales y menú base.
- Dashboard diario personalizado.
- Modo entrenamiento con seguimiento de series, repeticiones y tiempos.
- Sustitución de ejercicios por contexto o molestia.
- Registro de progreso corporal y de adherencia.
- Recordatorios básicos y notificaciones.
- Suscripción premium.

### 9.2 Fuera de alcance MVP

- Telemedicina o diagnóstico clínico.
- Marketplace de entrenadores.
- Video llamadas con coaches.
- Comunidad social compleja.
- Integración extensa con laboratorios o EPS.
- Planes familiares o corporativos.

### 9.3 Alcance futuro deseable

- Integración con Apple Health, Google Fit y wearables.
- Chat conversacional continuo con coach IA.
- Reconocimiento de alimentos por foto.
- Video análisis de técnica de ejercicio.
- Panel web administrativo.
- Módulos B2B para gimnasios, empresas o coaches.

## 10. Modelo de Negocio

### 10.1 Modelo de monetización

- Plan gratuito:
  - Registro y onboarding.
  - Biblioteca básica de ejercicios.
  - Seguimiento básico de actividad y progreso.
  - Acceso limitado a recomendaciones.
- Plan premium por suscripción mensual o anual:
  - Planes personalizados completos.
  - Ajustes diarios adaptativos.
  - Sustitución inteligente ilimitada.
  - Nutrición integrada.
  - Reportes avanzados y seguimiento histórico.
  - Coach IA conversacional en fases posteriores.

### 10.2 Palancas de crecimiento

- Prueba gratuita del plan premium.
- Referidos.
- Contenido educativo.
- Retos y programas por objetivos.
- Alianzas con creadores, gimnasios o profesionales.

## 11. Principios de Producto

- Personalización por encima de plantillas rígidas.
- Simplicidad en la experiencia, complejidad en el motor.
- Entrenamiento y nutrición como un sistema integrado.
- Adaptación diaria como diferenciador central.
- Decisiones basadas en datos de uso y adherencia.
- Seguridad, confianza y claridad sobre límites del sistema.

## 12. Funcionalidades del Sistema

### 12.1 Módulo de autenticación y acceso

#### Objetivo
Permitir al usuario crear una cuenta, autenticarse y gestionar su sesión de forma segura.

#### Requerimientos funcionales

- RF-001 El sistema debe permitir registro mediante correo y contraseña.
- RF-002 El sistema debe permitir login social con Google.
- RF-003 El sistema debe permitir login con Apple en iOS o donde aplique por cumplimiento de plataforma.
- RF-004 El sistema debe permitir restablecimiento de contraseña.
- RF-005 El sistema debe mantener la sesión iniciada de forma segura.
- RF-006 El sistema debe permitir cierre de sesión.
- RF-007 El sistema debe permitir eliminación de cuenta según normativa aplicable.

### 12.2 Módulo de onboarding inteligente

#### Objetivo
Capturar suficiente información para construir un perfil inicial útil y personalizado.

#### Datos a capturar

- Nombre o alias.
- Edad.
- Sexo o identidad relevante para cálculo fisiológico, con manejo respetuoso.
- Estatura.
- Peso actual.
- Meta principal.
- Nivel de experiencia.
- Disponibilidad semanal.
- Tiempo por sesión.
- Lugar de entrenamiento.
- Equipamiento disponible.
- Limitaciones físicas o dolor actual.
- Horas y calidad de sueño autoreportadas.
- Nivel de estrés percibido.
- Preferencias alimentarias.
- Restricciones y alergias.
- Objetivo nutricional.
- Hábitos actuales.

#### Requerimientos funcionales

- RF-008 El sistema debe guiar al usuario paso a paso durante el onboarding.
- RF-009 El sistema debe validar campos obligatorios y formato de datos.
- RF-010 El sistema debe permitir omitir ciertos campos no críticos y completarlos después.
- RF-011 El sistema debe resumir el perfil antes de confirmar.
- RF-012 El sistema debe usar los datos del onboarding para generar un plan inicial.
- RF-013 El sistema debe permitir editar el perfil posteriormente.

### 12.3 Módulo de perfil de usuario y objetivos

#### Objetivo
Mantener una representación viva del usuario y sus metas.

#### Requerimientos funcionales

- RF-014 El sistema debe almacenar métricas base e historial.
- RF-015 El sistema debe permitir definir uno o más objetivos con prioridad.
- RF-016 El sistema debe permitir actualizar peso, medidas y fotos de progreso.
- RF-017 El sistema debe recalibrar recomendaciones cuando el perfil cambie materialmente.
- RF-018 El sistema debe mostrar resumen de progreso hacia metas.

### 12.4 Módulo de motor de personalización

#### Objetivo
Generar y ajustar planes en función del perfil, comportamiento y contexto diario.

#### Requerimientos funcionales

- RF-019 El sistema debe generar un plan de entrenamiento inicial personalizado.
- RF-020 El sistema debe generar lineamientos o plan nutricional inicial personalizado.
- RF-021 El sistema debe reajustar el plan diario según tiempo disponible.
- RF-022 El sistema debe reajustar el plan diario según nivel de energía o fatiga reportada.
- RF-023 El sistema debe reajustar el plan cuando el usuario reporte dolor o limitación.
- RF-024 El sistema debe reajustar el plan cuando no exista equipo disponible.
- RF-025 El sistema debe proponer alternativas equivalentes a ejercicios o comidas no deseadas.
- RF-026 El sistema debe registrar el motivo del ajuste para trazabilidad.
- RF-027 El sistema debe evitar recomendaciones incompatibles con restricciones declaradas.
- RF-028 El sistema debe soportar reglas de negocio y lógica configurable desde backend.

### 12.5 Módulo de dashboard diario

#### Objetivo
Servir como centro operativo del usuario durante el día.

#### Requerimientos funcionales

- RF-029 El sistema debe mostrar un resumen contextual del día.
- RF-030 El sistema debe resaltar la acción principal del momento, por ejemplo entrenar, comer, hidratarse o descansar.
- RF-031 El sistema debe mostrar progreso diario y semanal.
- RF-032 El sistema debe mostrar recomendaciones personalizadas por franja horaria.
- RF-033 El sistema debe mostrar próximos hitos o tareas pendientes.
- RF-034 El sistema debe incluir mensajes motivacionales o educativos no intrusivos.

### 12.6 Módulo de entrenamiento

#### Objetivo
Guiar la ejecución del plan de entrenamiento.

#### Requerimientos funcionales

- RF-035 El sistema debe mostrar la rutina del día organizada por bloques o ejercicios.
- RF-036 El sistema debe mostrar instrucciones, músculos objetivo y material requerido por ejercicio.
- RF-037 El sistema debe incluir temporizadores de descanso y ejecución.
- RF-038 El sistema debe permitir registrar peso, repeticiones, series, duración y esfuerzo percibido.
- RF-039 El sistema debe permitir marcar ejercicios como completados, omitidos o sustituidos.
- RF-040 El sistema debe permitir pausar y reanudar la sesión.
- RF-041 El sistema debe calcular métricas básicas de volumen y cumplimiento.
- RF-042 El sistema debe permitir finalizar sesión con resumen.

### 12.7 Función SOS durante entrenamiento

#### Objetivo
Resolver fricciones en tiempo real sin que el usuario abandone la sesión.

#### Requerimientos funcionales

- RF-043 El sistema debe permitir reportar dolor, incomodidad o imposibilidad de ejecutar un ejercicio.
- RF-044 El sistema debe permitir reportar equipo ocupado o no disponible.
- RF-045 El sistema debe ofrecer una o más alternativas biomecánicamente equivalentes.
- RF-046 El sistema debe conservar la coherencia del objetivo del entrenamiento tras la sustitución.
- RF-047 El sistema debe registrar qué ejercicio fue reemplazado y por qué.
- RF-048 El sistema debe advertir al usuario que, ante dolor persistente o severo, debe detener la actividad y consultar a un profesional.

### 12.8 Módulo de nutrición

#### Objetivo
Ayudar al usuario a cumplir sus objetivos alimentarios de forma flexible.

#### Requerimientos funcionales

- RF-049 El sistema debe mostrar objetivos nutricionales diarios.
- RF-050 El sistema debe generar propuestas de comidas o menús según preferencias y restricciones.
- RF-051 El sistema debe permitir reemplazar una comida sugerida por otra equivalente.
- RF-052 El sistema debe generar lista de compras a partir del menú planificado.
- RF-053 El sistema debe permitir registrar cumplimiento básico de comidas.
- RF-054 El sistema debe mostrar consumo estimado de calorías y macronutrientes cuando el plan lo contemple.
- RF-055 El sistema debe evitar ingredientes prohibidos por alergias o restricciones declaradas.

### 12.9 Módulo de progreso y analítica personal

#### Objetivo
Permitir al usuario visualizar avances y reforzar adherencia.

#### Requerimientos funcionales

- RF-056 El sistema debe mostrar evolución de peso y medidas.
- RF-057 El sistema debe mostrar consistencia semanal y mensual.
- RF-058 El sistema debe mostrar historial de entrenamientos completados.
- RF-059 El sistema debe mostrar indicadores básicos de cumplimiento nutricional.
- RF-060 El sistema debe destacar logros, rachas e hitos.

### 12.10 Módulo de notificaciones y recordatorios

#### Objetivo
Mantener activación y adherencia sin saturar al usuario.

#### Requerimientos funcionales

- RF-061 El sistema debe enviar recordatorios de entrenamiento.
- RF-062 El sistema debe enviar recordatorios de hidratación si están activados.
- RF-063 El sistema debe enviar mensajes de seguimiento cuando el usuario pierda adherencia.
- RF-064 El sistema debe permitir configurar preferencias de notificación.
- RF-065 El sistema debe respetar horarios razonables y zona horaria del usuario.

### 12.11 Módulo de pagos y suscripción

#### Objetivo
Gestionar monetización del plan premium.

#### Requerimientos funcionales

- RF-066 El sistema debe mostrar diferencias entre plan gratuito y premium.
- RF-067 El sistema debe permitir comprar suscripción desde la app.
- RF-068 El sistema debe reflejar el estado de la suscripción del usuario.
- RF-069 El sistema debe controlar acceso a funcionalidades premium.
- RF-070 El sistema debe soportar restauración de compras.

### 12.12 Módulo administrativo futuro

#### Objetivo
Permitir monitoreo, soporte y evolución operativa del producto.

#### Requerimientos esperados para fase posterior

- RF-071 El sistema debe permitir administrar catálogos de ejercicios y alimentos.
- RF-072 El sistema debe permitir revisar métricas agregadas de uso.
- RF-073 El sistema debe permitir gestionar contenido y configuraciones.

## 13. Casos de Uso Principales

### CU-01 Registro y acceso
El usuario crea cuenta o inicia sesión para acceder a la plataforma.

### CU-02 Completar onboarding
El usuario responde preguntas guiadas y obtiene su plan inicial.

### CU-03 Consultar plan diario
El usuario abre el dashboard y revisa qué debe hacer hoy.

### CU-04 Realizar entrenamiento
El usuario inicia la rutina, registra resultados y finaliza la sesión.

### CU-05 Sustituir ejercicio
Durante la sesión, el usuario reporta dolor o indisponibilidad y recibe una alternativa.

### CU-06 Consultar plan nutricional
El usuario revisa comidas sugeridas y registra cumplimiento.

### CU-07 Actualizar progreso
El usuario registra peso, medidas o fotos y observa cambios.

### CU-08 Cambiar a plan premium
El usuario decide suscribirse para desbloquear funciones avanzadas.

## 14. Reglas de Negocio

- RN-001 Ningún plan debe sugerir ejercicios incompatibles con restricciones físicas declaradas.
- RN-002 Ningún menú debe contener ingredientes marcados como alérgenos por el usuario.
- RN-003 El sistema debe priorizar adherencia sostenible sobre complejidad excesiva.
- RN-004 La adaptación diaria debe preservar el objetivo principal del usuario en la medida de lo posible.
- RN-005 Si el usuario no tiene tiempo suficiente para el plan original, el sistema debe ofrecer una versión reducida de alto impacto.
- RN-006 Los usuarios gratuitos tendrán acceso limitado a funciones de personalización avanzada.
- RN-007 Las recomendaciones generadas por IA deben pasar por validaciones y reglas determinísticas antes de mostrarse.
- RN-008 El sistema debe incluir descargos claros indicando que no reemplaza atención médica profesional.
- RN-009 El usuario debe poder corregir manualmente datos clave si el sistema sugiere algo no pertinente.
- RN-010 El sistema debe registrar cambios relevantes para auditoría funcional y mejora del motor.

## 15. Requerimientos No Funcionales

### 15.1 Rendimiento

- RNF-001 La app debe abrir el dashboard principal en menos de 3 segundos en condiciones normales de red.
- RNF-002 Las interacciones comunes deben sentirse fluidas y responder en menos de 300 ms en UI local.
- RNF-003 La sustitución de ejercicios o ajuste diario idealmente no debe tardar más de 5 segundos.

### 15.2 Disponibilidad

- RNF-004 Los servicios principales deben aspirar a una disponibilidad mensual de al menos 99.5% en producción inicial.

### 15.3 Escalabilidad

- RNF-005 La arquitectura debe permitir crecimiento por módulos y separación de cargas entre app, API y motor de personalización.

### 15.4 Seguridad

- RNF-006 La autenticación debe manejarse con proveedores confiables y tokens validados por backend.
- RNF-007 La información sensible debe transmitirse cifrada en tránsito.
- RNF-008 Los datos personales y de salud básica deben almacenarse con controles de acceso estrictos.
- RNF-009 El sistema debe contemplar borrado de cuenta y eliminación de datos asociados según regulación aplicable.

### 15.5 Privacidad

- RNF-010 El usuario debe aceptar términos y política de privacidad antes de usar funciones sensibles.
- RNF-011 Debe existir consentimiento explícito para integraciones de salud o wearables.
- RNF-012 Debe informarse al usuario cuando una recomendación sea generada o ajustada por IA.

### 15.6 Usabilidad

- RNF-013 La experiencia debe ser entendible para usuarios principiantes.
- RNF-014 El flujo de onboarding no debe sentirse clínico ni intimidante.
- RNF-015 Las acciones principales del día deben ser visibles sin navegación profunda.

### 15.7 Mantenibilidad

- RNF-016 El frontend debe seguir una arquitectura modular por features.
- RNF-017 El backend debe separar dominio, reglas, integraciones y API.
- RNF-018 El sistema debe ser testeable a nivel unitario, integración y end to end.

### 15.8 Portabilidad

- RNF-019 La app móvil debe funcionar en Android e iOS desde una sola base de código Flutter.
- RNF-020 La capa de persistencia backend debe abstraer el proveedor de base de datos para facilitar migración.

### 15.9 Observabilidad

- RNF-021 El sistema debe registrar errores, eventos críticos y métricas de uso relevantes.
- RNF-022 Debe ser posible rastrear fallos de generación o ajuste del plan.

## 16. Arquitectura Propuesta

### 16.1 Frontend móvil

- Tecnología principal: Flutter.
- Lenguaje: Dart.
- Arquitectura recomendada: Clean Architecture modular por feature.
- Gestión de estado sugerida: Bloc o Cubit en módulos con lógica transaccional clara.

### 16.2 Backend

- Tecnología principal: Python con FastAPI.
- Responsabilidades:
  - Exponer API segura para la app.
  - Orquestar lógica de negocio.
  - Gestionar motor de personalización.
  - Intermediar con proveedores de IA y servicios externos.

### 16.3 Persistencia

- Base de datos relacional: PostgreSQL.
- Uso inicial sugerido: Supabase como hosting gestionado de PostgreSQL.
- Abstracción: SQLAlchemy o SQLModel para evitar acoplamiento.

### 16.4 Autenticación

- Proveedor sugerido: Firebase Authentication o alternativa equivalente.
- El backend debe validar tokens y mapear identidad a usuario interno.

### 16.5 IA y motor de recomendación

- La generación inteligente debe residir en backend, no en cliente.
- Debe existir combinación de reglas determinísticas y generación por LLM.
- Las respuestas del modelo deben pasar por validación antes de persistirse o mostrarse.
- Debe contemplarse caché o reutilización de resultados para controlar costos.

## 17. Integraciones Externas

### 17.1 Integraciones del MVP

- Autenticación social y credenciales.
- Plataforma de pagos móviles.
- Servicio de notificaciones push.
- Proveedor de IA para generación de planes y ajustes.

### 17.2 Integraciones futuras

- Apple Health.
- Google Fit.
- Wearables.
- Analítica avanzada.
- CRM o herramientas de soporte.

## 18. Modelo de Datos de Alto Nivel

### Entidades principales

- Usuario
- Perfil fisiológico
- Objetivo
- Restricción física
- Preferencia alimentaria
- Alergia
- Plan de entrenamiento
- Rutina
- Ejercicio
- Sesión de entrenamiento
- Registro de ejercicio
- Plan nutricional
- Comida sugerida
- Lista de compras
- Métrica de progreso
- Suscripción
- Evento de personalización
- Notificación

### Relaciones relevantes

- Un usuario tiene un perfil, uno o varios objetivos y múltiples métricas de progreso.
- Un usuario puede tener múltiples planes en el tiempo, pero uno activo por tipo.
- Un plan de entrenamiento contiene múltiples rutinas y ejercicios.
- Un plan nutricional contiene múltiples comidas y equivalencias.
- Cada ajuste adaptativo debe quedar vinculado a un usuario y a un contexto específico.

## 19. Flujos Clave de Usuario

### 19.1 Flujo de activación inicial

1. Usuario instala la app.
2. Crea cuenta o inicia sesión.
3. Acepta términos.
4. Completa onboarding.
5. Recibe plan inicial.
6. Visualiza dashboard.
7. Ejecuta primera acción relevante.

### 19.2 Flujo de entrenamiento diario

1. Usuario abre dashboard.
2. Revisa rutina recomendada.
3. Inicia sesión de entrenamiento.
4. Registra desempeño.
5. Si surge problema, usa función SOS.
6. Finaliza sesión.
7. Recibe resumen y siguiente recomendación.

### 19.3 Flujo de ajuste nutricional

1. Usuario revisa comida sugerida.
2. No desea la opción propuesta.
3. Solicita reemplazo.
4. Sistema propone alternativas equivalentes.
5. Usuario confirma y registra cumplimiento.

## 20. Riesgos del Producto

- Riesgo de prometer más personalización de la que el MVP pueda entregar.
- Riesgo de alto costo por uso intensivo de IA.
- Riesgo regulatorio o reputacional por recomendaciones sensibles.
- Riesgo de baja retención si onboarding es largo o el valor tarda en percibirse.
- Riesgo técnico si se combinan demasiadas integraciones desde el inicio.
- Riesgo de contenido insuficiente en biblioteca de ejercicios y menús.

## 21. Mitigaciones Recomendadas

- Lanzar primero con objetivos y casos de uso bien delimitados.
- Implementar reglas base robustas antes de sofisticar la IA.
- Diseñar onboarding progresivo con preguntas mínimas obligatorias.
- Mantener disclaimers claros de salud.
- Medir activación y abandono por pantalla desde el primer release.
- Priorizar calidad del flujo principal sobre amplitud de funcionalidades.

## 22. Recomendación de MVP

### 22.1 Objetivo del MVP
Validar si los usuarios perciben valor en una experiencia adaptativa de entrenamiento y nutrición y están dispuestos a usarla recurrentemente y pagar por ella.

### 22.2 Funcionalidades mínimas recomendadas

- Autenticación.
- Onboarding resumido pero útil.
- Generación de plan de entrenamiento básico personalizado.
- Dashboard diario.
- Modo entrenamiento con registro básico.
- Sustitución simple de ejercicios.
- Plan nutricional básico por lineamientos y sugerencias.
- Seguimiento básico de peso y adherencia.
- Notificaciones esenciales.
- Paywall y suscripción premium.

### 22.3 Qué dejar para fase 2

- Integraciones con wearables.
- Chat continuo con IA.
- Video técnica.
- Reconocimiento por foto.
- Backoffice avanzado.

## 23. Roadmap Propuesto

### Fase 0: Descubrimiento y definición

- Validación de mercado.
- Benchmark competitivo.
- Diseño de marca y propuesta visual.
- Priorización de alcance MVP.

### Fase 1: Fundaciones técnicas

- Repositorios base.
- Autenticación.
- Modelado inicial de datos.
- Infraestructura de backend.
- Configuración analítica y crash reporting.

### Fase 2: MVP funcional

- Onboarding.
- Motor inicial de personalización.
- Dashboard.
- Entrenamiento.
- Nutrición básica.
- Suscripción.

### Fase 3: Optimización

- Mejoras de retención.
- Reglas más avanzadas.
- A/B testing.
- Refinamiento de UX.

### Fase 4: Expansión

- Wearables.
- Coach conversacional.
- Panel administrativo.
- Alianzas B2B.

## 24. Criterios de Aceptación del MVP

- El usuario puede registrarse e iniciar sesión sin fricción crítica.
- El usuario puede completar onboarding en menos de 10 minutos.
- El sistema entrega un plan inicial coherente con el perfil declarado.
- El usuario puede completar una rutina y guardar resultados.
- El usuario puede sustituir al menos un ejercicio durante una sesión.
- El usuario puede consultar recomendaciones nutricionales básicas.
- El usuario puede visualizar progreso inicial.
- El sistema puede diferenciar entre usuario gratuito y premium.

## 25. Indicadores de Producto a Instrumentar

- Porcentaje de onboarding completado.
- Tiempo hasta primer valor.
- Número de sesiones por usuario por semana.
- Frecuencia de uso del botón SOS.
- Razones más frecuentes de sustitución.
- Porcentaje de usuarios que vuelven tras 7 y 30 días.
- Conversión a premium.
- Churn de suscripción.

## 26. Consideraciones Legales y de Confianza

- El producto debe incluir términos y condiciones y política de privacidad.
- Debe quedar explícito que no sustituye orientación médica profesional.
- Las recomendaciones deben presentarse como apoyo para bienestar y entrenamiento general.
- Las funciones con datos sensibles deben operar bajo principios de minimización de datos.
- El proceso de borrado de cuenta debe ser claro y accesible.

## 27. Recomendación de Diseño de Experiencia

- El tono de la app debe sentirse cercano, claro y motivador.
- El dashboard debe actuar como asistente diario, no solo como tablero de métricas.
- El onboarding debe parecer conversación guiada, no formulario largo.
- La experiencia premium debe evidenciarse en fluidez, claridad y adaptación contextual.
- La UI debe comunicar progreso, control y confianza.

## 28. Conclusión

Kineo Coach tiene potencial para convertirse en un producto diferencial dentro del espacio fitness y wellness si mantiene el foco en una promesa concreta: adaptar el plan al día real del usuario. El mayor valor no estará en tener muchas funciones aisladas, sino en integrar entrenamiento, nutrición y contexto en una experiencia coherente, práctica y confiable.

La recomendación es construir primero un MVP sólido centrado en personalización útil, adherencia y claridad operativa, y luego expandir capacidades de IA e integraciones conforme se validen retención, conversión y comportamiento de uso.
