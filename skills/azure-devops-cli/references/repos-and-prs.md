# Repositories & Pull Requests

## Table of Contents
- [Repositories](#repositories)
- [Repository Import](#repository-import)
- [Pull Requests](#pull-requests)
- [Git References](#git-references)
- [Repository Policies](#repository-policies)

---

## Repositories

### List Repositories

```bash
az repos list --org https://dev.azure.com/{org} --project {project}
az repos list --output table
```

### Show Repository Details

```bash
az repos show --repository {repo-name} --project {project}
```

### Create Repository

```bash
az repos create --name {repo-name} --project {project}
```

### Delete Repository

```bash
az repos delete --id {repo-id} --project {project} --yes
```

### Update Repository

```bash
az repos update --id {repo-id} --name {new-name} --project {project}
```

## Repository Import

### Import Git Repository

```bash
# Import from public Git repository
az repos import create \
  --git-source-url https://github.com/user/repo \
  --repository {repo-name}

# Import with authentication
az repos import create \
  --git-source-url https://github.com/user/private-repo \
  --repository {repo-name} \
  --user {username} \
  --password {password-or-pat}
```

## Pull Requests

### Create Pull Request

```bash
# Basic PR creation
az repos pr create \
  --repository {repo} \
  --source-branch {source-branch} \
  --target-branch {target-branch} \
  --title "PR Title" \
  --description "PR description" \
  --open

# PR with work items
az repos pr create \
  --repository {repo} \
  --source-branch {source-branch} \
  --work-items 63 64

# Draft PR with reviewers
az repos pr create \
  --repository {repo} \
  --source-branch feature/new-feature \
  --target-branch main \
  --title "Feature: New functionality" \
  --draft true \
  --reviewers user1@example.com user2@example.com \
  --required-reviewers lead@example.com \
  --labels "enhancement" "backlog"
```

### List Pull Requests

```bash
# All PRs
az repos pr list --repository {repo}

# Filter by status
az repos pr list --repository {repo} --status active

# Filter by creator
az repos pr list --repository {repo} --creator {email}

# Output as table
az repos pr list --repository {repo} --output table
```

### Show PR Details

```bash
az repos pr show --id {pr-id}
az repos pr show --id {pr-id} --open  # Open in browser
```

### Update PR (Complete/Abandon/Draft)

```bash
# Complete PR
az repos pr update --id {pr-id} --status completed

# Abandon PR
az repos pr update --id {pr-id} --status abandoned

# Set to draft
az repos pr update --id {pr-id} --draft true

# Publish draft PR
az repos pr update --id {pr-id} --draft false

# Auto-complete when policies pass
az repos pr update --id {pr-id} --auto-complete true

# Set title and description
az repos pr update --id {pr-id} --title "New title" --description "New description"
```

### Checkout PR Locally

```bash
# Checkout PR branch
az repos pr checkout --id {pr-id}

# Checkout with specific remote
az repos pr checkout --id {pr-id} --remote-name upstream
```

### Vote on PR

```bash
az repos pr set-vote --id {pr-id} --vote approve
az repos pr set-vote --id {pr-id} --vote approve-with-suggestions
az repos pr set-vote --id {pr-id} --vote reject
az repos pr set-vote --id {pr-id} --vote wait-for-author
az repos pr set-vote --id {pr-id} --vote reset
```

### PR Reviewers

```bash
# Add reviewers
az repos pr reviewer add --id {pr-id} --reviewers user1@example.com user2@example.com

# List reviewers
az repos pr reviewer list --id {pr-id}

# Remove reviewers
az repos pr reviewer remove --id {pr-id} --reviewers user1@example.com
```

### PR Work Items

```bash
# Add work items to PR
az repos pr work-item add --id {pr-id} --work-items {id1} {id2}

# List PR work items
az repos pr work-item list --id {pr-id}

# Remove work items from PR
az repos pr work-item remove --id {pr-id} --work-items {id1}
```

### PR Policies

```bash
# List policies for a PR
az repos pr policy list --id {pr-id}

# Queue policy evaluation for a PR
az repos pr policy queue --id {pr-id} --evaluation-id {evaluation-id}
```

## Git References

### Branch Naming Rules

**These rules are mandatory when creating branches.** All new branches must be created from `main` (or `master` if `main` does not exist).

#### Feature Branches

When the user mentions creating a branch for a **feature**, use:

```text
features/{feature-name-in-kebab-case}
```

Examples:

- `features/user-authentication`
- `features/payment-gateway-integration`
- `features/export-to-pdf`

#### Release Branches

When the user mentions creating a **release**, use the two-level structure:

```text
releases/vX.Y.x/vX.Y.Z
```

Where `vX.Y.x` is the minor-version "bucket" (patch component literally `x`) and `vX.Y.Z` is the concrete release.

Examples:

- `create release v1.9.3` → `releases/v1.9.x/v1.9.3`
- `create release v2.0.0` → `releases/v2.0.x/v2.0.0`
- `create release v1.10.5` → `releases/v1.10.x/v1.10.5`

#### Creating From main/master

Both feature and release branches **must** be created from the latest commit of `main` (fallback to `master`):

```bash
# Get latest commit SHA from main (fallback to master)
BASE_SHA=$(az repos ref list --repository {repo} \
  --query "[?name=='refs/heads/main'].objectId | [0]" -o tsv)
[ -z "$BASE_SHA" ] && BASE_SHA=$(az repos ref list --repository {repo} \
  --query "[?name=='refs/heads/master'].objectId | [0]" -o tsv)

# Feature branch
az repos ref create \
  --name refs/heads/features/{feature-name-in-kebab-case} \
  --object-type commit \
  --object "$BASE_SHA" \
  --repository {repo}

# Release branch (e.g. v1.9.3)
az repos ref create \
  --name refs/heads/releases/v1.9.x/v1.9.3 \
  --object-type commit \
  --object "$BASE_SHA" \
  --repository {repo}
```

### List References (Branches)

```bash
az repos ref list --repository {repo}
az repos ref list --repository {repo} --query "[?name=='refs/heads/main']"
```

### Create Reference (Branch)

```bash
az repos ref create --name refs/heads/new-branch --object-type commit --object {commit-sha}
```

### Delete Reference (Branch)

```bash
az repos ref delete --name refs/heads/old-branch --repository {repo} --project {project}
```

### Lock/Unlock Branch

```bash
az repos ref lock --name refs/heads/main --repository {repo} --project {project}
az repos ref unlock --name refs/heads/main --repository {repo} --project {project}
```

## Repository Policies

### Main Branch Ruleset (mandatory baseline)

**Every repository must apply this ruleset to `main` (and `master` if it exists):**

- All changes to `main` must go through a Pull Request — direct push is forbidden.
- Only members of the **Project Administrators** group may push directly or bypass policies (e.g. for emergency hotfixes).
- Everyone else (Contributors) commits to a feature/release branch and merges via PR.

In Azure DevOps this is enforced by combining **branch policies** (which block non-PR pushes once they are blocking + enabled) with **branch-scoped permissions** (which restrict who may bypass).

```bash
# Resolve repo + project ids
PROJECT_ID=$(az devops project show --project {project} --query id -o tsv)
REPO_ID=$(az repos show --repository {repo} --project {project} --query id -o tsv)
ADMIN_GROUP_DESCRIPTOR=$(az devops security group list --project {project} \
  --query "graphGroups[?displayName=='Project Administrators'].descriptor | [0]" -o tsv)
CONTRIB_GROUP_DESCRIPTOR=$(az devops security group list --project {project} \
  --query "graphGroups[?displayName=='Contributors'].descriptor | [0]" -o tsv)

# 1. Blocking branch policy: require ≥1 reviewer (this is what forces PR-only flow)
az repos policy approver-count create \
  --blocking true --enabled true \
  --branch main --repository-id "$REPO_ID" \
  --minimum-approver-count 1 \
  --creator-vote-counts false \
  --allow-downvotes false \
  --reset-on-source-push true

# 2. Require linked work items on every PR
az repos policy work-item-linking create \
  --blocking true --enabled true \
  --branch main --repository-id "$REPO_ID"

# 3. Require all PR comments to be resolved
az repos policy comment-required create \
  --blocking true --enabled true \
  --branch main --repository-id "$REPO_ID"

# 4. Restrict the bypass: only Project Administrators may push to / bypass policies on main
#    Security namespace "Git Repositories" GUID is fixed: 2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87
#    Token format for a branch: repoV2/<projectId>/<repoId>/refs/heads/<branch>
GIT_NS=2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87
TOKEN="repoV2/$PROJECT_ID/$REPO_ID/refs/heads/main"

# Deny "Contribute" (push) and "Bypass policies when pushing/completing PR" for Contributors
# Bit values: Contribute=4, BypassPoliciesPush=128, BypassPoliciesCompletePR=32768
az devops security permission update \
  --namespace-id "$GIT_NS" \
  --subject "$CONTRIB_GROUP_DESCRIPTOR" \
  --token "$TOKEN" \
  --deny-bit $((4 + 128 + 32768))

# Allow the same bits for Project Administrators (admins keep push + bypass)
az devops security permission update \
  --namespace-id "$GIT_NS" \
  --subject "$ADMIN_GROUP_DESCRIPTOR" \
  --token "$TOKEN" \
  --allow-bit $((4 + 128 + 32768))

# Verify
az devops security permission show \
  --namespace-id "$GIT_NS" \
  --subject "$CONTRIB_GROUP_DESCRIPTOR" \
  --token "$TOKEN"
```

Apply the same block to `master` by repeating with `--branch master` and `refs/heads/master` in the token. Apply to long-lived release branches by setting the token to `repoV2/$PROJECT_ID/$REPO_ID/refs/heads/releases` (covers all `releases/*`).

**Permission bit reference for the Git Repositories namespace** (use these in `--allow-bit` / `--deny-bit`):

| Bit   | Name                                     | Effect                                     |
| ----: | ---------------------------------------- | ------------------------------------------ |
|     2 | GenericContribute (legacy)               | Read/contribute                            |
|     4 | Contribute                               | Push commits to the branch                 |
|     8 | ForcePush                                | Force-push / rewrite history               |
|    16 | CreateBranch                             | Create branches under the token            |
|   128 | PolicyExempt (push)                      | Push that bypasses branch policies         |
| 32768 | BypassPoliciesWhenCompletingPullRequests | Complete a PR ignoring failing policies    |

Combine with `+` as shown above.

### List All Policies

```bash
az repos policy list --repository {repo-id} --branch main
```

### Create/Update/Delete Policy

```bash
# Create from config file
az repos policy create --config policy.json

# Update
az repos policy update --id {policy-id} --config updated-policy.json

# Delete
az repos policy delete --id {policy-id} --yes
```

### Approver Count Policy

```bash
az repos policy approver-count create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --minimum-approver-count 2 \
  --creator-vote-counts true
```

### Build Policy

```bash
az repos policy build create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --build-definition-id {definition-id} \
  --queue-on-source-update-only true \
  --valid-duration 720
```

### Work Item Linking Policy

```bash
az repos policy work-item-linking create \
  --blocking true \
  --branch main \
  --enabled true \
  --repository-id {repo-id}
```

### Required Reviewer Policy

```bash
az repos policy required-reviewer create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --required-reviewers user@example.com
```

### Merge Strategy Policy

```bash
az repos policy merge-strategy create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --allow-squash true \
  --allow-rebase true \
  --allow-no-fast-forward true
```

### Case Enforcement Policy

```bash
az repos policy case-enforcement create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id}
```

### Comment Required Policy

```bash
az repos policy comment-required create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id}
```

### File Size Policy

```bash
az repos policy file-size create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --maximum-file-size 10485760  # 10MB in bytes
```
