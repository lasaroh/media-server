#!/bin/bash

set -e

BACKUP_DIR="./backups"
CONFIG_DIR="./configuration"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

mkdir -p "$BACKUP_DIR"

echo "Deteniendo contenedores..."
docker compose down

echo "Creando backup..."
tar -czf "$BACKUP_DIR/configuration_$DATE.tar.gz" -C "$CONFIG_DIR" .

echo "Levantando contenedores..."
docker compose up -d

echo "Backup creado: $BACKUP_DIR/configuration_$DATE.tar.gz"
