-- Alternance Tracker Database Schema v1.0
-- SQLite version
-- Created: 2026-10-22
-- MVP scope: WF0-6 + WF10 (without automatic followups)

-- ============================================================================
-- USERS AND CONFIGURATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,  -- UUID v4
  email TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  created_at TEXT NOT NULL,  -- ISO 8601 UTC
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS configuration (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  version INTEGER NOT NULL DEFAULT 1,
  
  -- Integrations
  gmail_enabled INTEGER DEFAULT 0,  -- BOOLEAN as INTEGER (SQLite)
  gmail_email TEXT,
  drive_enabled INTEGER DEFAULT 0,
  drive_folder_id TEXT,
  llm_provider TEXT,  -- 'openai', 'anthropic', etc.
  llm_model TEXT,
  
  -- Search preferences (JSON strings)
  search_keywords TEXT,  -- JSON array
  excluded_keywords TEXT,  -- JSON array
  locations TEXT,  -- JSON array
  contract_types TEXT,  -- JSON array: ['alternance', 'apprentissage']
  
  -- Scoring rules (JSON)
  scoring_weights TEXT,  -- JSON object: {skills: 40, experience: 30, education: 20, location: 10}
  min_score_threshold INTEGER DEFAULT 50,
  
  -- Notifications
  notifications_enabled INTEGER DEFAULT 1,
  notification_types TEXT,  -- JSON array
  
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  
  UNIQUE(user_id, version)
);

-- ============================================================================
-- PROFILES
-- ============================================================================

CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  version INTEGER NOT NULL DEFAULT 1,
  
  -- Source metadata
  source_file_id TEXT,  -- Drive file ID
  source_filename TEXT,
  source_filepath TEXT,  -- Local path if uploaded
  extracted_at TEXT,
  
  -- Structured content (JSON)
  personal_info TEXT NOT NULL,  -- {firstName, lastName, email, phone, location}
  education TEXT NOT NULL,  -- [{degree, institution, startDate, endDate}]
  experience TEXT NOT NULL,  -- [{title, company, startDate, endDate, description}]
  skills TEXT NOT NULL,  -- [{name, level, category}]
  languages TEXT NOT NULL,  -- [{language, level}]
  certifications TEXT,  -- [{name, issuer, date}]
  projects TEXT,  -- [{name, description, technologies, url}]
  
  -- Extraction quality
  raw_text TEXT,
  extraction_confidence REAL CHECK(extraction_confidence >= 0.0 AND extraction_confidence <= 1.0),
  uncertain_elements TEXT,  -- JSON array of elements to confirm
  
  -- Verification (human validation required in MVP)
  human_verified INTEGER DEFAULT 0,
  verified_at TEXT,
  verification_notes TEXT,
  
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  
  UNIQUE(user_id, version)
);

-- ============================================================================
-- OFFERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS offers (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- External identifiers
  external_id TEXT,
  external_source TEXT,  -- 'email_alert', 'manual', 'api_francetravail', etc.
  external_url TEXT,
  
  -- Content
  title TEXT NOT NULL,
  company_name TEXT NOT NULL,
  company_domain TEXT,  -- for email matching (e.g., 'airbus.com')
  description TEXT NOT NULL,
  location TEXT,
  contract_type TEXT,
  salary_range TEXT,
  start_date TEXT,
  
  -- Contact
  contact_email TEXT,
  contact_name TEXT,
  application_url TEXT,
  
  -- Metadata
  posted_at TEXT,
  expires_at TEXT,
  last_checked_at TEXT,
  availability_status TEXT DEFAULT 'available',  -- 'available', 'expired', 'filled', 'removed'
  
  -- Internal status
  status TEXT DEFAULT 'new',  -- 'new', 'analyzed', 'rejected', 'archived'
  
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  
  UNIQUE(external_source, external_id)
);

CREATE INDEX idx_offers_user_status ON offers(user_id, status);
CREATE INDEX idx_offers_company ON offers(company_name, company_domain);

-- ============================================================================
-- OFFER ANALYSES
-- ============================================================================

