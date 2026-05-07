# Posting messages to Teams (chat & channel)

Use this when an agent needs to **notify** a team — e.g. "BA Agent finished requirements v1, post a heads-up in the dev channel" — rather than just dropping a file in SharePoint. Files alone don't trigger a conversation; a message does.

Two surfaces exist:

| Target           | Command                            | When to use                                                                 |
|------------------|------------------------------------|-----------------------------------------------------------------------------|
| Channel message  | `m365 teams chat message send` (channel mode) / `m365 teams message send` | Broadcast to a team channel — visible to all members, threadable          |
| Chat message     | `m365 teams chat message send`     | 1:1 or group chat — direct message to specific people, no channel context |

The CLI uses the same family of commands; the difference is which IDs you pass.

---

## Prerequisites

- `m365 status` shows you're logged in (see `auth-setup.md`)
- The signed-in user is a member of the target team / chat
- The Microsoft Entra app registration has the delegated permissions:
  - `ChannelMessage.Send` (for channel posts)
  - `Chat.ReadWrite` (for chat posts)

If permissions are missing the call fails with `Authorization_RequestDenied` — direct the user to grant consent for the app registration in Azure Portal.

---

## Channel message — post to a team channel

```bash
m365 teams message send \
  --teamId <team-id> \
  --channelId <channel-id> \
  --message "📄 Requirements v1 is up — see Shared Documents/01-requirements/ba-requirements.md"
```

Or, by team/channel **display name** (CLI resolves IDs for you):

```bash
m365 teams message send \
  --teamName "Bolignet Development" \
  --channelName "General" \
  --message "..."
```

### Finding the IDs

```bash
# All teams you have access to:
m365 teams team list --output json

# Channels in a specific team:
m365 teams channel list --teamId <team-id> --output json
```

Cache `teamId` and `channelId` in the client's `settings.json` once known — looking them up on every send is wasteful:

```json
{
  "m365": {
    "teamId": "00000000-0000-0000-0000-000000000000",
    "channels": {
      "general": "19:abc...@thread.tacv2",
      "dev":     "19:def...@thread.tacv2"
    }
  }
}
```

### Formatting

**Default to `--contentType html`** for any message with structure (lists, headings, bold, links). Teams chats and channels do **not** render markdown — `**bold**` and `- item` show as raw characters. If the user gives you markdown, convert it before sending.

```bash
m365 teams message send \
  --teamId <id> --channelId <id> \
  --contentType html \
  --message "<p><b>Requirements v1</b> is up — <a href='https://...'>open file</a></p>"
```

Markdown → HTML conversion table (covers ~95% of real messages):

| Markdown                  | HTML                                              |
|---------------------------|---------------------------------------------------|
| `**bold**`                | `<b>bold</b>`                                     |
| `*italic*` / `_italic_`   | `<i>italic</i>`                                   |
| `` `code` ``              | `<code>code</code>`                               |
| `[text](url)`             | `<a href="url">text</a>`                          |
| `# H1` / `## H2` / `### H3` | `<h1>H1</h1>` / `<h2>H2</h2>` / `<h3>H3</h3>`   |
| `- item` (unordered list) | `<ul><li>item</li></ul>`                          |
| `1. item` (ordered list)  | `<ol><li>item</li></ol>`                          |
| Blank line                | `<p>...</p>` for the next paragraph, or `<br>`    |
| Tables                    | `<table><tr><td>...</td></tr></table>` (basic; some clients render poorly) |
| Emoji                     | Paste literal Unicode (✅ 🟡 🔴 ⚠️) — works as-is  |

Other supported tags: `<u>`, `<s>` (strikethrough), `<pre>` for code blocks, `<blockquote>`, `<hr>`. Mentions (`<at>...</at>`) need the Graph API directly — not currently in the CLI.

Plain text (`--contentType text`, the default) is fine **only** when the message has no structure to render.

#### Linkify identifiers (work items, PRs, commits)

