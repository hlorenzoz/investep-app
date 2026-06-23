# AGENTS.md — investep-app

> Guía para agentes de IA (Claude Code, Cursor, etc.) que trabajen en este repositorio.
> Léelo entero antes de modificar código.

## 1. Qué es este proyecto

`investep-app` es la **aplicación cliente multiplataforma** de Investep App, parte del
ecosistema de [Investep Academy](https://investepacademy.com/). Es la *aplicación* en sí
(la experiencia logueada del usuario), no el sitio web público.

Construida con **Flutter** desde una sola base de código para:
- **iOS**
- **Android**
- **Web** (la versión web de la *app*, distinta del sitio público en SvelteKit)
- **Escritorio** (Windows / macOS / Linux)

La app permite al usuario ver sus planes de inversión, contenido de la academia y el
estado de sus carteras (saldos, posiciones, órdenes, transacciones) en **solo lectura**,
agregadas desde sus brókers (IBKR, TastyTrade, eTrade).

## 2. Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Framework | **Flutter** (Dart), **compilado nativo** para cada plataforma |
| Targets | iOS, Android, Web, Desktop (Windows / macOS / Linux) |
| Backend | **API REST** `investep-app-api` (Hono / Cloudflare Workers) |
| Auth | Supabase Auth (`supabase_flutter`); token de sesión en `flutter_secure_storage` |
| Gestión de estado | **Riverpod** (`flutter_riverpod`) — sin code-gen por ahora (ver §4 y §9) |
| Navegación | **`go_router`** (router expuesto como provider) |
| Cliente HTTP / API | Transporte **`dio`**; modelos/endpoints generados contra el spec **OpenAPI** de la API |
| Diseño visual | **Glassmorphism** (transparencias, blur) + **animaciones** |
| Iconos | **Lucide** ([lucide.dev](https://lucide.dev/)) vía **`lucide_icons_flutter`** — icon font nativa compilada en el binario |
| Runner de tareas | **Justfile** (`just`) |
| Hooks de calidad | **pre-commit** + [pre-commit.ci](https://pre-commit.ci/) |
| Tests | **`flutter test`** (unit + widget) |

## 3. Relación con el resto del ecosistema

- **No** habla directamente con la base de datos ni con los brókers. Todo pasa por
  `investep-app-api`.
- El sitio público vive en **`investep-app-web` (SvelteKit)**. Esta app cubre la
  experiencia *después* del login. La frontera natural es: público → SvelteKit,
  sesión → Flutter.
- La transición sitio↔app comparte sesión de Supabase; respeta el esquema de dominios
  acordado (p. ej. `investepacademy.com` para el sitio, `app.investepacademy.com` para
  la app) para que cookies/tokens se compartan.

## 3bis. Estructura del proyecto

Arquitectura **feature-first / clean**: cada feature aísla sus capas
`data` / `domain` / `presentation`. Lo transversal vive en `core`; la UI
reutilizable, en `shared`.

```
lib/
├── app/                 # raíz: InvestepApp (MaterialApp.router), router, theme
├── core/                # infraestructura transversal
│   ├── config/          # AppConfig (env vía --dart-define)
│   ├── network/         # cliente Dio + interceptores
│   └── storage/         # almacén seguro de sesión (flutter_secure_storage)
├── features/            # dominios de negocio
│   ├── auth/            # data · domain · presentation
│   ├── academy/
│   └── portfolio/       # incluye pantalla de ejemplo (scaffold visual)
└── shared/              # UI reutilizable
    └── widgets/glass/   # GlassCard (glassmorphism nativo)
```

- Respeta la separación de capas: no metas lógica de red en `presentation` ni
  widgets en `domain`.
- Providers de Riverpod cerca de lo que exponen (p. ej. `apiClientProvider` en
  `core/network/`). Los globales de infraestructura, en `core/`.

## 4. Convenciones de código

- **Dart estricto**, null-safety siempre activo. SDK objetivo: **Flutter 3.41+ / Dart 3.11+**.
- Sigue las lint rules del proyecto (`analysis_options.yaml`); respeta `flutter analyze`
  sin warnings antes de dar por terminado un cambio. El `analysis_options.yaml` activa
  `strict-casts` / `strict-inference` / `strict-raw-types` y lints extra (comillas simples,
  `const`, trailing commas, `avoid_print`, etc.).
- **Estado con Riverpod sin code-gen**: declara los providers a mano (p. ej.
  `final fooProvider = NotifierProvider(...)`), **no** uses `riverpod_generator` por ahora
  (el ecosistema 3.x no resuelve estable sobre Dart 3.11 — ver §9). `ProviderScope` se
  monta en `main.dart`; los widgets que leen estado extienden `ConsumerWidget`.
- Una sola base de código para todas las plataformas: **evita ramas específicas de
  plataforma** salvo que sea imprescindible; cuando lo sea, aíslalas con
  `kIsWeb` / `Platform` y coméntalo.
- Cliente de API: la API es **REST** y regéneras/actualizas el cliente contra el **spec
  OpenAPI** que publica `investep-app-api`. No escribas a mano modelos que ya estén en el
  contrato.
- UI consistente entre plataformas; ten en cuenta diferencias de input (táctil vs ratón/
  teclado) y tamaños de pantalla (móvil ↔ escritorio).
- **Compilación nativa por plataforma.** Aprovecha que Flutter compila a nativo para
  ofrecer transparencias y animaciones fluidas en cada target. Verifica el rendimiento de
  los efectos visuales en plataformas reales (especialmente blur en web/escritorio, que
  es más caro que en móvil).

## 4bis. Diseño visual (Glassmorphism + animaciones)

El lenguaje visual de la app es **glassmorphism**, donde corresponda:

- Superficies con **transparencia y desenfoque** (`BackdropFilter` + `ImageFilter.blur`),
  bordes suaves, capas translúcidas sobre fondos con profundidad.
- Úsalo con criterio: no todo es cristal. Aplícalo a tarjetas, paneles, barras y modales
  destacados; mantén legibilidad y contraste (clave en datos financieros).
- **Animaciones** fluidas en transiciones, cambios de estado y feedback de interacción.
  Prefiere animaciones implícitas/`AnimationController` bien gestionados; evita jank.
- **Rendimiento:** el blur es costoso. Vigila el número de capas con `BackdropFilter`
  simultáneas, sobre todo en Flutter Web y escritorio. Mide antes de abusar.
- **Iconografía: Lucide** ([lucide.dev](https://lucide.dev/)), **renderizada de forma
  nativa**. Los iconos son glifos de una *icon font* o vectores (`IconData`/`Icon`)
  compilados dentro del binario y dibujados por el motor nativo de Flutter — **nunca**
  imágenes rasterizadas, SVG cargados en runtime ni nada vía webview. Así escalan sin
  pérdida, heredan color/tamaño del tema y rinden como iconos nativos en todas las
  plataformas.
- Lucide es un set **unificado e idéntico** en iOS, Android, web y escritorio (decisión
  consciente: prima la identidad visual propia de la app sobre los sets por plataforma
  como Cupertino/Material). Úsalo de forma consistente; **no mezcles** familias de iconos.
- Accesibilidad: respeta el contraste y el ajuste "reduce motion" del sistema para
  usuarios que prefieran menos animación.
- **Implementación:** el glassmorphism es un widget **propio** (`GlassCard` en
  `lib/shared/widgets/glass/`) con `BackdropFilter` + `ImageFilter.blur` nativos — **no**
  se usa una librería externa. Reutilízalo en vez de reescribir el efecto.
- **Lucide en código:** `import 'package:lucide_icons_flutter/lucide_icons.dart';` y usa
  la clase `LucideIcons` (p. ej. `Icon(LucideIcons.wallet)`). Es una icon font con
  `fontPackage` propio, compilada en el binario.

## 5. Seguridad y datos sensibles (CRÍTICO — fintech)

- **Nunca** almacenes tokens de brókers ni credenciales sensibles en el cliente. Esos
  viven cifrados en el backend. La app solo recibe datos de cartera ya agregados.
- Usa almacenamiento seguro del dispositivo (`flutter_secure_storage`) para el token de
  sesión de Supabase; nunca en `SharedPreferences` en claro.
- No loguees datos de cartera, saldos identificables ni tokens.
- La app es **solo lectura** sobre las cuentas de brókers. No implementes flujos de
  ejecución de órdenes ni movimiento de fondos.
- Datos de usuarios UE → ten presente GDPR (consentimiento, borrado de cuenta).

## 6. Tooling y flujo de trabajo

- **Justfile** es el punto de entrada único para tareas. Antes de inventar un comando,
  mira el `justfile`; si una tarea es habitual, añádele una receta.
- **pre-commit** gestiona los hooks de calidad (`dart format`, `flutter analyze`, etc.),
  integrado con [pre-commit.ci](https://pre-commit.ci/), que corre en cada PR. No te
  saltes los hooks (`--no-verify`) salvo emergencia justificada.
- **Tests con `flutter test`** (unit + widget). Todo cambio de lógica o de componentes
  reutilizables debe llevar tests. `flutter analyze` debe pasar sin warnings.

## 7. Comandos habituales

> Preferir siempre las recetas del Justfile. Ver todas con `just --list`.

```bash
# Recetas (vía Just)
just deps             # flutter pub get
just run              # ejecutar en el target por defecto
just web              # flutter run -d chrome
just desktop          # macOS por defecto (o: just desktop windows | linux)
just test             # flutter test
just analyze          # flutter analyze + dart format --set-exit-if-changed
just format           # dart format in-place
just clean            # flutter clean
just build            # release; apk por defecto (o: just build ios | web | macos | windows | linux)
just hooks            # pre-commit run --all-files
just openapi          # (stub) regenerar cliente OpenAPI — pendiente de cablear (§9)

# Configuración de entorno: NUNCA hardcodees secretos; inyéctalos con --dart-define
flutter run \
  --dart-define=API_BASE_URL=https://api.investepacademy.com \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## 8. Qué NO hacer

- No documentes ni ejecutes comandos sueltos si pueden ser una receta del Justfile.
- No te saltes los hooks de pre-commit con `--no-verify`.
- No mezcles familias de iconos: usa **Lucide** (renderizado nativo) de forma consistente.
- No uses iconos como imágenes rasterizadas, SVG en runtime ni webviews: deben ser
  glifos/vectores nativos compilados en el binario.
- No abuses del blur/glassmorphism hasta provocar jank, sobre todo en web/escritorio.
- No hables directamente con Supabase-DB ni con los brókers: usa la API REST.
- No guardes tokens de brókers ni credenciales en el cliente.
- No implementes ejecución de órdenes ni movimiento de fondos.
- No escribas a mano modelos que ya define el contrato OpenAPI.
- No metas dependencias pesadas específicas de una plataforma sin justificarlo.
- No loguees datos financieros ni credenciales.

## 9. Estado de las decisiones

**Resueltas en el scaffold inicial:**

- ✅ **Gestión de estado:** Riverpod (`flutter_riverpod`), sin code-gen por ahora.
- ✅ **Iconos:** `lucide_icons_flutter` (icon font nativa).
- ✅ **Glassmorphism:** widget propio `GlassCard` (`BackdropFilter` nativo), sin librería externa.
- ✅ **Navegación:** `go_router`.
- ✅ **Recetas del Justfile y config de pre-commit:** ver §7 y `.pre-commit-config.yaml`.

**Pendientes de confirmar / cablear:**

- ⏳ **Herramienta de generación del cliente OpenAPI** para Dart (cablear la receta
  `just openapi`). Hasta entonces, `dio` es sólo el transporte base.
- ⏳ **`riverpod_generator`:** sumarlo cuando el ecosistema 3.x resuelva estable sobre el
  SDK objetivo (hoy choca por `analyzer`/`macros`). Migración sin reescribir lógica.
- ⏳ **Entorno Supabase:** definir `SUPABASE_URL` / `SUPABASE_ANON_KEY` (vía `--dart-define`)
  e inicializar Supabase en el arranque cuando entre la feature de auth.
