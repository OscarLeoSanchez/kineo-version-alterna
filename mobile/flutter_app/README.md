# Flutter App

Arquitectura base para la aplicacion movil de Kineo Coach.

## Estructura

- `lib/core`: configuracion global.
- `lib/shared`: componentes reutilizables.
- `lib/features`: modulos por funcionalidad.
- `test`: pruebas unitarias y de widgets.
- `integration_test`: pruebas de flujos completos.
- `assets`: recursos visuales.

## Features iniciales

- `auth`
- `onboarding`
- `dashboard`
- `workout`
- `nutrition`
- `progress`
- `subscription`

## Convenciones

- Cada feature debe separar `data`, `domain` y `presentation`.
- La navegacion debe centralizarse en `lib/core/router`.
- Las dependencias deben registrarse desde `lib/core/di`.
- La logica de negocio no debe vivir en widgets.
