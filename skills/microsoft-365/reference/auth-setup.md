# Auth setup for m365 CLI

This file covers first-time setup and ongoing auth maintenance. Read it whenever `m365 status` reports "Logged out" or a command fails with an auth error.

## The short version

```bash
# First time ever on this machine — creates an Entra app registration:
m365 setup

# Every subsequent session — starts device code login:
m365 login

# Verify:
m365 status
```

That's usually enough. Read on for the details and for when things don't go smoothly.

---

## First-time setup (one time per machine)

The CLI authenticates against Microsoft 365 through a **Microsoft Entra application registration** — an OAuth client that represents the CLI in your tenant. Each user needs one.

### Option A — Guided setup (recommended)

```bash
m365 setup
```

This command walks through the setup interactively. It will ask:

- How the user plans to use the CLI (interactively vs scripts vs CI/CD)
- Whether to create a new Entra app registration or use an existing one
- Which login flow to configure (device code is default and works everywhere)

Choose "create new" unless an admin has already provisioned a shared app registration for the team.

### Option B — Use an existing app registration

If the tenant admin has created an app registration for CLI use, get these three values from them and run:

```bash
m365 setup \
  --clientId <app-id-guid> \
  --tenant <tenant-id-guid>
```

### What `m365 setup` actually does

1. Creates (or references) an Entra app registration in the tenant
2. Configures the required API permissions (Microsoft Graph, SharePoint, etc.)
3. Stores the app ID and tenant ID locally under `~/.config/@pnp/cli-microsoft365/`
4. Sets the default login flow to device code

The app registration is **per-user, per-tenant**. If the user works with multiple tenants, they'll need to either switch connections (`m365 connection use`) or re-run setup for each tenant.

---

## Logging in

```bash
m365 login
```

This starts the **device code flow**:

1. The CLI prints a short code and a URL (`https://microsoft.com/devicelogin`)
2. Open that URL in a browser, paste the code, sign in
3. The CLI picks up the token and returns to the prompt

Device code flow works on headless machines (servers, CI runners) because the browser step happens on whatever device the user has handy.

### Non-interactive login (for CI/CD or scripted agents)

For agents running unattended, use certificate-based auth or a secret. **Never commit credentials** — pull them from environment variables or a secret store:

```bash
# Certificate (preferred for production agents):
m365 login --authType certificate --certificateFile ./cert.pfx --password $CERT_PW

# App-only with secret (simpler, less secure):
m365 login --authType secret --secret $M365_SECRET
```

These require the Entra app registration to have the right permissions granted with admin consent. See the `pnp/cli-microsoft365` docs on "Using your own Microsoft Entra identity" for the full permission list.

---

## Checking status

```bash
m365 status
```

Outputs either:

- `Logged in as <user>@<tenant>` — good to go
- `Logged out` — run `m365 login`

For JSON output (useful when an agent needs to branch on auth state):

```bash
m365 status --output json
```

---

## Logging out

```bash
m365 logout
```

This clears the local token cache. The app registration itself stays — only the session is invalidated.

---

## Switching between tenants

If the user deals with multiple tenants (e.g., one per client), use named connections:

```bash
# First time — save a connection under a name:
m365 login --connectionName "bolignet"
m365 login --connectionName "visioneers"

# Later — switch between them:
m365 connection use --name "bolignet"
m365 connection list
```

This is especially useful when the multi-agent workflow spans clients — agents can pick the right connection based on the `client` field in `settings.json`.

---

## Troubleshooting

### "Error: The access token has expired"

Tokens expire. Just run `m365 login` again. If the CLI was supposed to refresh automatically and didn't, clear the cache:

```bash
m365 logout
m365 login
```

### "AADSTS65001: The user or administrator has not consented to use the application"

An admin needs to grant consent for the permissions the CLI is requesting. Either:

- Ask the tenant admin to grant consent on the Entra app registration (Entra admin center → App registrations → `<your app>` → API permissions → Grant admin consent)
- If self-service consent is allowed, the user can grant it during `m365 login` themselves

### "AADSTS50076: Due to a configuration change... multi-factor authentication"

Device code flow handles MFA fine — follow the MFA prompt in the browser. If using `--authType password` (deprecated, avoid), switch to device code.

### Device code flow says "We can't sign you in"

Usually means the Entra app registration is misconfigured. Delete the local config and re-run setup:

```bash
rm -rf ~/.config/@pnp/cli-microsoft365/
m365 setup
```

### Wrong tenant

Check which tenant the current app registration points to:

```bash
m365 status --output json
```

Look for `connectedAs` and the tenant ID. If it's wrong, either switch connections (see above) or re-run `m365 setup` pointing at the right tenant.

---

## For agents operating unattended

When writing an agent that will run `m365` commands on a schedule or in response to events (e.g., the WhatsApp comm agent), prefer:

1. **Certificate auth** over secrets, and over user-interactive login
2. A **dedicated Entra app registration** per agent rather than reusing a developer's personal one
3. **Minimum permissions** — only grant the Graph/SPO scopes the agent actually needs
4. **Connection names** matching the client — so `m365 connection use --name "$CLIENT"` always points at the right tenant

Never use `--authType password` for agents — it's deprecated and won't work with MFA-enabled accounts (which is basically all of them now).
