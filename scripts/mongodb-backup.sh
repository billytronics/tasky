#!/bin/bash

# MongoDB Backup Script to S3
# Configuration
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_USER="myUserAdmin" #replace with admin user
MONGO_PASS="yourPassword" #replace with user pw
MONGO_AUTH_DB="admin"
BACKUP_DIR="/tmp/mongodb-backups"
S3_BUCKET="your-backup-bucket" #replace with bucket name
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mongodb_backup_${DATE}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v mongodump &> /dev/null; then
        error "mongodump is not installed. Please install MongoDB tools."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install AWS CLI."
        exit 1
    fi
    
    log "All dependencies are available."
}

# Create backup directory
create_backup_dir() {
    log "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
        error "Failed to create backup directory"
        exit 1
    fi
}

# Perform MongoDB backup
backup_mongodb() {
    log "Starting MongoDB backup..."
    
    # Full backup with authentication
    mongodump \
        --host "$MONGO_HOST:$MONGO_PORT" \
        --username "$MONGO_USER" \
        --password "$MONGO_PASS" \
        --authenticationDatabase "$MONGO_AUTH_DB" \
        --out "$BACKUP_DIR/$BACKUP_NAME"
    
    if [ $? -eq 0 ]; then
        log "MongoDB backup completed successfully"
    else
        error "MongoDB backup failed"
        exit 1
    fi
}

# Compress backup
compress_backup() {
    log "Compressing backup..."
    
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    if [ $? -eq 0 ]; then
        log "Backup compressed successfully"
        # Remove uncompressed backup
        rm -rf "$BACKUP_NAME"
    else
        error "Backup compression failed"
        exit 1
    fi
}

# Upload to S3
upload_to_s3() {
    log "Uploading backup to S3..."
    
    aws s3 cp "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" "s3://$S3_BUCKET/mongodb-backups/${BACKUP_NAME}.tar.gz"
    
    if [ $? -eq 0 ]; then
        log "Backup uploaded to S3 successfully"
    else
        error "Failed to upload backup to S3"
        exit 1
    fi
}

# Cleanup local backups (keep last 3 days)
cleanup_local() {
    log "Cleaning up local backups..."
    
    # Remove backups older than 3 days
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +3 -delete
    
    if [ $? -eq 0 ]; then
        log "Local cleanup completed"
    else
        warn "Local cleanup had some issues"
    fi
}

# Cleanup old S3 backups (keep last 30 days)
cleanup_s3() {
    log "Cleaning up old S3 backups..."
    
    # List and delete backups older than 30 days
    aws s3 ls "s3://$S3_BUCKET/mongodb-backups/" | while read -r line; do
        file_date=$(echo "$line" | awk '{print $1}')
        file_name=$(echo "$line" | awk '{print $4}')
        
        if [[ -n "$file_date" && -n "$file_name" ]]; then
            file_epoch=$(date -d "$file_date" +%s)
            cutoff_epoch=$(date -d "30 days ago" +%s)
            
            if [[ $file_epoch -lt $cutoff_epoch ]]; then
                log "Deleting old backup: $file_name"
                aws s3 rm "s3://$S3_BUCKET/mongodb-backups/$file_name"
            fi
        fi
    done
}

# Send notification (optional)
send_notification() {
    local status=$1
    local message=$2
    
    # You can implement email/Slack notifications here
    # For now, just log to system log
    logger "MongoDB Backup: $status - $message"
}

# Main execution
main() {
    log "Starting MongoDB backup process..."
    
    # Check dependencies
    check_dependencies
    
    # Create backup directory
    create_backup_dir
    
    # Perform backup
    backup_mongodb
    
    # Compress backup
    compress_backup
    
    # Upload to S3
    upload_to_s3
    
    # Cleanup
    cleanup_local
    cleanup_s3
    
    # Send success notification
    send_notification "SUCCESS" "MongoDB backup completed successfully: ${BACKUP_NAME}.tar.gz"
    
    log "MongoDB backup process completed successfully!"
}

# Error handling
trap 'error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