CREATE TABLE IF NOT EXISTS offer_analyses (
  id TEXT PRIMARY KEY,
  offer_id TEXT NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
  profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Scoring
  score INTEGER NOT NULL CHECK(score >= 0 AND score <= 100),
  scoring_details TEXT NOT NULL,  -- JSON: breakdown by criteria
  
  -- Qualitative analysis
  matching_skills TEXT,  -- JSON array
  missing_skills TEXT,  -- JSON array
  strengths TEXT,  -- JSON array
  concerns TEXT,  -- JSON array
  recommendation TEXT NOT NULL,  -- 'apply', 'consider', 'skip'
  rationale TEXT NOT NULL,
  
  -- Provenance
  analyzed_by TEXT NOT NULL,  -- 'llm:gpt-4', 'manual', etc.
  model_version TEXT,
  
  created_at TEXT NOT NULL,
  
  UNIQUE(offer_id, profile_id)
);

CREATE INDEX idx_analyses_score ON offer_analyses(score DESC);

-- ============================================================================
-- APPLICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS applications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  offer_id TEXT NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
  profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Unique tracking reference (for email matching)
  tracking_ref TEXT UNIQUE NOT NULL,  -- 'APP-a3f5e89c' generated by WF6
  
  -- Primary status
  status TEXT NOT NULL DEFAULT 'draft',
  -- MVP statuses:
  -- 'draft': documents being prepared
  -- 'ready': draft email created, ready to send
  -- 'sent': manually sent and confirmed by user
  -- 'response_received': response received (manual tracking in MVP)
  -- 'interview_scheduled': interview scheduled
  -- 'rejected': rejection received
  -- 'accepted': offer accepted
  -- 'withdrawn': application withdrawn
  -- 'closed': closed for any reason
  
  -- Key dates
  draft_created_at TEXT,
  sent_at TEXT,  -- manually entered in MVP
  last_response_at TEXT,
  closed_at TEXT,
  
  -- Tracking counters
  response_count INTEGER DEFAULT 0,
  
  -- User notes
  notes TEXT,
  
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  
  UNIQUE(user_id, offer_id)
);

CREATE INDEX idx_applications_user_status ON applications(user_id, status);
CREATE INDEX idx_applications_tracking_ref ON applications(tracking_ref);

-- ============================================================================
-- DOCUMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  application_id TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Type and format
  document_type TEXT NOT NULL,  -- 'cv', 'cover_letter', 'email_body'
  format TEXT NOT NULL,  -- 'pdf', 'docx', 'txt', 'html', 'markdown'
  
  -- Storage
  storage_type TEXT NOT NULL,  -- 'drive', 'local'
  storage_id TEXT,  -- Drive file ID or local path
  filename TEXT NOT NULL,
  
  -- Generation
  generated_by TEXT NOT NULL,  -- 'llm:gpt-4', 'template', 'manual'
  template_id TEXT,
  generation_params TEXT,  -- JSON: parameters used
  
  -- Content (for text formats)
  content TEXT,
  
  -- Verification (human validation required in MVP)
  verification_status TEXT DEFAULT 'pending',  -- 'pending', 'verified', 'needs_review'
  verification_notes TEXT,
  human_verified INTEGER DEFAULT 0,
  verified_at TEXT,
  
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX idx_documents_application ON documents(application_id, document_type);

-- ============================================================================
-- MESSAGES (for future WF7-8, stored but not auto-processed in MVP)
-- ============================================================================

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Provider identifiers
  provider TEXT NOT NULL,  -- 'gmail', 'outlook'
  message_id TEXT NOT NULL,  -- unique message ID
  thread_id TEXT,
  
  -- Classification
  message_type TEXT NOT NULL,  -- 'sent', 'received', 'draft'
  direction TEXT NOT NULL,  -- 'outbound', 'inbound'
  
  -- Content
  subject TEXT,
  from_email TEXT,
  from_name TEXT,
  to_emails TEXT NOT NULL,  -- JSON array
  cc_emails TEXT,  -- JSON array
  body_plain TEXT,
  body_html TEXT,
  
  -- Metadata
  sent_at TEXT,
  received_at TEXT,
  labels TEXT,  -- JSON array
  has_attachments INTEGER DEFAULT 0,
  attachment_names TEXT,  -- JSON array
  
  -- Synchronization
  synced_at TEXT NOT NULL,
  
  -- Manual tracking ref extraction (MVP)
  extracted_tracking_ref TEXT,  -- parsed from subject if present
  
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  
  UNIQUE(provider, message_id)
);

