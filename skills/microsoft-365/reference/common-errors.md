# Common errors

The errors below cover roughly 90% of the real failures agents hit with `m365`. Before escalating to the user or retrying blindly, check this file.

---

## Auth errors

### `Error: The access token has expired`

The local cached token timed out. Run:

```bash
m365 login
```

If `m365 login` itself fails, clear the cache and retry:

```bash
m365 logout
m365 login
```

### `Error: You are not logged in` / `You must be logged in to execute this command`

Straightforward — run `m365 login`. If this happens in an agent script that *just* logged in, something cleared the cache mid-run (another process calling `m365 logout`, a container rebuild, etc.). Audit the environment.

### `AADSTS65001: The user or administrator has not consented to use the application`

Admin consent hasn't been granted for one or more of the API permissions the Entra app registration requests. The tenant admin must go to **Entra admin center → App registrations → <your app> → API permissions → Grant admin consent for \<tenant\>**.

See `reference/auth-setup.md` for the full flow.

### `AADSTS70011: The provided request must include a 'scope' input parameter`

Usually means the app registration is missing API permissions. Re-run `m365 setup` and let it re-provision permissions, or add them manually in Azure Portal.

---

## Site and path errors

### `Error: 404 FILE NOT FOUND` on a file that definitely exists

Almost always a URL format mistake. `m365 spo file get --url ...` expects a **server-relative URL** — starts with `/sites/<siteName>/...`, not an absolute URL.

```bash
# ❌ Wrong — absolute URL
--url "https://tenant.sharepoint.com/sites/Bolignet/Shared Documents/file.md"

# ✅ Right — server-relative URL
--url "/sites/Bolignet/Shared Documents/file.md"
```

Also check: case sensitivity of the site name, URL-encoded spaces (don't — pass them literally, just quote the whole argument).

### `The given URL is not valid` / site URL not recognized

You're using a server-relative path but the CLI doesn't know which tenant to resolve it against. Either:

- Pass `--webUrl` explicitly with the full tenant URL (always works)
- Run `m365 spo set --url "https://tenant.sharepoint.com"` once per session to set the default

### Folder doesn't exist on upload

`m365 spo file add` does not create parent folders. If the phase folder doesn't exist yet, create it first:

```bash
m365 spo folder add \
  --webUrl "$WEB_URL" \
  --parentFolderUrl "Shared Documents" \
  --name "01-requirements"
```

The `upload-artifact.sh` wrapper does this automatically — prefer it.

---

## File-state errors

### `File is checked out by another user`

Someone (or another agent instance) has the file checked out. Options:

1. **Wait and retry** if it's likely a brief edit by another agent.
2. **Force-check-in** if you're sure the checkout is stale:

   ```bash
   m365 spo file checkin \
     --webUrl "$WEB_URL" \
     --fileUrl "/sites/.../file.md" \
     --comment "Forced check-in — recovering stale lock"
   ```

   Only do this with explicit user approval — it may discard unsaved changes from whoever had the checkout.

3. **Upload with a different filename** (e.g., append a timestamp) if conflict-avoidance is more important than preserving the canonical path.

### `File already exists at path`

Expected behavior on re-upload if the library has versioning disabled. Either enable versioning (preferred — you get history for free) or pass `--fileName` to upload under a different name.

### `The file size exceeds the allowed limit`

Default limit is 250 GB, but tenants can restrict further. For files >100 MB, the CLI uses chunked upload automatically but it's slower. Check the library's quota in SharePoint admin if uploads of modest-sized files (< 1 GB) fail.

---

## Settings / config errors

### `settings.json not found` or malformed

The skill's wrapper scripts fail fast when `settings.json` is missing. Fix by:

1. Confirming the user is running from the right client workspace (`~/workspace/<client>/`)
2. If `settings.json` doesn't exist, create it (see SKILL.md for the expected shape)
3. If it exists but lacks the `m365` block, add it — the scripts print a clear error naming the missing field

### `m365.siteName not set` or `m365.tenantUrl not set`

Exactly what it says. Add the missing field to `settings.json` and retry. The scripts don't guess defaults — the URL matters too much to get wrong silently.

---

## Network and transient errors

### `ETIMEDOUT`, `ECONNRESET`, `503 Service Unavailable`

Microsoft 365 has transient throttling. Retry with exponential backoff — the CLI itself doesn't retry automatically. For agent scripts:

```bash
for attempt in 1 2 3; do
  if m365 spo file add --webUrl "$WEB_URL" --folder "$FOLDER" --path "$FILE"; then
    break
  fi
  sleep $((attempt * 5))
done
```

### `429 Too Many Requests` / `Request was throttled`

SharePoint throttling. Slow down. Respect any `Retry-After` header in the error output. If an agent is bulk-uploading (e.g., a test report with many attachments), add a deliberate 500ms sleep between calls.

---

## Output parsing errors

### JSON parse fails on `m365 ... --output json` result

Usually one of:

1. **Command also printed a warning to stdout** that ended up in the JSON stream. Redirect stderr and check: `m365 ... --output json 2>/dev/null`.
2. **Empty result** — the command succeeded but there's nothing to return. Check exit code before parsing.
3. **Using default text output accidentally** — always pass `--output json` explicitly.

### Command exited 0 but didn't do what was expected

`m365` sometimes returns success on no-ops (e.g., removing a file that doesn't exist with `--force`). Check the actual state after the command rather than trusting exit code alone.

---

## When none of the above fit

1. Run the failing command with `--verbose` to get the underlying HTTP calls:

   ```bash
   m365 spo file add ... --verbose
   ```

2. Add `--debug` for full request/response details. Dump this into the user's report rather than trying to interpret it — the CLI author and Microsoft Graph docs are the authoritative sources for deep failures.

3. Cross-reference the command's docs page, e.g., `https://pnp.github.io/cli-microsoft365/cmd/spo/file/file-add/` — each command has a "Remarks" section that documents known gotchas.
