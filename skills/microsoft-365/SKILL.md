---
name: microsoft-365
description: Use the CLI for Microsoft 365 (m365, @pnp/cli-microsoft365) to upload, download, list, and manage artifacts in SharePoint and Microsoft Teams channels. Use this skill whenever an agent needs to push a project artifact (requirements doc, design file, ADR, test report, project-log.json) to a Teams channel or SharePoint site, pull one down, list what's there, or authenticate against Microsoft 365 — including any phrase like "upload to Teams", "pull the latest requirements doc", "sync artifacts", "publish to SharePoint", "share with the team on Teams", or any mention of SharePoint/SPO/OneDrive file operations from a terminal. Also trigger when the user is building an agent that needs to read or write artifacts to the shared Teams/SharePoint workspace described in project settings.json.
---

# CLI for Microsoft 365 (m365)

This skill wraps the community-maintained `@pnp/cli-microsoft365` tool (binary: `m365`) so agents in the multi-agent development workflow can read and write artifacts to SharePoint and Microsoft Teams channels.

Teams channel files are stored in SharePoint document libraries, so the same `m365 spo file ...` commands handle both. This skill treats Teams as "the UI over SharePoint" and does all file I/O via SPO commands.

## When to reach for this skill

Use it whenever an agent needs to:

- Upload a completed phase artifact (requirements, design, ADRs, test reports) to the shared Teams workspace
- Download the latest version of an artifact another agent produced
- List what artifacts exist for a given phase
- Sync `project-log.json` between local disk and the shared store
- Check authentication status or re-authenticate

Do **not** use it for:

- Creating Microsoft Entra app registrations programmatically (direct the user to do this in Azure Portal — see `reference/auth-setup.md`)
- Anything requiring admin consent flows the user hasn't already granted
- Managing Teams memberships, channels, or permissions (out of scope for artifact sync)

## Prerequisites — check these first, before any command

Before running any `m365` command, confirm all of the following. If any is missing, stop and tell the user what's missing rather than guessing:

1. **`m365` is installed.** Run `m365 --version`. If not found, install with `npm install -g @pnp/cli-microsoft365` (requires Node.js 20+).
2. **The user is logged in.** Run `m365 status`. If it reports "Logged out", walk the user through `reference/auth-setup.md`.
3. **A client `settings.json` exists** with the Microsoft 365 target info (see next section). This is the source of truth for which SharePoint site to hit — never hardcode URLs in commands.

## Reading project settings

Every command in this skill resolves its target SharePoint site from a per-client `settings.json`, typically at `~/workspace/<client>/settings.json`. Never ask the user for the site URL if `settings.json` exists — read it.

**Expected shape:**

```json
{
  "client": "bolignet",
  "m365": {
    "tenantUrl": "https://yourtenant.sharepoint.com",
    "siteName": "Bolignet",
    "teamName": "Bolignet Development",
    "documentLibrary": "Shared Documents"
  }
}
```

**Derived values:**

- `webUrl` = `${tenantUrl}/sites/${siteName}` — this is the `--webUrl` argument for every SPO command
- `folder` = `${documentLibrary}/<phase-dir>` — e.g., `Shared Documents/01-requirements`

**If `settings.json` is missing or malformed:** stop and ask the user for the site name and tenant URL, then offer to write a `settings.json` stub they can commit.

**If `m365` block is missing but a client folder exists:** offer to scaffold the `m365` section based on the client folder name, then confirm with the user before writing.

## Phase folder convention

Artifacts in SharePoint mirror the numbered local directory structure. Always use these exact folder names so every agent finds the right place:

```
Shared Documents/
├── Features
  ├── 01-requirements/       # BA Agent outputs
  ├── 02-design/             # Design Agent outputs
  ├── 03-architecture/       # Architect Agent outputs (ADRs, diagrams)
  ├── 04-qa-test-cases/      # QA Agent (Phase 1) outputs
  ├── 07-qa-execution/       # QA Agent (Phase 2) outputs
  └── project-log.json       # Shared state (root, not in a phase folder)
```

When an agent asks to upload a requirements doc, map it to `01-requirements/` without asking. When the phase is ambiguous (e.g., a generic `.md` file), ask which phase it belongs to rather than guessing.

