# Justfile — punto de entrada único de tareas para investep-app.
# Ver recetas: `just --list`. Preferí SIEMPRE estas recetas sobre comandos sueltos.

# Lista las recetas disponibles (receta por defecto).
default:
    @just --list

# Instala/actualiza dependencias.
deps:
    flutter pub get

# Ejecuta en el dispositivo/target por defecto.
run:
    flutter run

# Ejecuta la versión web (la app, no el sitio público).
web:
    flutter run -d chrome

# Ejecuta en escritorio (override: just desktop windows | linux).
desktop target="macos":
    flutter run -d {{target}}

# Corre los tests (unit + widget + integration).
test:
    flutter test
    @if [ -d "integration_test" ]; then flutter test integration_test; fi

# Analiza el código y verifica formato. Debe pasar SIN warnings.
analyze:
    flutter analyze
    dart format --set-exit-if-changed .

# Formatea el código in-place.
format:
    dart format .

# Limpia artefactos de build.
clean:
    flutter clean

# Builds de release por plataforma (override: just build apk | ios | web | macos | windows | linux).
build target="apk":
    flutter build {{target}} --release

# Corre todos los hooks de pre-commit sobre el repo.
hooks:
    pre-commit run --all-files

# Levanta el cliente web en un contenedor Docker (puerto 8080, desarrollo local).
docker-up:
    docker compose up -d --build

# Apaga el contenedor Docker del cliente web.
docker-down:
    docker compose down

# Monitorea cambios y rebuildea el contenedor Docker automáticamente.
watch:
    docker compose watch


# --- Pendientes de cablear cuando estén las herramientas (ver AGENTS.md §9) ---

# Regenera el cliente Dart contra el spec OpenAPI de investep-app-api.
# TODO: definir la herramienta de generación y completar esta receta.
openapi:
    @echo "TODO: generar cliente OpenAPI (ver AGENTS.md §9)"
