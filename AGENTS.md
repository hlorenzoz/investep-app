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
- ✅ **Entorno Supabase e inicialización:** definidos `SUPABASE_URL` / `SUPABASE_ANON_KEY` (vía `--dart-define` / `--dart-define-from-file`) e inicializados en `lib/main.dart` con validación preventiva de placeholders.

**Pendientes de confirmar / cablear:**

- ⏳ **Herramienta de generación del cliente OpenAPI** para Dart (cablear la receta
  `just openapi`). Hasta entonces, `dio` es sólo el transporte base.
- ⏳ **`riverpod_generator`:** sumarlo cuando el ecosistema 3.x resuelva estable sobre el
  SDK objetivo (hoy choca por `analyzer`/`macros`). Migración sin reescribir lógica.


## 10. Conexión con la API de Investep

Cualquier agente que trabaje en esta base de código debe comprender la siguiente arquitectura de red y autenticación:

### 10.1 Arquitectura de Autenticación en Dos Patas
La API REST de Investep **no tiene un endpoint de login**. La autenticación se realiza de la siguiente manera:

1. **Pata 1 (Login en el Cliente):** El cliente Flutter se conecta directamente a Supabase Auth llamando a `signInWithPassword(email, password)` usando la **anon/publishable key** pública. Supabase retorna un token de acceso JWT (`accessToken`).
   - *Regla Crítica:* El cliente **nunca** utiliza la `service-role` key de Supabase (esta es solo para el servidor y tiene privilegios administrativos).
2. **Pata 2 (Validación del Token con la API):** El cliente Flutter realiza un request `GET /auth/me` a la API REST agregando el header `Authorization: Bearer <accessToken>`. La API valida dicho token con Supabase y responde con los datos del usuario en caso de éxito.

### 10.2 Tabla de Entornos por Rama

Las configuraciones se manejan mediante archivos JSON en la carpeta `config/` y se inyectan usando el parámetro de compilación `--dart-define-from-file=config/<env>.json`.

| Rama / Entorno | Archivo Config | API base URL | Supabase URL | Supabase anon key | Estado |
|---|---|---|---|---|---|
| **devel** (local) | `config/devel.json` | `http://localhost:8787` | `http://127.0.0.1:54321` | Anon key local de Supabase (`sb_publishable_...`) | **Confirmado** (listo para usar localmente) |
| **staging** | `config/staging.json` | `https://investep-app-api-staging.<SUBDOMINIO>.workers.dev` | `https://dmetfwaxotdxtpnlmczi.supabase.co` | Anon key de staging (`sb_publishable_...`) | **Placeholder** (Requiere completar `<SUBDOMINIO>`) |
| **main** (production) | `config/main.json` | `https://investep-app-api-production.<SUBDOMINIO>.workers.dev` | `https://<PROD_REF>.supabase.co` | Anon key de producción | **Placeholder** (Por definir tras despliegue de prod) |

*Nota:* Para evitar crashes en tiempo de ejecución, la app valida que las URLs y keys no contengan caracteres como `<` o `>` antes de inicializar Supabase.

### 10.3 Contratos y Shape de Error de la API

#### `GET /auth/me`
- **Request Header:** `Authorization: Bearer <access_token>`
- **200 OK (Éxito):**
  ```json
  {
    "user": {
      "id": "8f3b1d2e-0a4c-4e6f-9b2a-1c2d3e4f5a6b",
      "email": "user@example.com",
      "mustResetPassword": false
    }
  }
  ```
- **401 Unauthorized (Error de validación de token):**
  ```json
  {
    "error": {
      "code": "UNAUTHORIZED",
      "message": "Token inválido o expirado.",
      "details": []
    }
  }
  ```

#### Formato Único de Error de la API
Todos los errores emitidos por la API REST siguen la estructura `{ error: { code, message, details? } }`. Los códigos de error comunes son:
- `VALIDATION_ERROR` (422)
- `UNAUTHORIZED` (401)
- `FORBIDDEN` (403)
- `NOT_FOUND` (404)
- `CONFLICT` (409)
- `INTERNAL_ERROR` (500)

