#!/bin/bash
# Initialize Alternance Tracker database
# Usage: ./scripts/init_db.sh

set -e

DB_PATH="/data/alternance-tracker.db"
SCHEMA_PATH="./schemas/v1_initial.sql"
CONTAINER_NAME="alternance-tracker-n8n-1"

echo "🔧 Initializing Alternance Tracker database..."

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: Container ${CONTAINER_NAME} is not running"
    echo "   Start it with: docker compose up -d"
    exit 1
fi

# Check if database already exists
if docker exec "${CONTAINER_NAME}" test -f "${DB_PATH}"; then
    echo "⚠️  Database already exists at ${DB_PATH}"
    read -p "   Do you want to recreate it? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "   Aborted."
        exit 0
    fi
    echo "   Backing up existing database..."
    BACKUP_NAME="alternance-tracker-$(date +%Y%m%d-%H%M%S).db"
    docker exec "${CONTAINER_NAME}" cp "${DB_PATH}" "/data/${BACKUP_NAME}"
    echo "   Backup saved as: ${BACKUP_NAME}"
fi

# Copy schema to container
echo "📋 Copying schema to container..."
docker cp "${SCHEMA_PATH}" "${CONTAINER_NAME}:/tmp/schema.sql"

# Initialize database
echo "🗄️  Creating database and applying schema..."
docker exec "${CONTAINER_NAME}" sqlite3 "${DB_PATH}" < /tmp/schema.sql 2>&1 || {
    # If direct redirect fails, try alternative approach
    docker exec "${CONTAINER_NAME}" sh -c "sqlite3 ${DB_PATH} < /tmp/schema.sql"
}

# Verify database
echo "✅ Verifying database..."
TABLE_COUNT=$(docker exec "${CONTAINER_NAME}" sqlite3 "${DB_PATH}" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo "✅ Database initialized successfully!"
    echo "   Tables created: ${TABLE_COUNT}"
    
    # Show schema version
    SCHEMA_VERSION=$(docker exec "${CONTAINER_NAME}" sqlite3 "${DB_PATH}" "SELECT version FROM schema_version LIMIT 1;" 2>/dev/null || echo "unknown")
    echo "   Schema version: ${SCHEMA_VERSION}"
    
    # Show table list
    echo ""
    echo "📊 Tables:"
    docker exec "${CONTAINER_NAME}" sqlite3 "${DB_PATH}" "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;"
else
    echo "❌ Error: Database initialization failed"
    exit 1
fi

echo ""
echo "🎉 Done! You can now use the database at ${DB_PATH}"
echo "   Next steps:"
echo "   1. Load test fixtures: ./scripts/load_fixtures.sh"
echo "   2. Configure n8n workflows"
