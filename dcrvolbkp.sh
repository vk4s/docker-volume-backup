#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emojis for visual feedback
INFO="ℹ️"
SUCCESS="✅"
WARNING="⚠️"
ERROR="❌"
BACKUP="📦"
RESTORE="🔄"

MODE="$1"
TARGET_DIR="$2"
shift 2
VOLUMES=("$@")

BUSYBOX_IMAGE="busybox"

print_usage() {
  echo -e "${BLUE}Docker Volume Backup and Restore Utility by @vksh (https://vksh.fyi)${NC}"
  echo -e "${BLUE}=======================================${NC}\n"
  echo -e "${INFO} Usage:"
  echo -e "  $0 backup <backup-dir> <volume1> [volume2 ...]"
  echo -e "  $0 restore <backup-dir> <new_name=backup_name> [more...]"
  echo
  echo -e "${INFO} Examples:"
  echo -e "  $0 backup ./backups solr_data postgres_data"
  echo -e "  $0 restore ./backups solr_data postgres_data"
  echo -e "  $0 restore ./backups my_pg=postgres_data my_solr=solr_data"
  echo
  exit 1
}

if [[ -z "$MODE" || -z "$TARGET_DIR" || "${#VOLUMES[@]}" -eq 0 ]]; then
  print_usage
fi

echo -e "${BLUE}Docker Volume Backup and Restore Utility${NC}"
echo -e "${BLUE}=======================================${NC}\n"

set -e

# Function to check if a volume exists
volume_exists() {
  docker volume inspect "$1" >/dev/null 2>&1
}

# Function to validate backup directory
validate_backup_dir() {
  if [[ ! -d "$1" ]]; then
    echo -e "${ERROR} Backup directory does not exist: $1"
    exit 1
  fi
}

# Function to validate volume names
validate_volume_name() {
  if [[ ! "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
    echo -e "${ERROR} Invalid volume name: $1"
    echo -e "${INFO} Volume names must start with a letter or number and can only contain letters, numbers, underscores, dots, and hyphens."
    exit 1
  fi
}

# Resolve absolute path safely for macOS, Linux, and Git Bash
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # Git Bash on Windows
  ABS_BACKUP_DIR="$(cd "$TARGET_DIR" && pwd -W)"
else
  # macOS and Linux
  ABS_BACKUP_DIR="$(cd "$TARGET_DIR" && pwd)"
fi

mkdir -p "$ABS_BACKUP_DIR"

if [[ "$MODE" == "backup" ]]; then
  for VOLUME in "${VOLUMES[@]}"; do
    validate_volume_name "$VOLUME"
    
    if ! volume_exists "$VOLUME"; then
      echo -e "${ERROR} Volume does not exist: $VOLUME"
      exit 1
    fi

    ARCHIVE="${ABS_BACKUP_DIR}/${VOLUME}.tar.gz"
    echo -e "${BACKUP} Backing up volume: ${BLUE}$VOLUME${NC} → ${GREEN}$ARCHIVE${NC}"
    
    docker run --rm \
      -v "${VOLUME}:/source" \
      -v "$ABS_BACKUP_DIR:/backup" \
      "$BUSYBOX_IMAGE" \
      tar czf "/backup/${VOLUME}.tar.gz" -C /source .
    
    echo -e "${SUCCESS} Backup completed for volume: $VOLUME"
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

    validate_volume_name "$NEW_VOLUME"
    ARCHIVE="${ABS_BACKUP_DIR}/${ARCHIVE_NAME}.tar.gz"

    if [[ ! -f "$ARCHIVE" ]]; then
      echo -e "${ERROR} Archive not found: $ARCHIVE"
      exit 1
    fi

    if volume_exists "$NEW_VOLUME"; then
      echo -e "${WARNING} Volume already exists: $NEW_VOLUME"
      echo -e "${INFO} Please choose a different name or remove the existing volume first."
      exit 1
    fi

    echo -e "${RESTORE} Restoring: ${BLUE}${ARCHIVE_NAME}.tar.gz${NC} → volume '${GREEN}${NEW_VOLUME}${NC}'"
    docker volume create "$NEW_VOLUME" >/dev/null

    docker run --rm \
      -v "${NEW_VOLUME}:/restore" \
      -v "$ABS_BACKUP_DIR:/backup" \
      "$BUSYBOX_IMAGE" \
      tar xzf "/backup/${ARCHIVE_NAME}.tar.gz" -C /restore
    
    echo -e "${SUCCESS} Restore completed for volume: $NEW_VOLUME"
  done

else
  echo -e "${ERROR} Invalid mode: $MODE. Use 'backup' or 'restore'."
  print_usage
fi

echo -e "\n${SUCCESS} Operation completed successfully!"