#!/bin/bash

set -e

BACKUP_FILE="$1"
CONFIG_DIR="./configuration"

if [ -z "$BACKUP_FILE" ]; then
  echo "Uso: ./restore.sh <archivo_backup.tar.gz>"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: el archivo no existe"
  exit 1
fi

echo "Restaurando backup..."

# detener contenedores
docker compose down

# limpiar configuración
rm -rf "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

# restaurar backup
tar -xzf "$BACKUP_FILE" -C "$CONFIG_DIR"

echo "Corrigiendo permisos..."

# ajustar permisos (clave)
chown -R 1000:1000 "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

echo "Levantando contenedores..."

docker compose up -d

echo "Restauración completada"
