# investep-app

Aplicación cliente **multiplataforma** (Flutter) de Investep App — la experiencia
logueada del usuario: planes de inversión, contenido de la academia y estado de
carteras (saldos, posiciones, órdenes, transacciones) en **solo lectura**,
agregadas desde los brókers a través de `investep-app-api`.

> Antes de tocar código, leé [AGENTS.md](./AGENTS.md). Es la guía de trabajo.

## Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter (Dart), compilado nativo por plataforma |
| Targets | iOS · Android · Web · macOS · Windows · Linux |
| Estado | **Riverpod** (`flutter_riverpod`) — sin code-gen por ahora (ver más abajo) |
| Navegación | `go_router` |
| HTTP / API | `dio` (base del cliente generado por OpenAPI) |
| Auth / sesión | `supabase_flutter` + `flutter_secure_storage` |
| Iconos | `lucide_icons_flutter` (icon font nativa, Lucide) |
| Diseño | Glassmorphism nativo (`BackdropFilter`) + animaciones |
| Tareas | `just` (ver `justfile`) |
| Calidad | `flutter_lints` estricto + `pre-commit` |

## Requisitos

- Flutter 3.41+ / Dart 3.11+
- [`just`](https://github.com/casey/just)
- [`pre-commit`](https://pre-commit.com/) (`pre-commit install`)

## Cómo arrancar

```bash
just deps        # flutter pub get
just run         # target por defecto
just web         # versión web (app, no el sitio público)
just desktop     # macOS (o: just desktop windows | linux)
just test        # tests
just analyze     # analyze + verificación de formato
```

La configuración de entorno se inyecta con `--dart-define` (nunca hardcodees
secretos). Ejemplo:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.investepacademy.com \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## Estructura

Arquitectura **feature-first / clean**: cada feature aísla sus capas
`data` / `domain` / `presentation`.

```
lib/
├── app/                 # raíz de la app: MaterialApp.router, router, tema
├── core/                # infraestructura transversal
│   ├── config/          # AppConfig (env vía --dart-define)
│   ├── network/         # cliente Dio + interceptores
│   └── storage/         # almacén seguro de sesión
├── features/            # dominios de negocio
│   ├── auth/            # data · domain · presentation
│   ├── academy/
│   └── portfolio/       # incluye pantalla de ejemplo (scaffold visual)
└── shared/              # UI reutilizable
    └── widgets/glass/   # GlassCard (glassmorphism nativo)
```

## Decisiones tomadas en el scaffold

- **Riverpod sin code generation.** El ecosistema `riverpod_generator` 3.x está
  en transición sobre Dart 3.11 (macros/analyzer) y no resuelve de forma estable
  con `flutter_riverpod` 3.x. Declaramos providers a mano —100% idiomático— y
  sumaremos codegen cuando el ecosistema se estabilice, sin reescribir lógica.
- **Glassmorphism propio**, no una librería externa: `BackdropFilter` +
  `ImageFilter.blur` nativos (AGENTS.md §4bis). El blur es costoso; vigilá la
  cantidad de capas simultáneas en web/escritorio.
- **Sin `cupertino_icons`**: una sola familia de iconos (Lucide), sin mezclar.

## Pendientes (AGENTS.md §9)

- Herramienta de generación del cliente OpenAPI para Dart (cablear receta `just openapi`).
- Sumar `riverpod_generator` cuando el ecosistema se estabilice.
- Definir si se usa una librería de glassmorphism o se mantiene el widget propio.