## Core operations

The four operations below cover ~95% of real use. For anything beyond this, read `reference/sharepoint.md` for the broader command surface, and `reference/teams-files.md` for Teams-specific nuances.

### 1. Upload an artifact (push to the shared store)

Prefer the wrapper script — it handles settings.json lookup, phase-folder resolution, and error cases:

```bash
./scripts/upload-artifact.sh <client> <phase> <local-file-path> [--publish]
# Example:
./scripts/upload-artifact.sh bolignet 01-requirements ./docs/general/01-requirements/ba-requirements.md --publish
```

If the wrapper isn't available, use `m365` directly:

```bash
m365 spo file add \
  --webUrl "https://yourtenant.sharepoint.com/sites/Bolignet" \
  --folder "Shared Documents/01-requirements" \
  --path "./docs/general/01-requirements/ba-requirements.md" \
  --publish --publishComment "BA Agent: requirements v1"
```

Flags worth knowing:
- `--publish --publishComment "<msg>"` — publishes the file (when the library has major/minor versions enabled)
- `--approve --approveComment "<msg>"` — approves when list moderation is on
- `--checkOut --checkInComment "<msg>"` — checks out before uploading; useful when another agent might be editing

### 2. Download an artifact (pull from the shared store)

```bash
./scripts/download-artifact.sh <client> <phase> <filename> [<local-dest>]
# Example:
./scripts/download-artifact.sh bolignet 01-requirements ba-requirements.md ./local-copy/
```

Direct command:

```bash
m365 spo file get \
  --webUrl "https://yourtenant.sharepoint.com/sites/Bolignet" \
  --url "/sites/Bolignet/Shared Documents/01-requirements/ba-requirements.md" \
  --asFile \
  --path "./local-copy/ba-requirements.md"
```

The `--url` value is a **server-relative** path (starts with `/sites/<siteName>/...`). This is a common source of errors — see `reference/common-errors.md`.

### 3. List artifacts in a phase folder

```bash
m365 spo file list \
  --webUrl "https://yourtenant.sharepoint.com/sites/Bolignet" \
  --folderUrl "Shared Documents/01-requirements" \
  --output json
```

Add `--recursive` to include subfolders. Use `--output json` whenever an agent will parse the result programmatically — the default output is human-oriented.

### 4. Check auth status

```bash
m365 status
```

Returns the logged-in identity or "Logged out". If logged out, do not attempt any other command — route to `reference/auth-setup.md`.

## JSON output for programmatic use

Any agent parsing `m365` output should pass `--output json`. Never parse the default text table — it's formatted for humans and changes without notice.

```bash
m365 spo file list \
  --webUrl "$WEB_URL" \
  --folderUrl "Shared Documents/01-requirements" \
  --output json
```

The wrapper scripts already do this; direct callers must add it explicitly.

## When things go wrong

The vast majority of failures fall into a small set of categories. Before retrying blindly, read `reference/common-errors.md` — it covers:

- Auth expired / token refresh
- File already exists / conflict
- File is checked out by someone else
- Server-relative URL format mistakes
- Site URL not recognized (run `m365 spo set --url <tenant>` once per session)
- Large file upload limits

## Reference files

Read these when the situation calls for it — don't load them upfront:

- `reference/auth-setup.md` — First-time Entra app registration, device code login, token refresh, troubleshooting auth
- `reference/teams-files.md` — Teams-specific: mapping team names to site URLs, channel-to-folder mapping, chat files vs channel files
- `reference/sharepoint.md` — Broader SPO surface: folders, lists, sites, search beyond file operations
- `reference/common-errors.md` — Error playbook for the most common `m365` failures

## Scripts

These wrappers live in `scripts/` and encode the settings.json lookup + phase-folder convention, so an agent doesn't need to reconstruct URLs by hand:

- `scripts/upload-artifact.sh` — Upload a local file to the correct phase folder for a given client
- `scripts/download-artifact.sh` — Download a named artifact from a phase folder to local disk

Prefer the wrappers over raw `m365` calls whenever a workflow maps cleanly to "client + phase + filename", because they enforce the convention and fail fast on misconfiguration.