### 10.4 Notas de Conectividad por Plataforma (Desarrollo Local)
- **iOS Simulator / Web:** La API local es accesible vía `http://localhost:8787` y Supabase local vía `http://127.0.0.1:54321`.
- **Android Emulator:** La máquina local se mapea a la IP de puente loopback `10.0.2.2`. Por lo tanto, se debe cambiar la configuración a `http://10.0.2.2:8787` y `http://10.0.2.2:54321`.
- **Dispositivo Físico:** Se debe configurar la IP local de LAN de la computadora host (ej. `http://192.168.1.XX:8787`).

### 10.5 Obtención de Credenciales de Prueba (Provisionamiento)
No hay registro (sign-up) público en la aplicación cliente. Los usuarios de prueba se crean directamente en el backend mediante comandos CLI:
1. Dirigirse al repositorio del backend (`investep-app-api`).
2. Levantar el entorno local: `just up`
3. Crear el primer usuario administrador: `just create-first-user`
4. Crear un usuario de prueba personalizado: `just create-user <EMAIL>`
5. Usar el email y password generados para iniciar sesión en la app Flutter.


## 11. Guía de Ruteo de Skills locales (`.agents/skills/`)

Este repositorio tiene instaladas **skills personalizadas** que extienden las capacidades de los agentes de IA para tareas repetitivas o complejas. Cuando detectes uno de estos contextos, **leé el archivo `SKILL.md` correspondiente antes de escribir código**.

A continuación se detalla el catálogo y el criterio de ruteo para cada una:

### 11.1 Desarrollo y Arquitectura en Flutter (Core)
*   **[flutter-apply-architecture-best-practices](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md)**: Usala al estructurar nuevas features o refactorizar código para respetar la arquitectura clean/feature-first (separación UI/Presentation, Logic/Providers y Data).
*   **[flutter-build-responsive-layout](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-build-responsive-layout/SKILL.md)**: Usala cuando un widget o pantalla deba adaptarse a diferentes tamaños de pantalla (móvil, tablet, escritorio) mediante `LayoutBuilder`, `MediaQuery` o flexbox.
*   **[flutter-setup-declarative-routing](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-setup-declarative-routing/SKILL.md)**: Usala al agregar, modificar o depurar pantallas y flujos de navegación que involucren `go_router`.
*   **[flutter-setup-localization](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-setup-localization/SKILL.md)**: Usala cuando debas configurar o dar soporte a traducciones o internacionalización multilenguaje (`intl`, `l10n`).
*   **[flutter-implement-json-serialization](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-implement-json-serialization/SKILL.md)**: Usala al codificar modelos de datos en Dart que requieran serialización manual `fromJson` y `toJson`.
*   **[flutter-use-http-package](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-use-http-package/SKILL.md)**: Criterio secundario para peticiones de red directas (recordá priorizar el cliente `Dio` configurado en el core).
*   **[flutter-fix-layout-issues](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-fix-layout-issues/SKILL.md)**: Usala si te encontrás con desbordamientos visuales o errores de constraints ("RenderFlex overflowed", viewport sin altura, etc.).

### 11.2 Componentes, Vistas y Pruebas
*   **[flutter-add-widget-preview](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-add-widget-preview/SKILL.md)**: Usala al crear componentes UI reutilizables para dejarlos registrados en el catálogo interactivo (`previews.dart`).
*   **[flutter-add-widget-test](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-add-widget-test/SKILL.md)**: Usala para implementar pruebas unitarias de renderizado y comportamiento de componentes mediante `WidgetTester`.
*   **[flutter-add-integration-test](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-add-integration-test/SKILL.md)**: Usala cuando necesites cablear y automatizar flujos completos de pruebas de integración nativos con Flutter Driver.

