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
    "documentLibrary": "Shared Documents",
    "chats": {
      "Bolignet Team": {
        "chatId": "19:....@thread.v2",
        "chatType": "group",
        "default": true
      }
    }
  }
}
```

**Derived values:**

- `webUrl` = `${tenantUrl}/sites/${siteName}` — this is the `--webUrl` argument for every SPO command
- `folder` = `${documentLibrary}/<phase-dir>` — e.g., `Shared Documents/01-requirements`
- `chatId` for any named chat = `m365.chats["<friendly name>"].chatId`. The entry with `"default": true` is what bare "notify chat" / "notify group" requests resolve to.

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

### 4. Post a message to a Teams chat or channel

Uploading a file is silent — it doesn't notify anyone. To announce a handoff (e.g. "BA Agent finished requirements v1"), post a message.

**Always send as HTML.** Teams chats do **not** render markdown — asterisks and dashes show as raw characters. Use `--contentType html` for every message and convert any markdown the user gives you into HTML (`**bold**` → `<b>bold</b>`, `- item` → `<ul><li>item</li></ul>`, headings → `<h3>`, etc.). Plain text without `--contentType` only works when there's no formatting to render.

**Always linkify trackable IDs.** Teams does NOT auto-link bare numbers or `#1234` text. Whenever a message mentions a work item, PR, commit, or issue, wrap it in `<a href>`. This is non-negotiable for status updates — recipients expect to click. Resolve `{org}` from `.env` (`AZURE_DEVOPS_ORG_URL`) and `{project}` from the client's `settings.json` (`devOpsProjectName`). See `reference/teams-chat.md` § "Linkify identifiers" for the full URL templates. Quick reference:

- Azure DevOps work item: `https://dev.azure.com/{org}/{project}/_workitems/edit/{id}`
- Azure DevOps PR: `https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{id}`

Build the `<a>` inline as you generate each list item — never print the bare ID first and rely on Teams to fix it.

**Standard work item list format.** When listing work items in a Teams message, every `<li>` must follow this exact shape — no variations:

```
<li><a href="{workitem-url}">#{id}</a> - <b>{Assignee short name}</b> - {Title}</li>
```

- `#{id}` is wrapped in `<a href>` pointing to the Azure DevOps work item URL.
- Assignee is the short name (resolved from `.claude/devops.settings.json` `teamMembers[]`); use `<b>unassigned</b>` if null. Always bold.
- Title is the raw `System.Title` (HTML-escape `&`, `<`, `>`, `"`).
- Separator is ` - ` (space-hyphen-space). No emojis, no extra prefixes inside the `<li>`.
- Group items under section headings (`<h4>`) by state, type, or assignee — but every item line itself must match the format above.

Example:

```html
<li><a href="https://dev.azure.com/tabtabgo/BoligNet/_workitems/edit/19138">#19138</a> - <b>Sarya</b> - "Await Fulfillment" status for confirmed orders</li>
```

**Iteration summary format.** When the message is an iteration / sprint / release update (e.g. "v1.8.6 update"), follow these rules in addition to the work item list format above:

- **Do NOT list Closed items.** They clutter the post. List only Active, New, and Resolved (still needs closure) sections. Mention the closed *count* in the summary header but skip the per-item enumeration.
- **Include a % completed metric** in the summary header. Formula:
  - `% completed = (Closed + Resolved) / (Total - Removed) × 100`
  - Removed items are excluded from the denominator (they were dropped from scope).
  - Resolved items count as done for completion %, even though they still need formal closure.
- Summary header line should include: total items, % completed, then the breakdown counts.

Example summary header:

```html
<p><b>Summary:</b> 26 items &nbsp;·&nbsp; <b>67% completed</b> &nbsp;·&nbsp; ✅ Closed: 14 &nbsp;·&nbsp; 🟢 Resolved: 2 &nbsp;·&nbsp; 🟡 Active: 3 &nbsp;·&nbsp; 🆕 New: 5 &nbsp;·&nbsp; ⛔ Removed: 2</p>
```

#### Group chat / "notify chat" workflow (read-then-write)

When the user asks "notify chat <name>", "post to <name>", or just "notify group", **resolve the chatId from the client's `settings.json` first** — never run `m365 teams chat list` again for a chat that's already registered.

1. Read `~/workspace/<client>/settings.json` → `m365.chats[<name>].chatId`.
2. If the user said just "notify group" / "notify chat" with no name, use the entry where `"default": true`.
3. **If the named chat is not in `settings.json`:** ask the user for the chat name (if not already given), run `m365 teams chat list --output json` and filter by `topic` (case-insensitive contains), show matches to the user, get their pick, then **persist it back** into `settings.json` under `m365.chats` before sending. Mark the first registered chat as `"default": true` only with explicit user confirmation.
4. Send via `m365 teams chat message send --chatId "$CHAT_ID" --message "$HTML" --contentType html`.

```bash
# Example: notify group chat from settings.json
CHAT_ID=$(jq -r '.m365.chats["Lisa Team"].chatId' ~/workspace/lisa/settings.json)
m365 teams chat message send \
  --chatId "$CHAT_ID" \
  --contentType html \
  --message "<h3>v2.2.6 status</h3><ul><li>Closed: <b>30/41</b></li></ul>"
```

#### Channel post — broadcast to a team

```bash
m365 teams message send \
  --teamName "Bolignet Development" \
  --channelName "General" \
  --contentType html \
  --message "<p>📄 <b>Requirements v1</b> is up — <a href='$FILE_URL'>open file</a></p>"
```

#### Direct chat by email (one-off, no settings.json entry)

```bash
m365 teams chat message send \
  --userEmails "alice@tenant.com" \
  --contentType html \
  --message "<p>Uploaded the latest design file.</p>"
```

Cache `teamId` / `channelId` / `chatId` in `settings.json` after first lookup. Full command surface, formatting rules, HTML cheatsheet, and the upload-then-announce pattern: `reference/teams-chat.md`.

### 5. Check auth status

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
- `reference/teams-chat.md` — Posting messages to Teams channels and chats (`m365 teams message send`, `m365 teams chat message send`), HTML formatting, upload-then-announce pattern
- `reference/sharepoint.md` — Broader SPO surface: folders, lists, sites, search beyond file operations
- `reference/common-errors.md` — Error playbook for the most common `m365` failures

## Scripts

These wrappers live in `scripts/` and encode the settings.json lookup + phase-folder convention, so an agent doesn't need to reconstruct URLs by hand:

- `scripts/upload-artifact.sh` — Upload a local file to the correct phase folder for a given client
- `scripts/download-artifact.sh` — Download a named artifact from a phase folder to local disk

Prefer the wrappers over raw `m365` calls whenever a workflow maps cleanly to "client + phase + filename", because they enforce the convention and fail fast on misconfiguration.