When a message references trackable IDs, **always wrap them in `<a href>` so they're clickable**. Bare numbers or `#1234` text in Teams won't auto-link. Common templates (resolve `{org}` / `{project}` from `.env` and the client's `settings.json`):

| Reference                  | URL template                                                                 |
|----------------------------|------------------------------------------------------------------------------|
| Azure DevOps work item     | `https://dev.azure.com/{org}/{project}/_workitems/edit/{id}`                 |
| Azure DevOps PR            | `https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{id}`         |
| Azure DevOps commit        | `https://dev.azure.com/{org}/{project}/_git/{repo}/commit/{sha}`             |
| GitHub PR                  | `https://github.com/{owner}/{repo}/pull/{id}`                                |
| GitHub issue               | `https://github.com/{owner}/{repo}/issues/{id}`                              |

Example for a status post:

```html
<li><a href="https://dev.azure.com/tabtabgo/LISA/_workitems/edit/19163">#19163</a> — Omar — Use new email for OTPs</li>
```

When generating lists of items from a WIQL query result, build the link inline rather than printing the bare ID.

---

## Chat message — post to a 1:1 or group chat

```bash
# To an existing chat (you need its chatId):
m365 teams chat message send \
  --chatId 19:abc...@thread.v2 \
  --message "Hey — uploaded the latest design file to SharePoint."

# Or address by user — CLI creates/reuses a 1:1 chat:
m365 teams chat message send \
  --userEmails "alice@tenant.com" \
  --message "..."

# Group chat by emails (comma-separated):
m365 teams chat message send \
  --userEmails "alice@tenant.com,bob@tenant.com" \
  --message "..."
```

### Listing chats

```bash
m365 teams chat list --output json
```

The result includes `id` (the `chatId`), `chatType` (`oneOnOne` / `group` / `meeting`), and `topic`.

### Named-chat lookup workflow ("notify chat `<name>`" / "notify group")

For frequently-targeted group chats, persist the `chatId` in the client's `settings.json` once and reuse it. Resolution order:

1. **Read first.** Look up `~/workspace/<client>/settings.json` → `m365.chats[<name>].chatId`. If present, use it. Done.
2. **Default chat.** If the user said "notify group" / "notify chat" with no name, use the entry where `"default": true`.
3. **Discover-then-persist.** If the named chat is not registered:
   - Run `m365 teams chat list --output json` and filter `topic` (case-insensitive contains the user's name).
   - Show matches to the user (id, chatType, topic). If exactly one match, confirm. If multiple, ask which.
   - **Write the result back into `settings.json`** under `m365.chats[<name>]` so the next call skips discovery.
   - Mark a chat `"default": true` only with explicit user confirmation.

`settings.json` shape:

```json
{
  "m365": {
    "chats": {
      "Lisa Team": {
        "chatId": "19:74e8560d6c2a49b89201502b1827d162@thread.v2",
        "chatType": "group",
        "default": true
      },
      "PMs": {
        "chatId": "19:....@thread.v2",
        "chatType": "group"
      }
    }
  }
}
```

Send by `chatId`:

```bash
CHAT_ID=$(jq -r '.m365.chats["Lisa Team"].chatId' ~/workspace/<client>/settings.json)
m365 teams chat message send \
  --chatId "$CHAT_ID" \
  --contentType html \
  --message "<h3>v2.2.6 status</h3><ul><li>Closed: <b>30/41</b></li></ul>"
```

Don't re-run `m365 teams chat list` for a chat that's already in `settings.json` — that's the whole point of caching it.

---

## Combine: upload a file, then announce it

Common pattern for agent handoff — file goes to SharePoint, message goes to the channel with a link:

```bash
# 1. Upload
m365 spo file add \
  --webUrl "$WEB_URL" \
  --folder "Shared Documents/01-requirements" \
  --path "./ba-requirements.md" \
  --publish --publishComment "BA Agent: requirements v1"

# 2. Build the file's web URL (server-relative path, prefixed with the site URL):
FILE_URL="$WEB_URL/Shared%20Documents/01-requirements/ba-requirements.md"

# 3. Notify the channel
m365 teams message send \
  --teamName "Bolignet Development" \
  --channelName "General" \
  --contentType html \
  --message "<p>📄 <b>Requirements v1</b> is up — <a href='$FILE_URL'>open file</a></p>"
```

URL-encode spaces (`%20`) in the file URL — Teams won't auto-fix them.

---

## When NOT to use Teams messages

- **Per-developer notifications** — DM via the team's existing notification layer (WhatsApp, email) instead. Posting bot-style messages in busy channels burns goodwill quickly.
- **Long content** — paste a link to the SharePoint file, don't dump the whole document into a chat message. Teams renders large messages poorly and they're hard to search.
- **Agent-to-agent coordination** — use `project-log.json` in SharePoint, not chat. Chat is for humans.

---

## Common errors

| Symptom                                   | Cause                                                                | Fix                                                                          |
|-------------------------------------------|----------------------------------------------------------------------|------------------------------------------------------------------------------|
| `Authorization_RequestDenied`             | App registration lacks `ChannelMessage.Send` or `Chat.ReadWrite`     | Grant delegated permission + admin consent in Azure Portal                   |
| `Resource not found` on channelId         | Channel ID copied with wrong format (must include `@thread.tacv2`)   | Re-fetch with `m365 teams channel list --output json`                        |
| `--message` shows raw HTML in Teams       | Forgot `--contentType html`                                          | Add `--contentType html` for HTML; default is `text`                         |
| Empty mentions (`<at>` tags ignored)      | CLI doesn't support mentions — Graph-only                            | Either drop the mention or call Graph directly (out of scope for this skill) |
| Message posted but nobody saw it          | Channel has no followers / notifications muted                       | Expected — `send` doesn't ping; for urgent posts use a chat message instead  |
