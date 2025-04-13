# Docker Volume Backup and Restore Utility

A simple and reliable utility for backing up and restoring Docker volumes across different platforms.

## Features

- 🔄 Backup and restore Docker volumes
- 📦 Create compressed tarballs
- 🔒 Safe volume handling (prevents overwriting existing volumes)
- 🌐 Cross-platform support (macOS, Linux, and Git Bash for Windows)
- 🎨 Aesthetic and informative output
- ✅ Error handling and validation

## Prerequisites

- Docker installed and running
- Bash shell
- Busybox image (will be pulled automatically if not present)

## Installation

1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/yourusername/docker-volume-backup/main/dcrvolbkp.sh
```

2. Make it executable:
```bash
chmod +x dcrvolbkp.sh
```

## Usage

### Backup Volumes

```bash
./dcrvolbkp.sh backup <backup-dir> <volume1> [volume2 ...]
```

Example:
```bash
./dcrvolbkp.sh backup ./backups postgres_data solr_data
```

### Restore Volumes

You can restore volumes in two ways:

1. Restore with the same name:
```bash
./dcrvolbkp.sh restore <backup-dir> <volume1> [volume2 ...]
```

2. Restore with new names:
```bash
./dcrvolbkp.sh restore <backup-dir> <new_name=backup_name> [more...]
```

Examples:
```bash
# Restore with same names
./dcrvolbkp.sh restore ./backups postgres_data solr_data

# Restore with new names
./dcrvolbkp.sh restore ./backups new_pg=postgres_data new_solr=solr_data
```

## Important Notes

- The script will not overwrite existing volumes during restore
- Volume names must follow Docker naming conventions:
  - Start with a letter or number
  - Can only contain letters, numbers, underscores, dots, and hyphens
- Backup files are stored as compressed tarballs (.tar.gz)
- The script requires write permissions in the backup directory

## Error Handling

The script provides clear error messages for common issues:
- Missing arguments
- Invalid volume names
- Non-existent volumes
- Non-existent backup files
- Attempting to restore to existing volumes

## Examples

### Backup multiple volumes
```bash
./dcrvolbkp.sh backup /mnt/backups mysql_data redis_data
```

### Restore with renaming
```bash
./dcrvolbkp.sh restore /mnt/backups staging_mysql=mysql_data staging_redis=redis_data
```

## License

MIT License

## Contributing

Feel free to open issues and pull requests for any improvements or bug fixes. 