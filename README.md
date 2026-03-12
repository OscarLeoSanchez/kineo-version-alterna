# Kineo Coach

Base inicial de arquitectura para el producto Kineo Coach.

## Estructura del repositorio

- `mobile/flutter_app`: app movil en Flutter.
- `backend/api`: API y motor de negocio en FastAPI.
- `docs/architecture`: decisiones y mapas de arquitectura.
- `docs/product`: documentos de producto.

## Documentos de producto disponibles

- `kineo-coach-info.txt`
- `kineo-coach-srs.md`
- `kineo-coach-prd.md`
- `kineo-coach-backlog-inicial.md`

## Siguiente objetivo tecnico recomendado

1. Inicializar el proyecto Flutter dentro de `mobile/flutter_app`.
2. Inicializar el proyecto FastAPI dentro de `backend/api`.
3. Conectar autenticacion, configuracion base y observabilidad.

## Levantar infraestructura local

1. Ejecuta `docker compose up --build`.
2. La API quedara disponible en `http://localhost:8000`.
3. PostgreSQL quedara disponible en `localhost:5432`.
4. Para la app Flutter usa `--dart-define=API_BASE_URL=http://10.0.2.2:8000` en Android emulator o `http://localhost:8000` en iOS/web/desktop.
