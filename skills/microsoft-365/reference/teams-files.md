# Teams files

Microsoft Teams doesn't have its own file storage. Channel files live in SharePoint, chat files live in OneDrive. This file explains how to get from a human-readable team/channel name to the SharePoint URL that `m365 spo file ...` commands need.

## The mental model

```
Team (e.g. "Bolignet Development")
 └── SharePoint site          (one site per team)
      └── Document library    (usually "Shared Documents")
           └── Channel folder (one per channel — "General", "Dev", etc.)
                └── Files
```

Chat files (1:1 or group chats) are different — they live in the sender's OneDrive, not in any team's SharePoint site.

---

## Finding the SharePoint URL for a Team

### If you know the team's display name

```bash
# List all teams you have access to (look for the right one by displayName):
m365 teams team list --output json

# Once you have the team ID, get its SharePoint site URL:
m365 teams team get --id <team-id> --output json
```

The returned object includes `webUrl` for the team and, under associated channel info, the SharePoint site URL. For the typical multi-agent workflow, you can shortcut this by reading `m365.tenantUrl` + `m365.siteName` straight out of the client's `settings.json` — the team's site URL follows the pattern:

```
${tenantUrl}/sites/${siteName}
```

…as long as the team was created with the standard naming (which it almost always is).

### If you know the SharePoint site URL directly

You're done — that's the `--webUrl` argument.

---

## Channel → folder mapping

Every channel in a team maps to a folder **inside the team's default document library**. The folder name matches the channel's display name.

For the multi-agent workflow, the convention is:

- **Use the General channel as the landing area.** It maps to `Shared Documents/General/Features`.
- **But don't put artifacts there directly.** Instead, put them in phase folders:

```
Shared Documents/
├── 01-requirements/
├── 02-design/
├── 03-architecture/
├── 04-qa-test-cases/
├── 05-frontend/
├── 06-backend/
├── 07-qa-execution/
└── General/   ← the Teams "General" channel's folder, keep it for humans
```

The phase folders sit at the root of `Shared Documents/` so they're not tied to any one Teams channel. Every channel's Files tab shows "…Shared Documents" and users can navigate up to see all phase folders.

### If you want artifacts to appear inside a specific channel's Files tab

Put them in `Shared Documents/<ChannelName>/<subfolder>/` instead. Example — if there's a dedicated `dev-artifacts` channel:

```
Shared Documents/
└── dev-artifacts/
    ├── 01-requirements/
    ├── 02-design/
    └── ...
```

Mirror whichever convention the project's `settings.json` specifies. If `settings.json` has no channel preference, default to root-level phase folders.

---

## Uploading to a Teams channel (practical)

Once the `webUrl` and folder are known, it's a plain `spo file add` call. Teams picks up the file automatically — the Files tab is just a view over the SharePoint folder.

```bash
m365 spo file add \
  --webUrl "https://yourtenant.sharepoint.com/sites/Bolignet" \
  --folder "Shared Documents/01-requirements" \
  --path "./ba-requirements.md" \
  --publish --publishComment "BA Agent: requirements v1"
```

After the upload:

- The file appears under the Teams team's Files tab immediately
- Members get a "new file" notification if they follow the channel
- The file is subject to the library's versioning, retention, and sharing policies

---

## Posting a chat message alongside the file (optional)

Uploading a file doesn't automatically start a conversation about it. To notify the channel, post a message with a link to the file:

```bash
# Post a message to a specific channel
m365 teams message send \
  --teamId <team-id> \
  --channelId <channel-id> \
  --message "📄 Requirements v1 is up — see [Shared Documents/01-requirements/ba-requirements.md](...)"
```

Find the `channelId` with:

```bash
m365 teams channel list --teamId <team-id> --output json
```

For agent-driven notifications, consider routing through your existing WhatsApp/notification layer instead of Teams messages — keeps the "which channels am I authorized to post in" surface smaller.

---

## Chat files vs channel files

Files shared in Teams **chats** (1:1 or group) aren't in the team's SharePoint site at all. They live in the **sender's OneDrive**, under a folder called `Microsoft Teams Chat Files`.

For the multi-agent workflow this is usually irrelevant — agents should use channel files, which are shared with the whole team. But if you ever need to grab a chat attachment:

```bash
# List files in the user's OneDrive (chat files folder):
m365 onedrive list --userName user@tenant.com

# Download a specific file from OneDrive:
m365 spo file get \
  --webUrl "https://yourtenant-my.sharepoint.com/personal/user_tenant_com" \
  --url "/personal/user_tenant_com/Documents/Microsoft Teams Chat Files/filename.ext" \
  --asFile --path "./filename.ext"
```

Note the host is `<tenant>-my.sharepoint.com` for OneDrive, not `<tenant>.sharepoint.com`.

---

## Limits worth knowing

- **File size:** SharePoint/Teams supports up to 250 GB per file, but uploads via the CLI may be slower for files >100 MB. Consider chunked upload for very large files.
- **Path length:** SharePoint enforces a ~400-character limit on the full server-relative path. Deep nesting + long filenames will break silently.
- **Filename characters:** Avoid `" * : < > ? / \ |` and leading/trailing spaces. The CLI passes the filename through unchanged; SharePoint rejects invalid characters with a cryptic error.
- **Versioning:** If the library has versioning enabled (the default for Teams), re-uploading the same filename creates a new version rather than overwriting. Use `m365 spo file version list` if you need to see history.
