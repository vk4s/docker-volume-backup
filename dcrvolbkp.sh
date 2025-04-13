#!/bin/bash

echo "Docker Volume Backup and Restore Utility"

set -e

MODE="$1"
TARGET_DIR="$2"
shift 2
VOLUMES=("$@")

BUSYBOX_IMAGE="busybox"

print_usage() {
  echo "Usage:"
  echo "  $0 backup <backup-dir> <volume1> [volume2 ...]"
  echo "  $0 restore <backup-dir> <new_name=backup_name> [more...]"
  echo
  echo "Examples:"
  echo "  $0 backup ./backups solr_data postgres_data"
  echo "  $0 restore ./backups solr_data postgres_data"
  echo "  $0 restore ./backups my_pg=postgres_data my_solr=solr_data"
  echo
  exit 1
}

if [[ -z "$MODE" || -z "$TARGET_DIR" || "${#VOLUMES[@]}" -eq 0 ]]; then
  print_usage
fi

# Resolve absolute path safely for macOS and Linux
ABS_BACKUP_DIR="$(cd "$TARGET_DIR"; pwd)"
mkdir -p "$ABS_BACKUP_DIR"

if [[ "$MODE" == "backup" ]]; then
  for VOLUME in "${VOLUMES[@]}"; do
    ARCHIVE="${ABS_BACKUP_DIR}/${VOLUME}.tar.gz"
    echo "📦 Backing up volume: $VOLUME → $ARCHIVE"
    docker run --rm \
      -v "${VOLUME}:/source" \
      -v "$ABS_BACKUP_DIR:/backup" \
      "$BUSYBOX_IMAGE" \
      tar czf "/backup/${VOLUME}.tar.gz" -C /source .
  done

elif [[ "$MODE" == "restore" ]]; then
  for VOLUME_ARG in "${VOLUMES[@]}"; do
    if [[ "$VOLUME_ARG" == *"="* ]]; then
      NEW_VOLUME="${VOLUME_ARG%%=*}"
      ARCHIVE_NAME="${VOLUME_ARG##*=}"
    else
      NEW_VOLUME="$VOLUME_ARG"
      ARCHIVE_NAME="$VOLUME_ARG"
    fi

    ARCHIVE="${ABS_BACKUP_DIR}/${ARCHIVE_NAME}.tar.gz"

    if [[ ! -f "$ARCHIVE" ]]; then
      echo "❌ Archive not found: $ARCHIVE"
      exit 1
    fi

    echo "🔄 Restoring: ${ARCHIVE_NAME}.tar.gz → volume '${NEW_VOLUME}'"
    docker volume create "$NEW_VOLUME" >/dev/null

    docker run --rm \
      -v "${NEW_VOLUME}:/restore" \
      -v "$ABS_BACKUP_DIR:/backup" \
      "$BUSYBOX_IMAGE" \
      tar xzf "/backup/${ARCHIVE_NAME}.tar.gz" -C /restore
  done

else
  echo "❌ Invalid mode: $MODE. Use 'backup' or 'restore'."
  print_usage
fi

echo "✅ Done."