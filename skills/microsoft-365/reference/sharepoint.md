# SharePoint operations beyond file upload/download

The main `SKILL.md` covers the four core operations agents need most: upload, download, list, and auth check. This file documents the broader SPO command surface — reach for these when an agent needs something more than vanilla file I/O.

## Table of contents

1. [Site and web operations](#site-and-web-operations)
2. [Folder operations](#folder-operations)
3. [File advanced operations](#file-advanced-operations)
4. [List and list item operations](#list-and-list-item-operations)
5. [Search](#search)
6. [Setting the default SPO URL](#setting-the-default-spo-url)

---

## Site and web operations

### Get info about a site

```bash
m365 spo site get --url "https://tenant.sharepoint.com/sites/Bolignet" --output json
```

Returns the site ID, owner, storage quota, template, etc. Useful when an agent needs to verify the site exists or check permissions.

### List all sites in the tenant

```bash
m365 spo site list --output json
```

Large tenants return hundreds of sites — pipe to `jq` to filter.

### Check the web's basic info

```bash
m365 spo web get --webUrl "https://tenant.sharepoint.com/sites/Bolignet" --output json
```

A "web" is a sub-site. For most multi-agent workflow purposes, site and web are the same thing (the root web of the site).

---

## Folder operations

### Create a phase folder if it doesn't exist

Before uploading the first artifact for a new phase, make sure the folder exists:

```bash
m365 spo folder add \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --parentFolderUrl "Shared Documents" \
  --name "01-requirements"
```

Idempotent-ish — if the folder already exists, this errors. An agent should either catch that or check first:

```bash
m365 spo folder get \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --folderUrl "Shared Documents/01-requirements" \
  --output json
```

### List folder contents (folders only, not files)

```bash
m365 spo folder list \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --parentFolderUrl "Shared Documents" \
  --output json
```

Use `--recursive` for a full tree.

### Remove a folder

```bash
m365 spo folder remove \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --url "Shared Documents/01-requirements/obsolete" \
  --force
```

`--force` skips the confirmation prompt. Only remove phase folders as part of explicit cleanup — never as part of a regular agent flow.

---

## File advanced operations

### Copy a file between folders or sites

```bash
m365 spo file copy \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --sourceUrl "/sites/Bolignet/Shared Documents/01-requirements/ba-requirements.md" \
  --targetUrl "/sites/Bolignet/Shared Documents/archive/"
```

Use for snapshotting approved artifacts into an `archive/` folder before a new version overwrites.

### Move a file

```bash
m365 spo file move \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --sourceUrl "/sites/Bolignet/Shared Documents/drafts/ba-v1.md" \
  --targetUrl "/sites/Bolignet/Shared Documents/01-requirements/"
```

### Check file versions

```bash
m365 spo file version list \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --fileUrl "/sites/Bolignet/Shared Documents/01-requirements/ba-requirements.md" \
  --output json
```

Restore an old version with `m365 spo file version restore`.

### Check in / check out

When multiple agents might touch the same file, explicit check-out avoids last-write-wins clobbering:

```bash
# Check out
m365 spo file checkout --webUrl "$WEB_URL" --fileUrl "/sites/.../file.md"

# ...make changes, upload with --checkOut...

# Check in
m365 spo file checkin \
  --webUrl "$WEB_URL" \
  --fileUrl "/sites/.../file.md" \
  --comment "Updated by QA Agent"
```

For the multi-agent workflow this is overkill in the normal case — file-based `project-log.json` updates are serialized through the orchestrator. Use check-out/check-in only when genuinely concurrent edits are expected.

### Remove a file

```bash
m365 spo file remove \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --url "/sites/Bolignet/Shared Documents/drafts/old.md" \
  --force
```

`--force` skips confirmation and moves to Recycle Bin (not permanent delete). Recoverable for ~93 days by default.

---

## List and list item operations

SharePoint document libraries are lists under the hood. For most artifact work, the file commands above are enough — but if an agent needs to set custom metadata (e.g., `ApprovalStatus`, `AssignedAgent`), use list item commands:

```bash
# Set a custom field on a file's list item
m365 spo listitem set \
  --webUrl "$WEB_URL" \
  --listUrl "Shared Documents" \
  --id <item-id> \
  --ApprovalStatus "Approved" \
  --AssignedAgent "QA Agent"
```

Field names are whatever the library was configured with — check the library's columns in the SharePoint UI first.

---

## Search

Cross-library search is handy when an agent doesn't know which phase folder holds the file it needs:

```bash
m365 spo search \
  --queryText "ba-requirements filename:*.md" \
  --webUrl "https://tenant.sharepoint.com/sites/Bolignet" \
  --output json
```

Returns paths you can feed into `spo file get`. Use sparingly — search results have up to a 15-minute indexing delay, so a file uploaded a moment ago may not appear yet.

---

## Setting the default SPO URL

To save typing `--webUrl` on every command in a session:

```bash
m365 spo set --url "https://tenant.sharepoint.com"
```

After this, commands accept server-relative URLs (`/sites/Bolignet/...`) and auto-resolve. Note this is session state — it doesn't persist across `m365 logout`/`login` cycles.

For agent scripts, always pass `--webUrl` explicitly. Relying on `spo set` introduces hidden state that makes scripts fragile.
