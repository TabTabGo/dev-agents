# Team Work Items — Queries & Conventions

Recipes for common team-oriented work item queries (by user, by iteration, by status) and the conventions this skill enforces when creating iterations and work items for features and releases.

All WIQL queries are run via:

```bash
az boards query --wiql "<WIQL>" --project {project} --output table
```

When scripting, prefer `--output json` and filter with `--query` (JMESPath) as needed.

## Resolving Team Member Emails

**Never ask the user for an email or guess one.** When the user refers to a teammate by name or role (e.g. "Ghassan", "the BE", "our QA"), resolve the email from the root `.claude/settings.json` file, which contains a `teamMembers` array:

```json
{
  "teamMembers": [
    { "name": "Member Name", "email": "member@example.com", "role": "BE" }
  ]
}
```

Valid `role` values: `FE`, `BE`, `QA`, `PM`, `BA`, `ARC`, `PO`.

Resolution rules:

1. Match by `name` (case-insensitive, partial match allowed) → use the `email`.
2. If the user refers to a role (e.g. "assign to the QA"), match by `role`. If multiple members share the role, list them and ask which one.
3. If no match is found, tell the user which names/roles are available from `teamMembers` instead of guessing.

Example lookup:

```bash
# Resolve email by name
jq -r --arg n "Ghassan" '.teamMembers[] | select(.name | test($n; "i")) | .email' \
  .claude/settings.json

# List all members of a role
jq -r --arg r "BE" '.teamMembers[] | select(.role == $r) | "\(.name) <\(.email)>"' \
  .claude/settings.json
```

## Standard WIQL SELECT

**Every WIQL query in this file returns the same columns** so output is consistent and scriptable:

```sql
SELECT [System.Id],
       [System.TeamProject],
       [System.IterationPath],
       [System.AreaPath],
       [System.Title],
       [System.AssignedTo],
       [System.State],
       [System.Tags]
FROM WorkItems
```

Referred to below as `<STANDARD_SELECT>`. Never drop or reorder columns — downstream formatters depend on them.

---

## Table of Contents

