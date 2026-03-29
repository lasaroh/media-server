# 🎬 Media Server Stack

Un stack completo de servidor multimedia autohospedado basado en Docker, con gestión automatizada de contenido, descarga de subtítulos y acceso mediante proxy inverso.

---

## 📦 Servicios

| Servicio | Imagen | Puerto | Descripción |
|---|---|---|---|
| **Jellyfin** | `lscr.io/linuxserver/jellyfin` | `8096` | Servidor multimedia — streaming de películas, series y música |
| **Radarr** | `lscr.io/linuxserver/radarr` | `7878` | Gestor automático de películas |
| **Sonarr** | `lscr.io/linuxserver/sonarr` | `8989` | Gestor automático de series |
| **Prowlarr** | `lscr.io/linuxserver/prowlarr` | `9696` | Gestor de indexadores para Radarr/Sonarr |
| **Bazarr** | `lscr.io/linuxserver/bazarr` | `6767` | Descarga automática de subtítulos |
| **qBittorrent** | `lscr.io/linuxserver/qbittorrent` | `8080` | Cliente de torrents |
| **Nginx Proxy Manager** | `jc21/nginx-proxy-manager` | `80`, `443`, `81` | Proxy inverso con soporte SSL/TLS |
| **Seerr** | `ghcr.io/seerr-team/seerr` | `5056` | Portal de solicitudes de contenido |
| **Homepage** | `ghcr.io/gethomepage/homepage` | `3000` | Dashboard de inicio unificado |

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
    ├── media/                # Biblioteca de medios consumida por Jellyfin.
    │   ├── movies/
    │   └── series/
    └── torrents/             # Carpeta donde qbittorrent descarga el contenido y lo sedea a otros usuarios del enjambre.
        ├── movies/
        ├── tv/
        └── torrents_copy/    # Copias de los archivos .torrent (opcional).
```

## 🌐 Comunicación entre servicios
 
Todos los contenedores comparten la red `media-network` (bridge de Docker). Esto permite que se comuniquen entre sí usando el **nombre del contenedor como hostname**, sin exponer puertos innecesarios al exterior.

---

## 🔄 Flujo del stack
 
El stack funciona como un pipeline automatizado de extremo a extremo: desde que el usuario solicita contenido hasta que lo tiene disponible para reproducir en Jellyfin, con subtítulos incluidos y sin intervención manual.

**1. Acceso y enrutamiento**
 
Todo el tráfico externo entra por **Nginx Proxy Manager**, que actúa como proxy inverso con terminación SSL/TLS. Desde ahí se enruta hacia Jellyfin (reproducción) o Seerr (solicitudes).

**2. Solicitud de contenido**
 
El usuario solicita una película o serie a través de **Seerr**. Seerr envía la petición al gestor correspondiente: **Radarr** para películas o **Sonarr** para series.

**3. Búsqueda en indexadores**
 
Radarr y Sonarr consultan a **Prowlarr**, que centraliza todos los indexadores (trackers) y devuelve los resultados disponibles. Prowlarr evita tener que configurar los indexadores por separado en cada aplicación.

**4. Descarga**
 
Radarr o Sonarr envían el torrent seleccionado a **qBittorrent**, que descarga el contenido en:
 
```
content/
└── torrents/
    ├── movies/   ← descargas de Radarr
    └── tv/       ← descargas de Sonarr
```

**5. Hardlink a la biblioteca**
 
Una vez completa la descarga, Radarr y Sonarr crean un **hardlink** del archivo desde `torrents/` hacia `media/`:
 
```
content/
└── media/
    ├── movies/   ← hardlink desde torrents/movies/
    └── series/   ← hardlink desde torrents/tv/
```
 
> 💡 El hardlink apunta al mismo inode en disco, por lo que **no ocupa espacio adicional**. qBittorrent puede seguir sedeando desde `torrents/` mientras Jellyfin sirve el archivo desde `media/`. Para que los hardlinks funcionen, `torrents/` y `media/` deben estar en el **mismo sistema de ficheros** (ambas cuelgan de `content/`).

**7. Reproducción**
 
**Jellyfin** sirve el contenido desde `media/` al usuario final a través de Nginx, con los subtítulos ya disponibles.