### 11.3 Flujo de Trabajo del Repositorio y Pull Requests
*   **[preparing-pr](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/preparing-pr/SKILL.md)**: Usala siempre antes de abrir un PR o dar por terminado un lote de cambios para ejecutar linters, formateadores locales y pre-commits.
*   **[adding-copyright-headers](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/adding-copyright-headers/SKILL.md)**: Usala al crear nuevos archivos para asegurar que tengan la licencia y cabecera de derechos de autor adecuada.
*   **[adding-changelog-entries](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/adding-changelog-entries/SKILL.md)**: Usala al documentar las modificaciones introducidas en los archivos `CHANGELOG.md` del ecosistema.
*   **[adding-release-notes](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/adding-release-notes/SKILL.md)**: Usala al añadir explicaciones sobre nuevas features o bugfixes al archivo `NEXT_RELEASE_NOTES.md`.
*   **[updating-package-versions](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/updating-package-versions/SKILL.md)**: Usala al resolver problemas de resolución o dependencias cruzadas dentro del monorrepo.

### 11.4 Soporte de Ecosistema GenUI y Firebase
*   **[create-catalog-item](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/create-catalog-item/SKILL.md)**: Usala cuando debas modelar una nueva clase de datos o un widget a partir de esquemas JSON en proyectos que integren `genui`.
*   **[genui-helper](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/genui-helper/SKILL.md)**: Usala para alinear el desarrollo a los estándares de desarrollo, tests y referencias del repositorio GenUI.
*   **[integrate-genui-firebase](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/integrate-genui-firebase/SKILL.md)**: Usala si estás integrando la interfaz generativa `genui` con la lógica de Firebase AI.

### 11.5 Mantenimiento, Calidad y Documentación
*   **[update-llms-text](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/update-llms-text/SKILL.md)**: Usala cuando necesites actualizar, agregar recursos o corregir información en el archivo de contexto `llms.txt`.
*   **[proofread-markdown](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/proofread-markdown/SKILL.md)**: Usala para revisar estilo, redacción y consistencia gramatical de guías y especificaciones markdown.
*   **[authoring-skills](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/authoring-skills/SKILL.md)**: Usala al escribir, modificar o extender las propias directivas de las skills de IA dentro de `.agents/skills/`.
*   **[dart-log-failure-parser](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/dart-log-failure-parser/SKILL.md)**: Usala al analizar fallos crípticos o logs de error extensos generados por el motor de pruebas de Dart/Flutter.
*   **[flutter-pr-checks-finder](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-pr-checks-finder/SKILL.md)**: Usala para rastrear y recuperar logs de fallas en ejecuciones remotas de CI/LUCI.

### 11.6 Tareas especializadas del SDK de Flutter / Engine
*   **[find-release](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/find-release/SKILL.md)**: Usala para determinar en qué versión o canal de Flutter/Dart se encuentra incorporado un commit de Git (SHA).
*   **[flutter-cherry-pick](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/flutter-cherry-pick/SKILL.md)**: Usala al ordenar el traslado de fixes específicos a las ramas estables o candidatas de lanzamiento.
*   **[analyze-github-flake](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/analyze-github-flake/SKILL.md)**: Usala para investigar reportes de issues inestables (flaky) en el repositorio central de Flutter.
*   **[closing-obsolete-issues](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/closing-obsolete-issues/SKILL.md)**: Usala si estás gestionando el mantenimiento del tracker cerrando issues obsoletos o duplicados.
*   **[rebuilding-flutter-tool](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/rebuilding-flutter-tool/SKILL.md)**: Usala cuando requieras recompilar o forzar un rebuild de la herramienta CLI de Flutter.
*   **[updating-android-sdk](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/updating-android-sdk/SKILL.md)**: Usala para gestionar APIs nativas de Android y paquetes CIPD del framework.
*   **[upgrade-browser](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/upgrade-browser/SKILL.md)**: Usala si es necesario actualizar la versión del navegador (Chrome o Firefox) en las pruebas de motor web.
*   **[validate-pr](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/.agents/skills/validate-pr/SKILL.md)**: Usala para levantar y verificar documentación web local de la comunidad de Flutter.
