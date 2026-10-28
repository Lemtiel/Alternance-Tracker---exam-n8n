# Google Sheets Setup - Alternance Tracker

The `Alternance Tracker` workflow uses one spreadsheet with **six tabs**. The tab names and the header row must match exactly: the workflow maps input fields to columns by name, so a misspelled header silently leaves the column empty.

## 1. Create the spreadsheet

1. Open https://sheets.google.com and create a blank spreadsheet.
2. Name it `Alternance Tracker - <your name>`.
3. Copy the id from the URL: `https://docs.google.com/spreadsheets/d/<SPREADSHEET_ID>/edit`.
4. Open the workflow in n8n, open the **Settings** node, and replace `PASTE_YOUR_SPREADSHEET_ID` with that id.

## 2. Create the six tabs

Create these tabs with these exact names (delete the default `Sheet1`):

1. `Configuration`
2. `Profiles`
3. `Offers`
4. `Offer_Analyses`
5. `Applications`
6. `Documents`

## 3. Paste the header rows

Paste each line into row 1 of the matching tab. Use a single tab character as separator, or use `Data > Split text to columns`.

### Configuration

```
id	user_id	version	llm_provider	llm_model	min_score_threshold	notifications_enabled	created_at	updated_at
```

Only the presence of the tab is checked by the `diagnostic` action. Add one row if you want the diagnostics to report a configuration.

### Profiles

```
id	user_id	version	source_filename	extracted_at	personal_info_json	education_json	experience_json	skills_json	languages_json	certifications_json	projects_json	raw_text	extraction_confidence	uncertain_elements_json	human_verified	created_at	updated_at
```

Written by `import_cv`. One profile per user: the row is upserted on `id`.

### Offers

```
id	user_id	external_id	external_source	title	company_name	company_domain	description	location	contact_email	status	availability_status	created_at	updated_at
```

Written by `add_offer`. The row is upserted on `id`, which is derived from the company and the title, so submitting the same offer twice updates it instead of duplicating it.

### Offer_Analyses

```
id	application_id	offer_id	profile_id	user_id	score	recommendation	rationale	matching_skills_json	missing_skills_json	strengths_json	concerns_json	warnings_json	analyzed_by	created_at
```

Appended by `prepare`. One row per analysis, never overwritten.

### Applications

```
id	user_id	offer_id	profile_id	tracking_ref	status	score	recommendation	company_name	offer_title	contact_email	email_subject	email_body	draft_to	draft_subject	draft_body	draft_status	sent_at	location	created_at	updated_at
```

Written by `prepare` (status `documents_ready`) and by `draft` (status `draft_ready`). The row is upserted on `tracking_ref`.

Status flow: `documents_ready` → `draft_ready` → `sent`.

`sent` is set by hand, only after the mailbox proves the email left. The workflow never sets it.

### Documents

```
id	application_id	profile_id	user_id	document_type	format	filename	content	verification_status	human_verified	created_at
```

Appended by `prepare`. One row per generated document: `cv`, `cover_letter`, `email`.

Every row starts with `verification_status = pending_review` and `human_verified = false`, because the model can still be wrong about the candidate.

## 4. Format the headers

1. Select row 1 of each tab.
2. Format > Text > Bold.
3. Format > Wrapping > Clip.
4. View > Freeze > 1 row.

## 5. Check the credential

The workflow expects a `Google Sheets OAuth2` credential named **Google Sheets account**. All Google Sheets nodes already reference it.

If you rename it, open one Google Sheets node, pick the new credential, and repeat for the other nine.

## 6. Verify

1. Save the workflow.
2. Open the form URL (`/form/alternance-tracker`).
3. Choose `diagnostic` and submit.
4. The response lists `blockers`. An empty list means the spreadsheet id and the profile are ready.

## 7. If a header is missing or misspelled

The write nodes run with `insertInNewColumn`: a field that has no matching column is **added at the end of the header row** instead of being dropped. Nothing is lost silently, but the tab drifts from the documented order.

- If you paste a tab from an older schema, the workflow completes the header row on the first write: unused columns stay empty, missing ones appear at the right end.
- `draft` adds an `instructions` column to `Applications` (the manual send reminder). It is expected.
- To get back to the documented order, clear the tab, paste the header row from section 3, and replay the action.

## Notes

- JSON columns hold a JSON string, not a native object. `skills_json` contains `[{"name":"Python","level":"unknown"}]`.
- Dates are ISO 8601 strings.
- Booleans are written as `false` / `true`.
- Empty values stay empty; the workflow never fills an unknown with a guess.
- The two Gemini nodes must not carry `thinkingBudget: 0`: the model served behind `gemini-flash-lite-latest` rejects it with HTTP 400.
