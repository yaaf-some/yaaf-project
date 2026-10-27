# Working rules

Rules for people and agents working in this repository. Keep it short: every line must prevent a mistake. Detail belongs
in the Issue or the code comment next to the thing it explains.

## What this is

A shop (Google's Online Boutique, vendored in `app/`) delivered to Kubernetes by GitOps: Argo CD deploys the manifests in
`deploy/`, `.github/` builds, scans and pins the images (arm64 only). Work is tracked in GitHub Issues.

## Commands

- `mise run check` runs the fast checks; it is also the pre-commit hook and the CI `check`. Run it before every push.
- Enable the hook once: `git config core.hooksPath .githooks`.
- Tool versions live only in `mise.toml` and `mise.lock`; bump them in a `chore/` PR (`mise upgrade --bump`, `mise lock`).

## AWS and money

- Only the owner creates or changes anything in AWS, from their own terminal. Agents hold no AWS credentials and never run
  the `aws` CLI or read `~/.aws` (both denied in `.claude/settings.json`; a script that opens the files itself is only
  blocked if the sandbox is on). If an AWS sign-in is visible, stop and say so.
- The account is on the Free plan and its credit is the spending cap. Anything billable is written down with a cost
  estimate before it exists. Never suggest a second account. Anything that needs a card is asked about first.
- The AWS Knowledge MCP (`.mcp.json`) is allowed: documentation only.
- Infrastructure as code is OpenTofu, not CDK or CloudFormation.
- For any secret, credential or token, use the `aws-secrets-manager` skill and `asm-exec`. Never call
  `secretsmanager get-secret-value` or `batch-get-secret-value`.

## Branching (GitHub Flow)

- `main` is always deployable (Argo CD deploys from it). It is protected: PRs only, required checks `check` and `build`,
  no force pushes.
- One short-lived branch per change, named `feat/`, `fix/`, `chore/` or `docs/` plus a slug. Dependabot and the pins bot
  (`bot/bump-images`, one open PR, auto-merges) keep their own names. In a Claude Code cloud session, work on the session's
  assigned branch and restart it from `main` after its PR merges.
- Open a PR early, squash-merge, delete the branch on merge. Titles are short and imperative. Old history lives at tags
  (`archive/*`), not in old branches.

## Delivery loop (agents)

1. Branch from `main`; run `mise run check` before every push.
2. Open a draft PR and subscribe to its activity.
3. Review with a separate pass that reads the diff cold (the `code-review` skill). Fix blocking findings; answer optional
   ones in one line.
4. Mark ready and enable auto-merge (squash), except where "Autonomy by path" below says the owner merges. A red check is
   fixed, not waited out.

**Stop and ask the owner** when an Issue has an open question, a change would contradict a decision recorded in an Issue,
or anything involves money, a card, AWS, secrets, repository settings or permissions, or deleting data.

## Issues and parallel work

- Work comes from Issues. A new Issue is `needs-triage`. A triage pass (the `triage` skill, at the start of a session)
  proposes label, milestone, size ("fits one PR?"), duplicates and `Blocked by`; the owner confirms. An agent that needs
  an answer posts one question and sets `needs-info`. Work found outside an Issue's scope becomes a new `needs-triage`
  Issue, not a bigger PR.
- A work Issue states Goal, Done when (with a planted fault where it fits), the paths it will touch, Blocked by, Out of
  scope. Labels: `ready-for-agent` (safe to run unattended), `ready-for-human`, `blocked`, `in-progress`, one `area:*`.
- At most 3 Issues are `in-progress`. Two in-progress Issues may not touch the same paths unless one is `Blocked by` the
  other. One owner per Issue, each in its own branch and git worktree. A PR closes its Issue with `Closes #N`.
- When you stop, post a handoff comment on the Issue: Done, Evidence, Next, Blockers, Surprises.
- Never turn a red check green by weakening it (a new accepted-findings entry, a loosened threshold, a skipped test)
  without the owner's approval.

### Autonomy by path

Until the kind deploy check is a required check, do not enable auto-merge on a PR that touches `deploy/` (the pins bot
excepted): mark it ready and stop. PRs that touch `.github/`, `.claude/`, `.githooks/`, `.mcp.json`, `.trivyignore.yaml`,
`CLAUDE.md`, `mise.toml`, `mise.lock` or `scripts/` are always merged by the owner. Docs and `app/` changes auto-merge
once `check` and `build` are green. This is a convention, not a control, until agents have their own GitHub identity.

## Evidence

Every claim about behavior is *designed*, *verified in CI* or *verified on AWS (date)*. Prove a new check against a planted
fault before trusting it, and retract a claim that turns out wrong.

## Code

- `app/` is vendored upstream code. Change it only through app Issues, and keep upstream's license notices.
- Comments say why, not what, and carry no decision or ticket numbers.
- Workflows: `permissions: {}`, actions pinned by SHA, no `pull_request_target` or `workflow_run`, zizmor clean.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`yaaf-some/yaaf-project`), via `gh`. External PRs are not a request surface.

### Triage labels

`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.

### Domain docs

None: no glossary and no ADRs. A decision lives in the Issue that made it.
