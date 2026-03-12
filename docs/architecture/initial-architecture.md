# Arquitectura Inicial

## Vision general

La solucion se divide en dos proyectos principales:

- App movil Flutter para experiencia de usuario.
- API backend en FastAPI para negocio, persistencia y orquestacion de IA.

## Frontend Flutter

La app se organiza por `features`, con separacion entre:

- `data`: acceso a API, DTOs y repositorios concretos.
- `domain`: entidades, casos de uso y contratos.
- `presentation`: pantallas, widgets, controladores y estado.

Capas compartidas:

- `core`: configuracion global, red, errores, tema, DI y navegacion.
- `shared`: widgets y modelos transversales.

## Backend FastAPI

La API se organiza por responsabilidades:

- `api/v1/endpoints`: rutas HTTP versionadas.
- `schemas`: contratos de entrada y salida.
- `models`: modelos de persistencia.
- `repositories`: acceso a datos.
- `services`: logica de aplicacion.
- `rules`: validaciones y reglas deterministicas.
- `ai`: orquestacion con proveedores de IA.
- `db`: conexion, sesiones y migraciones futuras.
- `core`: configuracion, seguridad, logging y dependencias.

## Modulos iniciales del dominio

- Autenticacion
- Onboarding
- Dashboard
- Workout
- Nutrition
- Progress
- Subscription

## Criterios de evolucion

- Evitar acoplar UI con infraestructura.
- Mantener reglas del negocio fuera del cliente cuando sea posible.
- Validar toda recomendacion inteligente antes de mostrarla al usuario.
- Instrumentar eventos desde el inicio.
