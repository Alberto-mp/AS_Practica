#!/bin/bash

set -e

BACKUP_DIR="/srv/nas/backups"
FECHA=$(date +%Y-%m-%d_%H-%M)

echo "[BACKUP] Iniciando copias de seguridad a las $(date)"

# Resolver IP de los contenedores vía DNS o hosts configurado
PG_HOST=$(getent hosts mysql-prod.prod.local  | awk '{ print $1 }')
MYSQL_HOST=$(getent hosts mysql-dev.dev.local | awk '{ print $1 }')

# Comprobación de resolución
if [ -z "$PG_HOST" ]; then
    echo "[ERROR] No se pudo resolver postgres_db"
    exit 1
fi

if [ -z "$MYSQL_HOST" ]; then
    echo "[ERROR] No se pudo resolver mysql_dev"
    exit 1
fi

echo "[INFO] IP PostgreSQL: $PG_HOST"
echo "[INFO] IP MySQL: $MYSQL_HOST"

# Backup PostgreSQL
echo "[POSTGRES] Realizando backup de PostgreSQL..."
PGPASSWORD=drupalpass pg_dump -h "$PG_HOST" -U drupaluser drupal > "$BACKUP_DIR/pg_backup_$FECHA.sql"

# Backup MySQL
echo "[MYSQL] Realizando backup de MySQL..."
mysqldump -h "$MYSQL_HOST" -u drupal -pdrupal drupal > "$BACKUP_DIR/mysql_backup_$FECHA.sql"

echo "[BACKUP] Copias completadas correctamente en $BACKUP_DIR"