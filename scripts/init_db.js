// Initialize SQLite database for Alternance Tracker
// Usage: node scripts/init_db.js

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const CONTAINER_NAME = 'alternance-tracker-n8n-1';
const DB_PATH = '/data/alternance-tracker.db';
const SCHEMA_FILE = path.join(__dirname, '..', 'schemas', 'v1_initial.sql');

console.log('🔧 Initializing Alternance Tracker database...\n');

// Check if container is running
try {
    const containers = execSync(`docker ps --format "{{.Names}}"`, { encoding: 'utf-8' });
    if (!containers.includes(CONTAINER_NAME)) {
        console.error(`❌ Error: Container ${CONTAINER_NAME} is not running`);
        console.error('   Start it with: docker compose up -d');
        process.exit(1);
    }
} catch (error) {
    console.error('❌ Error checking Docker containers:', error.message);
    process.exit(1);
}

// Check if database exists
let dbExists = false;
try {
    execSync(`docker exec ${CONTAINER_NAME} test -f ${DB_PATH}`, { stdio: 'ignore' });
    dbExists = true;
} catch (error) {
    // Database doesn't exist, which is fine
}

if (dbExists) {
    console.log(`⚠️  Database already exists at ${DB_PATH}`);
    // In production, we'd prompt for confirmation
    // For now, we'll backup and recreate
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const backupName = `alternance-tracker-${timestamp}.db`;
    try {
        execSync(`docker exec ${CONTAINER_NAME} cp ${DB_PATH} /data/${backupName}`);
        console.log(`   Backup saved as: ${backupName}\n`);
    } catch (error) {
        console.error('   Warning: Could not create backup:', error.message);
    }
}

// Read schema file
console.log('📋 Reading schema file...');
let schema;
try {
    schema = fs.readFileSync(SCHEMA_FILE, 'utf-8');
    console.log(`   Schema file: ${SCHEMA_FILE}`);
    console.log(`   Size: ${schema.length} characters\n`);
} catch (error) {
    console.error('❌ Error reading schema file:', error.message);
    process.exit(1);
}

// Install better-sqlite3 in container if not present
console.log('🔧 Setting up SQLite in container...');
try {
    execSync(`docker exec ${CONTAINER_NAME} npm list better-sqlite3 -g`, { stdio: 'ignore' });
    console.log('   SQLite module already installed\n');
} catch (error) {
    console.log('   Installing better-sqlite3...');
    try {
        execSync(`docker exec ${CONTAINER_NAME} npm install -g better-sqlite3`, { stdio: 'inherit' });
        console.log('   ✅ Installed\n');
    } catch (installError) {
        console.error('❌ Failed to install better-sqlite3');
        console.error('   Trying alternative approach...\n');
        
        // Try using node directly without better-sqlite3
        console.log('⚠️  Warning: better-sqlite3 not available');
        console.log('   Creating database initialization script...\n');
    }
}

// Create initialization script
const initScript = `
const fs = require('fs');
const Database = require('better-sqlite3');

const dbPath = '${DB_PATH}';
const db = new Database(dbPath);

const schema = ${JSON.stringify(schema)};

try {
    db.exec(schema);
    console.log('✅ Schema applied successfully');
    
    const tableCount = db.prepare("SELECT COUNT(*) as count FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").get();
    console.log('Tables created:', tableCount.count);
    
    const version = db.prepare('SELECT version FROM schema_version LIMIT 1').get();
    console.log('Schema version:', version.version);
    
    db.close();
} catch (error) {
    console.error('Error applying schema:', error.message);
    process.exit(1);
}
`;

// Write init script to temp file
const tempScriptPath = path.join(__dirname, '..', 'temp_init.js');
fs.writeFileSync(tempScriptPath, initScript);

console.log('🗄️  Creating database and applying schema...');
try {
    // Copy script to container
    execSync(`docker cp "${tempScriptPath}" ${CONTAINER_NAME}:/tmp/init_db.js`);
    
    // Execute script in container
    execSync(`docker exec ${CONTAINER_NAME} node /tmp/init_db.js`, { stdio: 'inherit' });
    
    // Cleanup
    fs.unlinkSync(tempScriptPath);
    execSync(`docker exec ${CONTAINER_NAME} rm /tmp/init_db.js`);
    
    console.log('\n🎉 Done! Database initialized at ' + DB_PATH);
    console.log('\nNext steps:');
    console.log('1. Load test fixtures: node scripts/load_fixtures.js');
    console.log('2. Configure n8n workflows');
    
} catch (error) {
    console.error('❌ Error initializing database:', error.message);
    if (fs.existsSync(tempScriptPath)) {
        fs.unlinkSync(tempScriptPath);
    }
    process.exit(1);
}
