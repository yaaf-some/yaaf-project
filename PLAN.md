# Plan

The one living document: what the project is for, where it stands, what is next, and the decisions made. It is kept short on
purpose. The longer target design (components, cost guardrails, later stages) is a draft in
[`docs/architecture/design-draft.md`](docs/architecture/design-draft.md); the evidence behind it is in `docs/research/`.
Rewritten from scratch on 2026-10-08; the Floci-era plan is at the tag `archive/floci-era` (made at stage 0).

**How it is used.** Decisions are asked in chat as clickable questions; each answer becomes one row below. Code comments cite
`PLAN.md D<n>`; numbers are never reused. **Status: a proposal** until the owner accepts it.

## Now

*Update at the end of every session, on any machine; it is the first thing a new session reads.*

- **Date:** 2026-10-23. **Branch and PR:** `claude/yaaf-cloud-migration-lsl4lq`, draft [#50](https://github.com/yaaf-some/yaaf-project/pull/50). Not merged: the owner is reviewing the plan.
- **In AWS:** nothing created. Free plan opened 2026-10-12, ends 2027-04-12; about $100 of credit (D65).
- **Owner's setup:** Mac mini (M2, 16 GB, macOS 27.2), Claude Pro, Docker Desktop (D66).
- **Next:** (1) the owner accepts or changes this plan; (2) one agent PR makes the Mac ready; (3) the owner's first apply of `infra/account`.

## What this is

A fictional online store run the way a small company would run it, built by one person to learn and to show the work. The
owner is the **DevOps engineer and cloud architect**; AI agents play the two development teams (Catalog, Checkout), the
customers (load) and the bad days (planted faults). It is for the owner's learning first, then for reviewers who spend a few
minutes and judge the decisions, diagrams, cost awareness and CI.

**Goals:** G1 safe delivery of agent-written change (each gate proved against a planted fault); G2 real AWS, used
responsibly; G3 cost discipline (nothing running when idle); G4 measurable reliability (SLOs, recovery drills); G5 written
architecture judgement.

## Constraints

- **Money (D65):** the Free plan credit (about $100) is the cap until the upgrade, by 2027-04-01; after it, at most $20 a month.
- **No long-lived infrastructure.** Environments are created for a purpose and destroyed after it.
- **Agents never change the AWS account (D64).** The owner applies, in their own terminal.
- **Honest evidence.** Every claim is *designed*, *verified in CI* or *verified on AWS (date)*; a new check is trusted only after it catches a planted fault.

## Shape

Two environments from one git configuration (D63): a **CI environment** (kind on a free GitHub arm64 runner or on the Mac, $0,
proves the delivery system on every change) and an **AWS session** (EKS, short and self-destroying, about $1 on the Free plan,
proves AWS behaviour). The full table, components and cost guardrails are in the design draft.

## Stages

### Stage 0: decide and reset *($0)*

- [ ] The owner accepts this plan (open question below)
- [ ] Tag `archive/floci-era`; remove Floci roots and tasks; rewrite `CLAUDE.md` (its "zero AWS spend" bullet and the borrowed-sandbox section are stale) and the README
- [ ] Rulesets on `main` with no bypass; required checks named

### Stage 1: the app and the CI environment *($0)*

- [ ] The retail sample vendored at a pinned commit, with its license
- [ ] Images built, scanned and attested per service (existing pipeline, adapted)
- [ ] `mise run ci-env`: kind with Argo CD, Traefik, Kyverno and the app from git, as a required check; proved red by a planted bad digest and an unattested image

### Stage 2a: the Free-plan interim *(from the credits; about $1 per session)*

- [x] AWS Knowledge MCP wired (`.mcp.json`; docs only, no credentials)
- [x] Account root `infra/account/` (state bucket, permissions boundary, deployer role) with 4 offline tests, each shown to fail on a planted fault
- [x] CloudShell runbook `docs/guides/account-bootstrap-cloudshell.md` (marked *to verify*)
- [ ] **Mac ready (D66), one agent PR:** `scripts/bootstrap`, `kind` pinned in `mise.toml`, decide the Floci-era AWS paths in `mise.toml`, settings denying agents `~/.aws`. Then the owner installs Docker Desktop and Claude Code, runs bootstrap and `mise run check`, proves a kind node reports `cgroup2fs`, probes that an agent cannot read `~/.aws`, sets up Remote Control and the phone app
- [ ] Owner in AWS Settings: confirm Region and account ID; Cost Explorer on; Budgets alert at half the credits
- [ ] **Owner, first real apply** of `infra/account` per the runbook (CloudShell or the Mac); the agent does not apply. Record what AWS enforces, with the date
- [ ] Migrate the bootstrap state into its bucket; add the backup bucket (D42) before any session stores data
- [ ] A first owner-run EKS session (on-demand nodes, Pod Identity, Argo CD), with its create/destroy times and credit cost recorded
- [ ] **Gate to stage 2:** upgrade and activate advanced features by 2027-04-01 (or earlier if credits run out), only once stage 1 is done

**Later (stages 2 to 9):** the AWS landing zone (Organization, SCPs, OIDC, reapers), the first automated session, data and recovery, security, observability and SLOs, the agent teams, customers and bad days, the showcase, and the architecture track. Their checklists are in the design draft and become real when reached.

## Open questions

- **? The plan as a whole.** Accept D63 to D67 and the stages above, or change them.
- **? A read-only identity.** Does the new AWS experience offer a read-only role an agent could sign in with (D64)? Until then, docs only.
- **? Credits and the upgrade.** Do unused credits survive the upgrade? Decides whether to spend them down before 2027-04-01.

## Decisions

| | Decision | Why |
|---|---|---|
| <a id="d63"></a>D63 | **Two places, one configuration.** Everyday work and tests run on a small Kubernetes (kind) on the owner's Mac mini and on GitHub's free runners. Real AWS is used only in short EKS sessions that destroy themselves (about $1 each on the Free plan's on-demand nodes). Floci is dropped. *Decided 2026-10-23* | Real AWS behaviour where it matters, for cents; the delivery system tested on every change for free. A forgotten cluster costs about $5 a day, so AWS is never the default place ([research](docs/research/2026-10-08-rebuild-research.md)) |
| <a id="d64"></a>D64 | **Only the owner changes AWS.** The owner runs plan and apply in their own terminal (the Mac; CloudShell until it is ready) and no agent session runs while that sign-in is live. Agents may look, never change, and only through a read-only AWS identity if AWS offers one for this account; until then they have documentation only, through the AWS Knowledge MCP (`.mcp.json`, no credentials). The checked-in settings deny agents `~/.aws`. *Decided 2026-10-23* | An agent holding cloud credentials is the main risk, and Claude's sandbox can read `~/.aws` unless told not to ([research](docs/research/2026-10-22-work-environment-local-vs-cloud.md)) |
| <a id="d65"></a>D65 | **Money and the account.** Stay on the Free plan: its credit (about $100) is the cap, and AWS suspends rather than bills. Upgrade once, and activate advanced features, by **2027-04-01** (the six-month period ends 2027-04-12), or earlier if a stage needs what the Free plan denies (GitHub OIDC, Spot, an Organization of our own, Fault Injection Service). After the upgrade: at most $20 a month, with the cost-protection layers designed then. Region `us-east-1`. *Decided 2026-10-23* | The credit is a stronger cap than anything we could build, and both AWS steps are irreversible, so they wait for a reason ([research](docs/research/2026-10-13-aws-new-experience.md)) |
| <a id="d66"></a>D66 | **Where the work runs.** The Mac mini (Docker Desktop with kind) is the main workbench for AWS and Kubernetes work. Claude cloud sessions and the phone handle code, review and planning, and are the fallback when the Mac is off. The repository is the only memory: the Now block above, a one-command bootstrap, a lockfile that covers the Mac. *Decided 2026-10-23* | The cloud container cannot run Kubernetes 1.35+ (cgroup v1) and its AWS sign-in dies with the VM; a Mac has both a usable kernel and a safe place for the owner's sign-in. It cannot be the only place, since Remote Control needs the Mac awake |
| <a id="d67"></a>D67 | **The shop and the teams.** AWS's retail sample, with fault flags in the style of the OpenTelemetry demo added later. Three repositories (`yaaf-platform`, `yaaf-catalog`, `yaaf-checkout`); the two agent teams run as GitHub Apps with no admin bypass (stage 7). *Decided 2026-10-23* | Real data stores on AWS with no app changes; a team boundary an agent cannot cross, because Claude's own sessions push as the owner and an identity that can bypass a rule is not stopped by it |

<details>
<summary>Standing conventions carried over from the first plan (17, unchanged): OpenTofu, GitOps, the pipeline standard and others</summary>

| | Convention | Why |
|---|---|---|
| <a id="d5"></a>D5 | OpenTofu, not Terraform | The community-governed fork; same language and providers |
| <a id="d6"></a>D6 | GitHub Actions reaches AWS only through OIDC, each role trusted on an exact `sub` and `aud`. *Amended 2026-10-08 (proposed):* two roles, `session` (the approved session environment on `main`) and `reaper` (the scheduled run on `main`); pull requests get none | No stored keys; a role can be assumed only from the workflow and branch it was made for |
| <a id="d9"></a>D9 | One script, `scripts/check`, is the fast gate for the git hook and for CI | One definition of "the checks"; the hook is a convenience, CI is the gate |
| <a id="d23"></a>D23 | GitOps: Argo CD reconciles from git; pins live in git and are bumped by a GitHub App bot PR with auto-merge; rollback is reverting the source, not the pin | Nothing pushes into the cluster; the bot recomputes pins from source |
| <a id="d24"></a>D24 | The pipeline standard: `permissions: {}`, actions pinned by SHA, no `pull_request_target` or `workflow_run`, zizmor; PRs never push images; `main` pushes by digest with SLSA provenance and an SBOM; Trivy fails on new fixable criticals; Scorecard; Dependabot with a cooldown; one always-running gate job per required workflow | Researched against GitHub, OpenSSF, SLSA and DORA guidance; each gate proved against a planted fault ([guide](docs/guides/ci-cd-pipeline-standard.md)) |
| <a id="d25"></a>D25 | One `mise.toml` and a committed `mise.lock` pin every tool; CI installs from the lockfile | A version written once cannot disagree with itself |
| <a id="d26"></a>D26 | Argo CD app-of-apps: OpenTofu installs Argo CD and one root Application; every other Application is a file in git | The cluster's contents change by pull request, never by `tofu apply` |
| <a id="d27"></a>D27 | Images are arm64 only, built on `ubuntu-24.04-arm` | Native builds; Graviton on AWS and arm runners in CI |
| <a id="d28"></a>D28 | Failure exercises are scenarios: a spec written first, an inject script, a report in `docs/postmortems/` | Spec first keeps them honest |
| <a id="d29"></a>D29 | Gateway API with Traefik; the platform owns the Gateway, teams own their routes | The split the API is designed for; identical in both environments ([guide](docs/guides/gateway-api.md)) |
| <a id="d33"></a>D33 | Demos go out through a named Cloudflare tunnel on `yaafsome.fyi`, the shop public, Argo CD and Grafana behind Cloudflare Access | Stable URLs and a login in front of the operator UIs, with no inbound exposure |
| <a id="d35"></a>D35 | The app is worked by two agent teams split by domain, each in its own repository | Least privilege by repository permission |
| <a id="d36"></a>D36 | The showcase is a static site on Vercel's free tier at the apex `yaafsome.fyi` | Always on at no cost |
| <a id="d37"></a>D37 | The project is planned in chat: questions, then one line per decision here; no ADRs | One place to read |
| <a id="d38"></a>D38 | The domain `yaafsome.fyi` on Cloudflare: the apex for the showcase, one level of subdomains for the demo; tunnel and Access set up by a written runbook | One permanent name for everything presented |
| <a id="d41"></a>D41 | Agents run the delivery loop in `CLAUDE.md`: check, draft PR, a cold review, auto-merge gated on required checks; they stop for open questions, money, real AWS, secrets, settings or data deletion | "Never merge red" is a property of the platform, not of the agent's care |
| <a id="d45"></a>D45 | Live demos are attended and time-boxed, plus a recorded walkthrough | Nothing runs, or bills, when nobody is looking |

</details>

**Merged on 2026-10-23.** The earlier proposals D47 to D62 were folded into D63 to D67; D50 (EKS Auto Mode on Graviton, Pod
Identity, Parameter Store) is now a design note in the design draft. Retired with the Floci era (readable at the archive
tag): D20, D21, D22, D30 to D32. Dated research records and the log keep the numbers of their day.

## Log

One line per merged change. Earlier history is at the tags `archive/windows-era` and `archive/floci-era`.

- 2026-10-08: the plan rewritten from scratch for real AWS on a tight budget (proposal; research in `docs/research/2026-10-08-rebuild-research.md`)
- 2026-10-13: the account is a project in the new AWS experience on the Free plan: D52 amended, D55 to D59, stage 2a; the AWS Knowledge MCP wired (`.mcp.json`)
- 2026-10-13: the account root (`infra/account/`): the state bucket, the permissions boundary and the deployer role, offline-tested; not applied
- 2026-10-22: the work environment researched (Mac versus Claude cloud versus hybrid); D59 amended, D60 to D62 proposed, a Now block added
- 2026-10-23: the decisions cut from 33 rows to 5 (D63 to D67) with the 17 working conventions folded away; settled with the owner as clickable questions; the Mac mini is Apple silicon, so no extra lockfile entry is needed
