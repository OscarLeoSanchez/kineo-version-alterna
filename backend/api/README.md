# Backend API

Arquitectura inicial para la API de Kineo Coach.

## Objetivos

- Exponer endpoints para la app movil.
- Centralizar reglas del negocio.
- Orquestar personalizacion y adaptacion diaria.
- Integrar autenticacion, base de datos y proveedores de IA.

## Estructura

- `app/api/v1/endpoints`: endpoints versionados.
- `app/core`: settings, seguridad, dependencias y logging.
- `app/db`: sesion y persistencia.
- `app/models`: modelos ORM.
- `app/schemas`: contratos Pydantic.
- `app/repositories`: acceso a datos.
- `app/services`: logica de aplicacion.
- `app/rules`: reglas deterministicas.
- `app/ai`: capa de IA.
- `tests`: pruebas unitarias e integracion.
