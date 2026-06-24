# syntax=docker/dockerfile:1
# ── build stage ───────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS build

# Instalar dependencias necesarias para Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Descargar Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Inicializar Flutter y habilitar Web
RUN flutter config --enable-web
RUN flutter doctor -v

# Copiar archivos del proyecto
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

# Compilar la aplicación para la plataforma Web
ARG DART_FLAGS=""
RUN flutter build web ${DART_FLAGS} --release

# ── release stage ─────────────────────────────────────────────────────────────
FROM nginx:alpine AS release
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