- [1. Work items assigned to a user](#1-work-items-assigned-to-a-user)
- [2. Work items assigned to a user, filtered by statuses](#2-work-items-assigned-to-a-user-filtered-by-statuses)
- [3. Work items assigned to a user, grouped by iteration](#3-work-items-assigned-to-a-user-grouped-by-iteration)
- [4. Work items in an iteration](#4-work-items-in-an-iteration)
- [5. Work items in an iteration, filtered by statuses](#5-work-items-in-an-iteration-filtered-by-statuses)
- [6. Work items in an iteration, grouped by assignee](#6-work-items-in-an-iteration-grouped-by-assignee)
- [7. Iteration status — all non-closed work items](#7-iteration-status--all-non-closed-work-items)
- [8. Create a feature iteration](#8-create-a-feature-iteration)
- [9. Create a release iteration](#9-create-a-release-iteration)
- [10. Create a User Story with child Tasks](#10-create-a-user-story-with-child-tasks)

---

## 1. Work items assigned to a user

Use `@Me` for the current authenticated user, or resolve the email from `teamMembers` (see above) for someone else.

```bash
# Current user
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.AssignedTo] = @Me
ORDER BY [System.ChangedDate] DESC"

# Specific user (email resolved from .claude/settings.json teamMembers)
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.AssignedTo] = 'member@example.com'
ORDER BY [System.ChangedDate] DESC"
```

## 2. Work items assigned to a user, filtered by statuses

Pass the list of statuses via the WIQL `IN` operator.

```bash
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.AssignedTo] = 'member@example.com'
  AND [System.State] IN ('Active', 'In Progress', 'Ready for Review')
ORDER BY [System.State], [System.ChangedDate] DESC"
```

## 3. Work items assigned to a user, grouped by iteration

WIQL does not support `GROUP BY`. Fetch sorted by `IterationPath`, then group client-side.

```bash
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.AssignedTo] = 'member@example.com'
ORDER BY [System.IterationPath], [System.State]" --output json \
  | jq 'group_by(.fields."System.IterationPath")
        | map({iteration: .[0].fields."System.IterationPath",
               count: length,
               items: map({id: .id,
                          project: .fields."System.TeamProject",
                          iteration: .fields."System.IterationPath",
                          area: .fields."System.AreaPath",
                          title: .fields."System.Title",
                          assignedTo: .fields."System.AssignedTo".displayName,
                          state: .fields."System.State",
                          tags: .fields."System.Tags"})})'
```

## 4. Work items in an iteration

Use the full iteration path (backslash-separated, e.g. `{project}\features\user-authentication`). Use `UNDER` to include sub-iterations.

```bash
# Exact iteration
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.IterationPath] = '{project}\\features\\user-authentication'
ORDER BY [System.State]"

# Iteration and all sub-iterations
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.IterationPath] UNDER '{project}\\releases\\v1.9.3'
ORDER BY [System.State]"
```

## 5. Work items in an iteration, filtered by statuses

```bash
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.IterationPath] = '{project}\\features\\user-authentication'
  AND [System.State] IN ('Active', 'In Progress', 'Ready for Review')
ORDER BY [System.State]"
```

## 6. Work items in an iteration, grouped by assignee

```bash
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.IterationPath] = '{project}\\features\\user-authentication'
ORDER BY [System.AssignedTo], [System.State]" --output json \
  | jq 'group_by(.fields."System.AssignedTo".displayName // "Unassigned")
        | map({assignee: (.[0].fields."System.AssignedTo".displayName // "Unassigned"),
               count: length,
               items: map({id: .id,
                          project: .fields."System.TeamProject",
                          iteration: .fields."System.IterationPath",
                          area: .fields."System.AreaPath",
                          title: .fields."System.Title",
                          state: .fields."System.State",
                          tags: .fields."System.Tags"})})'
```

## 7. Iteration status — all non-closed work items

When the user asks *"what is the status of iteration X"*, return every work item under that iteration whose state is **not** terminal. Terminal states in the default Agile/Scrum/Basic processes: `Closed`, `Done`, `Removed`.

```bash
az boards query --project {project} --wiql "
<STANDARD_SELECT>
WHERE [System.IterationPath] UNDER '{project}\\features\\user-authentication'
  AND [System.State] NOT IN ('Closed', 'Done', 'Removed')
ORDER BY [System.State]"
```

Summarize by state for a quick status view (same query, piped through `jq`):

```bash
# ... | jq 'group_by(.fields."System.State")
#          | map({state: .[0].fields."System.State", count: length})'
```

---

## Iteration Creation Conventions

**These rules are mandatory** and mirror the branch-naming rules in `repos-and-prs.md`. Feature and release work must live under matching iteration paths so boards and git history line up.

Iteration paths use backslashes in WIQL (`{project}\features\{name}`) and are created with `az boards iteration project create --path`.

### 8. Create a feature iteration

When the user mentions creating a **feature**, create an iteration under `features/{feature-name-in-kebab-case}` that matches the feature branch.

```bash
# Parent container (create once per project, idempotent — ignore "already exists" errors)
az boards iteration project create \
  --path "features" \
  --project {project}

# Feature iteration
az boards iteration project create \
  --path "features\\user-authentication" \
  --project {project}
```

Examples:

- `features\user-authentication`
- `features\payment-gateway-integration`
- `features\export-to-pdf`

### 9. Create a release iteration

When the user mentions creating a **release**, create an iteration under `releases/vX.Y.Z` (the concrete release number). Unlike release branches (which use the `vX.Y.x/vX.Y.Z` two-level structure), release **iterations** are a single level under `releases`.

```bash
# Parent container (create once per project)
az boards iteration project create \
  --path "releases" \
  --project {project}

# Release iteration — use the concrete release number
az boards iteration project create \
  --path "releases\\v1.9.3" \
  --project {project}
```

Examples:

- `create release v1.9.3` → iteration `releases\v1.9.3`
- `create release v2.0.0` → iteration `releases\v2.0.0`

### Add the iteration to the team

Newly created iterations are not automatically visible on a team's board. Add them:

```bash
az boards iteration team add \
  --team {team-name} \
  --path "{project}\\features\\user-authentication" \
  --project {project}
```

---

## 10. Create a User Story with child Tasks

**Rule:** every User Story represents a business requirement. The implementation work is broken down into child Tasks linked to that User Story. Create the User Story first, then create each Task with a `parent` relation back to the story.

```bash
# 1. Create the User Story (the business requirement)
STORY_ID=$(az boards work-item create \
  --project {project} \
  --type "User Story" \
  --title "User can sign in with SSO" \
  --description "As a user I want to sign in with my corporate SSO so I can access the app with a single credential." \
  --area "{project}\\{area}" \
  --iteration "{project}\\features\\user-authentication" \
  --fields "Microsoft.VSTS.Common.AcceptanceCriteria=Given a valid SSO session, when the user clicks 'Sign in', they land on the dashboard." \
  --query "id" -o tsv)

echo "Created User Story #$STORY_ID"

# 2. Create child Tasks describing the work to be done
for TASK_TITLE in \
  "Add SSO button to login page" \
  "Wire OIDC callback handler" \
  "Persist session token securely" \
  "Add integration tests for SSO flow"
do
  TASK_ID=$(az boards work-item create \
    --project {project} \
    --type "Task" \
    --title "$TASK_TITLE" \
    --iteration "{project}\\features\\user-authentication" \
    --query "id" -o tsv)

  az boards work-item relation add \
    --id "$TASK_ID" \
    --relation-type parent \
    --target-id "$STORY_ID"
done
```

Notes:

- `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=..."` captures the acceptance criteria portion of the business requirement. The `--description` field holds the narrative.
- The iteration on Tasks should match the parent User Story.
- Use `az boards work-item relation list-type` to see all supported relation names if `parent` is not recognised in your process template.
