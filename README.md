# 🎬 Media Server Stack

Un stack completo de servidor multimedia autohospedado basado en Docker, con gestión automatizada de contenido, descarga de subtítulos y acceso mediante proxy inverso.

---

## 📦 Servicios

| Servicio | Imagen | Puerto | Descripción |
|---|---|---|---|
| **Jellyfin** | `lscr.io/linuxserver/jellyfin:0.11.6ubu2404-ls24` | `8096` | Servidor multimedia — streaming de películas, series y música |
| **Radarr** | `lscr.io/linuxserver/radarr:6.0.4.10291-ls295` | `7878` | Gestor automático de películas |
| **Sonarr** | `lscr.io/linuxserver/sonarr:4.0.16.2944-ls304` | `8989` | Gestor automático de series |
| **Prowlarr** | `lscr.io/linuxserver/prowlarr:2.3.0.5236-ls139` | `9696` | Gestor de indexadores para Radarr/Sonarr |
| **Bazarr** | `lscr.io/linuxserver/bazarr:v1.5.6-ls341` | `6767` | Descarga automática de subtítulos |
| **qBittorrent** | `lscr.io/linuxserver/qbittorrent:5.1.4-r2-ls445` | `8080` | Cliente de torrents |
| **Nginx Proxy Manager** | `jc21/nginx-proxy-manager:2.14.0` | `80`, `443`, `81` | Proxy inverso con soporte SSL/TLS |
| **Homepage** | `ghcr.io/gethomepage/homepage:v1.11.0` | `3000` | Dashboard de inicio unificado |
| **Seerr** | `ghcr.io/seerr-team/seerr:v3.1.0` | `5056` | Portal de solicitudes de contenido |

---

## 🗂️ Estructura de directorios

```
media-server/
├── docker-compose.yml
├── configuration/
│   ├── jellyfin/
│   │   └── library/          # Configuración y base de datos de Jellyfin
│   ├── radarr/               # Configuración de Radarr
│   ├── sonarr/               # Configuración de Sonarr
│   ├── prowlarr/             # Configuración de Prowlarr
│   ├── bazarr/               # Configuración de Bazarr
│   ├── qbittorrent/          # Configuración de qBittorrent
│   ├── nginx/
│   │   ├── data/             # Datos de Nginx Proxy Manager
│   │   └── letsencrypt/      # Certificados SSL
│   ├── homepage/
│   │   └── config/           # Configuración del dashboard desde services.yml
│   └── seerr/
│       └── config/           # Configuración de Seerr
└── content/
    ├── media/
    │   ├── movies/           # Películas (biblioteca leída desde Jellyfin)
    │   └── series/           # Series (biblioteca leída desde Jellyfin)
    └── torrents/
        ├── movies/           # Descargas de películas en curso (Radarr)
        ├── tv/               # Descargas de series en curso (Sonarr)
        └── torrents_copy/    # Copias de los archivos .torrent (opcional)
```

> ⚠️ Es importante respetar esta estructura para que los volúmenes monten correctamente.

---

## 📁 Directorio `content`

El directorio `content/` es el corazón del stack. Radarr y Sonarr lo montan como `/data`, por lo que tienen visibilidad completa de las descargas y la biblioteca final — lo que permite el **hardlink** entre ambas ubicaciones sin duplicar espacio en disco.

```
content/
├── media/
│   ├── movies/        ← Biblioteca final de películas → Jellyfin
│   └── series/        ← Biblioteca final de series   → Jellyfin
└── torrents/
    ├── movies/        ← Radarr descarga aquí via qBittorrent
    ├── tv/            ← Sonarr descarga aquí via qBittorrent
    └── torrents_copy/ ← Copias de los archivos .torrent (opcional)
```

### Flujo de un archivo

```
qBittorrent descarga → content/torrents/movies/
                                ↓
                       Radarr detecta descarga completada
                                ↓
                       Hardlink / move → content/media/movies/
                                ↓
                       Jellyfin escanea y añade a la biblioteca
```

> 💡 Usar **hardlinks** (en lugar de copias) permite que qBittorrent siga seedando desde `torrents/` mientras Jellyfin sirve el archivo desde `media/`, sin ocupar espacio adicional. Para que esto funcione, `content/` debe estar en el mismo sistema de ficheros.

### Configuración en Radarr / Sonarr

En la configuración de Radarr y Sonarr, las rutas deben apuntar a las carpetas dentro de `/data` (como se monta en el contenedor):

| Servicio | Carpeta raíz de descargas | Carpeta raíz de la biblioteca |
|---|---|---|
| Radarr | `/data/torrents/movies` | `/data/media/movies` |
| Sonarr | `/data/torrents/tv` | `/data/media/series` |

---

## 🚀 Despliegue

### Requisitos previos

- [Docker](https://docs.docker.com/engine/install/) y [Docker Compose](https://docs.docker.com/compose/install/) instalados
- Puertos `80`, `443`, `8096`, `7878`, `8989`, `9696`, `6767`, `8080`, `3000`, `5056` disponibles en el host

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/media-server.git
cd media-server
```

### 2. Crear la estructura de directorios

```bash
mkdir -p configuration/{jellyfin/library,radarr,sonarr,prowlarr,bazarr,qbittorrent,nginx/{data,letsencrypt},homepage/config,seerr/config}
mkdir -p content/media/{movies,series}
mkdir -p content/torrents/{movies,tv,torrents_copy}
```

### 3. Ajustar permisos (opcional)

Los contenedores usan `PUID=1000` y `PGID=1000`. Asegúrate de que tu usuario tiene ese UID/GID o ajusta los valores en el `docker-compose.yml`:

```bash
id tu-usuario
# uid=1000(tu-usuario) gid=1000(tu-usuario) ...
```

### 4. Levantar el stack

```bash
docker compose up -d
```

### 5. Verificar que todo está corriendo

```bash
docker compose ps
```

---

## ⚙️ Configuración inicial

### Nginx Proxy Manager
Accede a `http://IP_DEL_SERVIDOR:81` con las credenciales por defecto:
- **Email:** `admin@example.com`
- **Contraseña:** `changeme`

> ⚠️ Cambia las credenciales inmediatamente tras el primer acceso.

### qBittorrent
Accede a `http://IP_DEL_SERVIDOR:8080`. La contraseña temporal se muestra en los logs:

```bash
docker logs qbittorrent | grep "temporary password"
```

### Flujo de integración recomendado
1. **Prowlarr** → añade indexadores
2. **Radarr / Sonarr** → conecta con Prowlarr y qBittorrent
3. **Bazarr** → conecta con Sonarr y Radarr para subtítulos
4. **Jellyfin** → apunta la biblioteca a `/data`
5. **Seerr** → conecta con Jellyfin, Radarr y Sonarr
6. **Homepage** → configura widgets para cada servicio

---

## 🌐 Red

Todos los servicios comparten la red `media-network` (bridge), lo que permite la comunicación entre contenedores usando el nombre del contenedor como hostname (p. ej. `http://radarr:7878`).

---

## 🔄 Actualización

```bash
docker compose pull
docker compose up -d
```

Para limpiar imágenes antiguas:

```bash
docker image prune -f
```

---

## 📋 Variables de entorno comunes

| Variable | Valor | Descripción |
|---|---|---|
| `PUID` | `1000` | ID de usuario del proceso |
| `PGID` | `1000` | ID de grupo del proceso |
| `TZ` | `Europe/Madrid` | Zona horaria |

---

## 🛑 Parar el stack

```bash
# Parar sin eliminar contenedores
docker compose stop

# Parar y eliminar contenedores (los datos persisten en los volúmenes)
docker compose down
```
