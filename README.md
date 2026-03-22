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
├── configuration/            # Configuración de los servicios
│   ├── jellyfin/
│   ├── radarr/
│   ├── sonarr/
│   ├── prowlarr/
│   ├── bazarr/
│   ├── qbittorrent/
│   ├── nginx/
│   ├── homepage/
│   └── seerr/
└── content/
    ├── media/                # Sonarr & Radarr se encargan de hacer un hardlink a esta carpeta
    │   ├── movies/           # Películas (biblioteca leída desde Jellyfin)
    │   └── series/           # Series (biblioteca leída desde Jellyfin)
    |   └── MiRSS/            # Serie en emisión que descarga los nuevos capítulos en cuanto se publican en el tracker
    └── torrents/             # Carpeta donde qbittorrent descarga el contenido y lo sedea a otros usuarios del enjambre.
        ├── movies/           # Descargas de películas en curso (Radarr)
        ├── tv/               # Descargas de series en curso (Sonarr)
        └── torrents_copy/    # Copias de los archivos .torrent (opcional)
```

> 💡 Usar **hardlinks** (en lugar de copias) permite que qBittorrent siga seedando desde `torrents/` mientras Jellyfin sirve el archivo desde `media/`, sin ocupar espacio adicional. Para que esto funcione, `content/` debe estar en el mismo sistema de ficheros.

### Configuración en Radarr / Sonarr

En la configuración de Radarr y Sonarr, las rutas deben apuntar a las carpetas dentro de `/data` (como se monta en el contenedor):

| Servicio | Carpeta raíz de descargas | Carpeta raíz de la biblioteca |
|---|---|---|
| Radarr | `/data/torrents/movies` | `/data/media/movies` |
| Sonarr | `/data/torrents/tv` | `/data/media/series` |

## 🌐 Red

Todos los servicios comparten la red `media-network` (bridge), lo que permite la comunicación entre contenedores usando el nombre del contenedor como hostname (p. ej. `http://radarr:7878`).

---

## 📋 Variables de entorno comunes

| Variable | Valor | Descripción |
|---|---|---|
| `PUID` | `1000` | ID de usuario del proceso |
| `PGID` | `1000` | ID de grupo del proceso |
| `TZ` | `Europe/Madrid` | Zona horaria |

---
