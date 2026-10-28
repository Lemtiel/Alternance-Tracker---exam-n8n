# Load fixtures into Alternance Tracker database (PowerShell)
# Usage: .\scripts\load_fixtures.ps1

$ErrorActionPreference = "Stop"

$DB_PATH = "/data/alternance-tracker.db"
$CONTAINER_NAME = "alternance-tracker-n8n-1"
$FIXTURES_DIR = ".\fixtures"

Write-Host "📦 Loading test fixtures into database..." -ForegroundColor Cyan

# Check if container is running
$containerRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "^$CONTAINER_NAME$"
if (-not $containerRunning) {
    Write-Host "❌ Error: Container $CONTAINER_NAME is not running" -ForegroundColor Red
    exit 1
}

# Check if database exists
$dbExists = docker exec $CONTAINER_NAME test -f $DB_PATH 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Database not found at $DB_PATH" -ForegroundColor Red
    Write-Host "   Run .\scripts\init_db.ps1 first"
    exit 1
}

Write-Host "👤 Loading user..." -ForegroundColor Cyan

# Load profile fixture to get user data
$profileData = Get-Content "$FIXTURES_DIR\profile_junior_dev.json" | ConvertFrom-Json

$userId = $profileData.userId
$userEmail = $profileData.email
$userName = $profileData.displayName
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Insert user
$userSql = @"
INSERT OR IGNORE INTO users (id, email, display_name, created_at, updated_at)
VALUES ('$userId', '$userEmail', '$userName', '$now', '$now');
"@

docker exec $CONTAINER_NAME sqlite3 $DB_PATH $userSql

Write-Host "✅ User created: $userName" -ForegroundColor Green

# Insert configuration
Write-Host "⚙️  Loading configuration..." -ForegroundColor Cyan

$configId = "config-$userId"
$configSql = @"
INSERT OR IGNORE INTO configuration (
  id, user_id, version,
  gmail_enabled, drive_enabled, llm_provider, llm_model,
  search_keywords, excluded_keywords, locations, contract_types,
  scoring_weights, min_score_threshold,
  notifications_enabled,
  created_at, updated_at
) VALUES (
  '$configId', '$userId', 1,
  0, 0, 'openai', 'gpt-4',
  '["développeur", "full-stack", "data", "python", "javascript"]',
  '["stage", "CDD"]',
  '["Paris", "Île-de-France", "Toulouse"]',
  '["alternance", "apprentissage"]',
  '{"skills": 40, "experience": 30, "education": 20, "location": 10}',
  50,
  1,
  '$now', '$now'
);
"@

docker exec $CONTAINER_NAME sqlite3 $DB_PATH $configSql

Write-Host "✅ Configuration created" -ForegroundColor Green

# Insert profile
Write-Host "📄 Loading profile..." -ForegroundColor Cyan

$profileId = "profile-$userId-v1"
$personalInfo = $profileData.personalInfo | ConvertTo-Json -Compress -Depth 10
$education = $profileData.education | ConvertTo-Json -Compress -Depth 10
$experience = $profileData.experience | ConvertTo-Json -Compress -Depth 10
$skills = $profileData.skills | ConvertTo-Json -Compress -Depth 10
$languages = $profileData.languages | ConvertTo-Json -Compress -Depth 10
$projects = $profileData.projects | ConvertTo-Json -Compress -Depth 10

# Escape single quotes for SQL
$personalInfo = $personalInfo -replace "'", "''"
$education = $education -replace "'", "''"
$experience = $experience -replace "'", "''"
$skills = $skills -replace "'", "''"
$languages = $languages -replace "'", "''"
$projects = $projects -replace "'", "''"

$profileSql = @"
INSERT OR IGNORE INTO profiles (
  id, user_id, version,
  source_filename, extracted_at,
  personal_info, education, experience, skills, languages, projects,
  raw_text, extraction_confidence, uncertain_elements,
  human_verified,
  created_at, updated_at
) VALUES (
  '$profileId', '$userId', 1,
  'CV_Jean_Dupont.pdf', '$now',
  '$personalInfo', '$education', '$experience', '$skills', '$languages', '$projects',
  'CV Jean Dupont - Développeur Full-Stack...', 0.92, '[]',
  1,
  '$now', '$now'
);
"@

docker exec $CONTAINER_NAME sqlite3 $DB_PATH $profileSql

Write-Host "✅ Profile created (version 1)" -ForegroundColor Green

# Load offers
Write-Host "💼 Loading offers..." -ForegroundColor Cyan

$offers = @(
    "offer_airbus_fullstack.json",
    "offer_thales_data.json"
)

foreach ($offerFile in $offers) {
    $offerData = Get-Content "$FIXTURES_DIR\$offerFile" | ConvertFrom-Json
    
    $offerId = $offerData.offerId
    $title = $offerData.title -replace "'", "''"
    $company = $offerData.companyName
    $domain = $offerData.companyDomain
    $desc = $offerData.description -replace "'", "''"
    $location = $offerData.location
    $contract = $offerData.contractType
    $salary = $offerData.salaryRange
    $startDate = $offerData.startDate
    $contactEmail = $offerData.contactEmail
    $contactName = $offerData.contactName
    $appUrl = $offerData.applicationUrl
    $posted = $offerData.postedAt
    $expires = $offerData.expiresAt
    $source = $offerData.externalSource
    
    $offerSql = @"
INSERT OR IGNORE INTO offers (
  id, user_id,
  external_id, external_source, external_url,
  title, company_name, company_domain, description,
  location, contract_type, salary_range, start_date,
  contact_email, contact_name, application_url,
  posted_at, expires_at, last_checked_at,
  availability_status, status,
  created_at, updated_at
) VALUES (
  '$offerId', '$userId',
  '$offerId', '$source', '$appUrl',
  '$title', '$company', '$domain', '$desc',
  '$location', '$contract', '$salary', '$startDate',
  '$contactEmail', '$contactName', '$appUrl',
  '$posted', '$expires', '$now',
  'available', 'new',
  '$now', '$now'
);
"@
    
    docker exec $CONTAINER_NAME sqlite3 $DB_PATH $offerSql
    Write-Host "  ✅ $company - $title" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Fixtures loaded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Database summary:" -ForegroundColor Cyan

# Show summary
$userCount = docker exec $CONTAINER_NAME sqlite3 $DB_PATH "SELECT COUNT(*) FROM users;"
$profileCount = docker exec $CONTAINER_NAME sqlite3 $DB_PATH "SELECT COUNT(*) FROM profiles;"
$offerCount = docker exec $CONTAINER_NAME sqlite3 $DB_PATH "SELECT COUNT(*) FROM offers;"

Write-Host "   Users: $userCount"
Write-Host "   Profiles: $profileCount"
Write-Host "   Offers: $offerCount"
Write-Host ""
Write-Host "✨ You can now test workflows in n8n!"
Write-Host "   Access n8n at: http://localhost:5678"
