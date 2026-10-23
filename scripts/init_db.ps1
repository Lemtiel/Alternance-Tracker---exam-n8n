# Initialize Alternance Tracker database (Windows PowerShell version - Fixed)
# Usage: .\scripts\init_db.ps1

$ErrorActionPreference = "Stop"

$DB_PATH = "/data/alternance-tracker.db"
$SCHEMA_PATH = ".\schemas\v1_initial.sql"
$CONTAINER_NAME = "alternance-tracker-n8n-1"

Write-Host "Initializing Alternance Tracker database..." -ForegroundColor Cyan

# Check if container is running
$containerRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "^$CONTAINER_NAME$"
if (-not $containerRunning) {
    Write-Host "Error: Container $CONTAINER_NAME is not running" -ForegroundColor Red
    Write-Host "Start it with: docker compose up -d"
    exit 1
}

# Check if database already exists
$dbExists = docker exec $CONTAINER_NAME test -f $DB_PATH 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Database already exists at $DB_PATH" -ForegroundColor Yellow
    $confirm = Read-Host "Do you want to recreate it? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Aborted."
        exit 0
    }
    Write-Host "Backing up existing database..."
    $backupName = "alternance-tracker-$(Get-Date -Format 'yyyyMMdd-HHmmss').db"
    docker exec $CONTAINER_NAME cp $DB_PATH "/data/$backupName" | Out-Null
    Write-Host "Backup saved as: $backupName" -ForegroundColor Green
}

# Copy schema to container
Write-Host "Copying schema to container..." -ForegroundColor Cyan
docker cp $SCHEMA_PATH "${CONTAINER_NAME}:/tmp/schema.sql" | Out-Null

# Initialize database using cat to read file content
Write-Host "Creating database and applying schema..." -ForegroundColor Cyan
docker exec $CONTAINER_NAME sh -c "cat /tmp/schema.sql | sqlite3 $DB_PATH"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Database initialization failed" -ForegroundColor Red
    exit 1
}

# Verify database
Write-Host "Verifying database..." -ForegroundColor Cyan
$tableCount = docker exec $CONTAINER_NAME sqlite3 $DB_PATH "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';"

if ([int]$tableCount -gt 0) {
    Write-Host "Database initialized successfully!" -ForegroundColor Green
    Write-Host "Tables created: $tableCount"
    
    # Show schema version
    $schemaVersion = docker exec $CONTAINER_NAME sqlite3 $DB_PATH "SELECT version FROM schema_version LIMIT 1;" 2>$null
    if (-not $schemaVersion) { $schemaVersion = "unknown" }
    Write-Host "Schema version: $schemaVersion"
    
    # Show table list
    Write-Host ""
    Write-Host "Tables:" -ForegroundColor Cyan
    docker exec $CONTAINER_NAME sqlite3 $DB_PATH "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;"
} else {
    Write-Host "Error: Database initialization failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done! You can now use the database at $DB_PATH" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Load test fixtures: .\scripts\load_fixtures.ps1"
Write-Host "2. Configure n8n workflows"