CREATE INDEX idx_messages_user_type ON messages(user_id, message_type, direction);
CREATE INDEX idx_messages_tracking_ref ON messages(extracted_tracking_ref);

-- ============================================================================
-- EVENTS (audit trail)
-- ============================================================================

CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Related entity
  entity_type TEXT NOT NULL,  -- 'application', 'document', 'offer', etc.
  entity_id TEXT NOT NULL,
  
  -- Event
  event_type TEXT NOT NULL,
  -- Examples:
  -- 'application.created', 'application.status_changed'
  -- 'document.generated', 'document.verified'
  -- 'offer.collected', 'offer.analyzed'
  -- 'draft.created', 'message.sent' (manual)
  
  event_data TEXT,  -- JSON: specific details
  
  -- Provenance
  triggered_by TEXT NOT NULL,  -- 'workflow:WF6', 'user:manual', 'system'
  
  occurred_at TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_events_entity ON events(entity_type, entity_id);
CREATE INDEX idx_events_occurred ON events(occurred_at DESC);
CREATE INDEX idx_events_user ON events(user_id, occurred_at DESC);

-- ============================================================================
-- SYNC STATE (for future integrations)
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_state (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,  -- 'gmail', 'drive'
  resource_type TEXT NOT NULL,  -- 'messages', 'files'
  
  -- Sync state
  last_sync_at TEXT,
  last_sync_status TEXT,  -- 'success', 'partial', 'failed'
  last_sync_cursor TEXT,  -- pageToken, historyId, etc.
  last_sync_error TEXT,
  
  -- Statistics
  total_synced INTEGER DEFAULT 0,
  last_batch_count INTEGER DEFAULT 0,
  
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  
  UNIQUE(user_id, provider, resource_type)
);

-- ============================================================================
-- WORKFLOW LOCKS (to prevent race conditions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS workflow_locks (
  workflow_name TEXT PRIMARY KEY,
  locked_at TEXT NOT NULL,
  locked_by TEXT NOT NULL,  -- execution ID
  expires_at TEXT NOT NULL
);

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- Active applications with latest profile
CREATE VIEW IF NOT EXISTS v_active_applications AS
SELECT 
  a.id,
  a.user_id,
  a.tracking_ref,
  a.status,
  a.sent_at,
  o.title AS offer_title,
  o.company_name,
  o.location,
  oa.score,
  oa.recommendation,
  p.version AS profile_version,
  a.created_at,
  a.updated_at
FROM applications a
JOIN offers o ON a.offer_id = o.id
JOIN profiles p ON a.profile_id = p.id
LEFT JOIN offer_analyses oa ON a.offer_id = oa.offer_id AND a.profile_id = oa.profile_id
WHERE a.status NOT IN ('closed', 'withdrawn', 'rejected');

-- Documents by application
CREATE VIEW IF NOT EXISTS v_application_documents AS
SELECT
  d.id,
  d.application_id,
  a.tracking_ref,
  d.document_type,
  d.format,
  d.filename,
  d.verification_status,
  d.human_verified,
  d.created_at
FROM documents d
JOIN applications a ON d.application_id = a.id;

-- Recent events
CREATE VIEW IF NOT EXISTS v_recent_events AS
SELECT
  e.id,
  e.user_id,
  e.entity_type,
  e.entity_id,
  e.event_type,
  e.triggered_by,
  e.occurred_at,
  CASE e.entity_type
    WHEN 'application' THEN (SELECT tracking_ref FROM applications WHERE id = e.entity_id)
    WHEN 'offer' THEN (SELECT title FROM offers WHERE id = e.entity_id)
    ELSE NULL
  END AS related_name
FROM events e
ORDER BY e.occurred_at DESC;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Already created inline above, summary:
-- idx_offers_user_status
-- idx_offers_company
-- idx_analyses_score
-- idx_applications_user_status
-- idx_applications_tracking_ref
-- idx_documents_application
-- idx_messages_user_type
-- idx_messages_tracking_ref
-- idx_events_entity
-- idx_events_occurred
-- idx_events_user

-- ============================================================================
-- INITIALIZATION METADATA
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_version (
  version TEXT PRIMARY KEY,
  applied_at TEXT NOT NULL,
  description TEXT
);

INSERT INTO schema_version (version, applied_at, description) 
VALUES ('1.0.0', datetime('now'), 'Initial MVP schema - WF0-6 + WF10');
