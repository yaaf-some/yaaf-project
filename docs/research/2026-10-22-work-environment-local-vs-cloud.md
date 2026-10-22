# Research: where the project should be worked on, a Mac or Claude's cloud, and how to work from anywhere

**Date:** 2026-10-22. **Why:** the owner finds the cloud session container ephemeral and partly unusable, and asked (a) whether
the work environment should be the Mac or Claude's cloud, and (b) what an ideal setup is so the project can be continued from
anywhere through Claude. Every page below was read on this date. A record: not rewritten later. Prices and limits go stale.

**How to read the confidence tags.** **[high]** = a primary page (vendor docs, source repository, spec) read today, or a
measurement made in this very session. **[medium]** = a primary page that was only partly returned by the fetch tool, or an
inference that follows directly from a [high] fact. **[low]** = general knowledge, not checked against a primary page today;
treat as a lead to verify. The documentation fetch tool summarised some long pages; where that matters it is said.

**Not known:** the Mac's chip (Apple silicon or Intel) and macOS version, and the owner's Claude plan tier. Both change
answers below; each place that depends on them says so.

## Verdict

**(a) A hybrid, with the Mac promoted to the primary workbench for anything that touches AWS or needs Kubernetes, and the cloud
kept as the secondary place for code, review and planning.** The two scarce things in this project are a kernel that can run
Kubernetes 1.35+ and a place where the owner's AWS sign-in can safely live. The cloud container has neither (it is cgroup v1,
measured today; its AWS sign-in dies with the VM). A Mac has both. But the Mac cannot be the only place: Remote Control and
Dispatch work only while the Mac is awake and running Claude Code, so "from anywhere" needs the cloud and GitHub as the fallback
and the repository as the single memory. This is D59 made concrete, with one change: the laptop is not a late "apply" box, it is
the default home for AWS and cluster work once it is declared ready.

**(b) The ideal setup is "the repository is the memory, the Mac is the hands, the phone is the remote".** Keep every fact a
session needs in git (a short "Now" section in `PLAN.md`, a one-command bootstrap, a lockfile that covers the Mac), keep
nothing that matters on any one machine (auto memory is machine-local, cloud VMs are reclaimed), run `claude remote-control` on
the Mac so the phone can drive local sessions, use cloud sessions from the phone or browser for code and PRs when the Mac is
off, and keep AWS credentials out of every agent's reach by running applies in the owner's own terminal and sandboxing the
agent. The concrete steps are in the section "The ideal setup, step by step".

## Pros and cons

| Option | Pros | Cons |
|---|---|---|
| **A. Claude cloud sessions only** | No setup; works from phone or any browser; keeps running with every device off; no extra charge for the VM (counts against plan usage); GitHub credentials never enter the VM; the repo's SessionStart hook already installs the locked tools; `.mcp.json` works in a single-repo session | Container is **cgroup v1** (measured), so k3s/kind for Kubernetes 1.35+ cannot run; VM is **x86_64**, project images are arm64 only (D27); no inbound access; outbound limited to an allowlist; `aws login` credentials and Agent Toolkit setup are lost when the VM is reclaimed; 4 vCPU / 16 GB / 30 GB; cannot run `/schedule`; AWS work forced into CloudShell (20-30 min idle limit, about 12 h cap) |
| **B. Mac only** | Real Linux VM via a container runtime, so Kubernetes 1.36 runs locally; the same machine holds AWS sign-in under the owner's control; no allowlist; long applies; the owner already used Docker Desktop on it (`docs/guides/local-aws-environment.md`); free runtimes exist | Off or asleep means no work at all, from the phone included; one machine is a single point of failure for state (Terraform bootstrap state, uncommitted work); the agent runs as the owner's OS user, so by default it can read `~/.aws` unless fenced; mise lockfile currently lacks Intel Macs; arm64-only images are native only on Apple silicon; owner must be near it to start or fix things |
| **C. Hybrid (recommended): Mac for AWS and Kubernetes, cloud and phone for code, review, planning; Remote Control to reach the Mac** | Each place does only what it is good at; cloud sessions carry no AWS credentials (matches D49 and D56); the phone can drive the Mac through Remote Control or Dispatch, or start a cloud session when the Mac is off; the repository stays the only memory, so either side can pick up; failure of one side degrades, not stops | Two environments to keep in step (hooks, lockfile, settings); Remote Control needs the Mac awake with the `claude` process running; teleport and handoff have rules (clean git state, pushed branch); the plan tier must include the features (Dispatch needs Pro or Max); more to document |
| **D. GitHub-driven only (issues, PRs, Actions, `@claude`)** | Needs no machine; free runners for a public repository; matches D51 (team agents as `claude-code-action`); everything reviewable | Cannot touch AWS (Free plan denies the GitHub OIDC provider, D55); each run is a cold start; costs API tokens or subscription usage; good for team agents, poor for platform engineering where the owner is thinking and iterating |
| **E. Codespaces / devcontainer** | Free monthly quota (Free plan: 120 compute hours at the base size; Pro 180); repeatable via a committed config; browser only | The quota is consumed faster on bigger machines; running kind needs Docker-in-Docker and a cgroup v2 kernel, not verified here; stops when idle; AWS sign-in is again ephemeral; adds a third environment for little gain |
| **F. Small always-on cloud VM** | Always reachable; ordinary Linux | A paid card-on-file item (asked first, CLAUDE.md); `aws login` lasts 12 hours and needs a human in a browser, so an always-on box cannot do unattended AWS work anyway; leaves AWS credentials on an internet-facing machine, which D49 and D56 avoid; not recommended |

## Evidence

### 1. What Claude Code offers for working across places

**Surfaces.** The same engine runs in the terminal CLI, VS Code and JetBrains, the Desktop app, the web at claude.ai/code and
the Claude mobile app; configuration, `CLAUDE.md` and MCP servers work across the local surfaces
([overview](https://code.claude.com/docs/en/overview), [platforms](https://code.claude.com/docs/en/platforms)) **[high]**.
Claude Code needs macOS 13.0 or later, 4 GB RAM, x64 or ARM64
([setup](https://code.claude.com/docs/en/setup)) **[high]**. The Desktop app is a universal build for Intel and Apple silicon
([Desktop](https://code.claude.com/docs/en/desktop)) **[medium]** (that page was returned truncated at 100,000 of 166,691
characters).

**Cloud sessions (Claude Code on the web).** Available on Pro, Max and Team, and Enterprise with premium seats; they run in an
Anthropic-managed VM, keep running when you close the laptop, count against plan usage with no separate VM charge, and can be
started from the browser, the mobile app, the Desktop app (Cloud instead of Local), `claude --cloud`, and scheduled tasks
([cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web)) **[high]**.

- *What persists.* A session's VM pauses after a few minutes idle with its files saved, and "the paused VM can later be
  reclaimed"; reopening then provisions a fresh VM. Conversation history is restored; background commands, subagents and
  session-scoped schedules are not
  ([environment expired](https://code.claude.com/docs/en/claude-code-on-the-web#environment-expired)) **[high]**. A setup
  script that finishes in about five minutes is snapshotted and reused (cache expiry about seven days); the snapshot holds files
  only, not running processes ([environments](https://code.claude.com/docs/en/cloud-environments)) **[high]**. Nothing a person
  writes to `~/.aws` survives a reclaimed VM.
- *Resources.* Ubuntu 24.04 on **x86_64**, about 4 vCPUs, 16 GB RAM, 30 GB disk; Docker (`dockerd`, `docker compose`) is
  installed; commands wait 2 minutes by default and can ask for 10; SessionStart hooks are cancelled after 600 seconds
  ([environments](https://code.claude.com/docs/en/cloud-environments)) **[high]**.
- *Measured in this session today:* `stat -fc %T /sys/fs/cgroup/` printed `tmpfs` (cgroup v1), `uname -m` printed `x86_64`,
  4 CPUs, 15 GB RAM, `CLAUDE_CODE_REMOTE=true` **[high]**. Kubernetes documents `tmpfs` as cgroup v1 and says: "Kubelet will
  no longer start on a cgroup v1 node by default" since v1.35, with `failCgroupV1: false` as the documented opt-out
  ([cgroups](https://kubernetes.io/docs/concepts/architecture/cgroups/)) **[high]**. So the owner's finding is confirmed. The
  opt-out exists but running a cluster of an unsupported cgroup mode on an x86 VM that cannot run arm64 images is not worth
  trying; not tested.
- *Network.* Four levels: None, Trusted (default allowlist of package registries, GitHub, cloud SDKs), Full, Custom. GitHub
  goes through a separate proxy that keeps real credentials outside the VM; MCP connectors travel through Anthropic's servers;
  the Anthropic API stays reachable even at None. No inbound access is described
  ([environments](https://code.claude.com/docs/en/cloud-environments)) **[high]** (the "no inbound" part is the owner's
  experience plus the absence of any inbound feature in these pages **[medium]**).
- *Secrets.* Environment variables and the setup script are readable by anyone who uses the environment. "Network secrets" are
  keys the agent proxy attaches to requests for hosts you list, so the key never enters the VM. They suit bearer-style API
  keys; AWS request signing (SigV4) needs the key material in the process, so this does not carry AWS credentials
  ([environments](https://code.claude.com/docs/en/cloud-environments)) **[high]** for the first two facts, **[medium]** for the
  AWS inference.
- *Hooks and settings.* SessionStart hooks in the repo's `.claude/settings.json` run in cloud sessions, on every start and
  resume, and also locally, so a hook must exit early unless `CLAUDE_CODE_REMOTE=true` (this repo's hook does). User-level
  `~/.claude/settings.json` hooks are not in the cloud. A session with several repositories loads no repository hooks
  ([environments](https://code.claude.com/docs/en/cloud-environments)) **[high]**. In **Projects** (public beta on Pro and Max),
  cloud threads load `CLAUDE.md` but not `.mcp.json`, `.claude/settings.json`, hooks, skills or permission rules
  ([Projects](https://code.claude.com/docs/en/claude-projects)) **[high]**; the repo's hook and its `.mcp.json` would therefore
  not apply in a Project thread.
- *Memory.* "Auto memory is machine-local ... Files are not shared across machines or cloud environments"
  ([memory](https://code.claude.com/docs/en/memory)) **[high]** (found by search of the page, which was returned in part).
  `CLAUDE.md` and `AGENTS.md` are the only memory that travels, because they are in git.

**Remote Control.** Connects claude.ai/code or the iOS/Android app to a session that runs **on your own machine**; "your
computer has to stay on and the `claude` process has to keep running". Needs Pro, Max, Team or Enterprise (not API keys, not
Bedrock/Vertex/Foundry, not `ANTHROPIC_BASE_URL` pointed elsewhere). Start with `claude remote-control` (server mode, up to 32
sessions, `--spawn worktree`), `claude --remote-control`, or `/remote-control` inside a session or the Desktop app. Only
outbound HTTPS on port 443, no inbound ports. A sleeping laptop reconnects when it wakes; a server-mode outage over about 10
minutes ends the process. If you stop the process or close the app, the session goes offline until resumed (`--continue`). To
sandbox the sessions it starts, "turn on sandboxing in a settings file"
([Remote Control](https://code.claude.com/docs/en/remote-control)) **[high]**. Nothing on the page says whether a closed lid
keeps the session alive; macOS-level sleep settings are the owner's side **[low]** (not researched).

**Moving a session between places.** From the web or phone to a terminal: `claude --teleport` (or `/teleport`, `/tasks`, or
**Open in > Terminal**); needs a clean git state, the same repository (not a fork), the branch pushed, the same claude.ai
account, and claude.ai login (not an API key). The terminal gets its own copy; later work there does not appear in the cloud
session. From the terminal to the cloud there is **no session transfer**: `claude --cloud "task"` starts a new cloud session
from the pushed branch (or an uploaded bundle if the GitHub App is not installed), and the Desktop app can send a local session
to the cloud from its **Open in** menu. Follow-ups can be queued into a running cloud session from any machine:
`claude -p "msg" --cloud <session-id>`
([cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web#move-tasks-between-terminal-and-cloud)) **[high]**.

**Desktop app, Dispatch, SSH.** The Code tab offers Local, Cloud and SSH environments. Dispatch (message a task from the phone,
it becomes a Desktop session) "requires a Pro or Max plan and is not available on Team or Enterprise". Local sessions need the
machine running; cloud sessions do not ([Desktop](https://code.claude.com/docs/en/desktop)) **[medium]** (truncated page).

**Scheduled tasks (formerly routines).** Cloud tasks run on Anthropic infrastructure when the laptop is closed; triggers are
schedule (minimum interval one hour), an API endpoint with a bearer token, and GitHub events (pull request, release). They run
autonomously with no permission prompts, push `claude/`-prefixed branches as **your** GitHub identity, and are a research
preview. Desktop scheduled tasks run on your machine instead
([scheduled tasks](https://code.claude.com/docs/en/routines)) **[high]**. This matters for D51: a routine pushes as the owner,
which the plan already avoids for the team agents.

**GitHub App and Action.** The Claude GitHub App enables auto-fix of PR CI failures and review comments from a cloud session
(per-PR toggle, started from the web, `/autofix-pr`, or the phone; reacts to events, cannot see merge conflicts). The
`claude-code-action` workflow answers `@claude` in issue and PR comments; it needs the App plus a repository secret
(`ANTHROPIC_API_KEY`, or `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token` on Pro, Max, Team, Enterprise), costs runner
minutes plus tokens or subscription usage, only runs for users with write access, and commits pushed with the default
`GITHUB_TOKEN` do not trigger CI
([GitHub Actions](https://code.claude.com/docs/en/github-actions)) **[high]**. Public repositories use standard GitHub-hosted
runners for free; the billing page does not name arm64 runners for public repositories
([Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)) **[high]** for the quote,
so the plan's "free `ubuntu-24.04-arm` runner" is still **unconfirmed** by this page.

**MCP and `.mcp.json`.** A committed `.mcp.json` is read in single-repository cloud sessions and scheduled tasks, and in local
sessions; not in Project threads ([scheduled tasks](https://code.claude.com/docs/en/routines),
[Projects](https://code.claude.com/docs/en/claude-projects)) **[high]**.

**Plan limits to confirm with the owner.** Cloud sessions, Remote Control and scheduled tasks: Pro and above. Dispatch: Pro or
Max only. Projects: Pro and Max, rolling out. Which plan the owner has is not in the repository.

### 2. A Mac as the work machine for this stack

**Why a container runtime VM is needed.** kind's own docs: "Docker containers cannot be executed natively on macOS and
Windows, therefore Docker Desktop runs them in a Linux VM"; kind needs about 6 GB RAM for the VM (8 GB recommended), and its
node images ship for AMD64 and ARM64 ([quick start](https://kind.sigs.k8s.io/docs/user/quick-start/),
[known issues](https://kind.sigs.k8s.io/docs/user/known-issues/)) **[high]**. kind v0.33.0 pre-builds node images for
Kubernetes 1.36.4 and 1.35.8, and v0.32.0 defaults to 1.36.1
([kind releases](https://github.com/kubernetes-sigs/kind/releases)) **[medium]** (the page showed dates without years). So
`k8s_version = "1.36"` in `mise.toml` is reachable with kind on a Mac, **provided the runtime's VM kernel is cgroup v2**
(Kubernetes needs Linux 5.8+ and a cgroup v2 distribution,
[cgroups](https://kubernetes.io/docs/concepts/architecture/cgroups/) **[high]**). Which cgroup version each Mac runtime's VM
uses was **not** found on a primary page. Check on the Mac with `docker info` (it prints the Cgroup Version) or inside the
node with `stat -fc %T /sys/fs/cgroup/` (`cgroup2fs` is v2) **[low]** for the first command, **[high]** for the second.

**Runtimes.**

| Runtime | Mac support read today | Cost and licence read today | Kubernetes |
|---|---|---|---|
| Docker Desktop | Apple silicon and Intel, "current and two previous major macOS releases", 4 GB RAM ([install](https://docs.docker.com/desktop/setup/install/mac-install/)) **[high]** | Free for personal use, education, non-commercial open source, and small businesses (fewer than 250 employees and under $10 million revenue); paid tiers $9 to $24 per user a month ([licence](https://docs.docker.com/subscription/desktop-license/), [pricing](https://www.docker.com/pricing/)) **[high]** | Use kind or k3d on top |
| OrbStack | Install and system requirements not on the pages reached | "Always free for personal use", Pro $8 per user a month for business and commercial use; "personal use" is not defined, so whether a job-search portfolio counts is unclear ([pricing](https://orbstack.dev/pricing)) **[high]** | Built-in single-node cluster, no choice of version documented; multi-node via kind or k3d ([docs](https://docs.orbstack.dev/kubernetes/)) **[high]** |
| Colima | Intel and Apple silicon ([README](https://github.com/abiosoft/colima)) **[high]** | MIT licence, free | `--kubernetes` flag; default VM is 2 CPU / 2 GiB, too small for kind, so raise it **[high]** |
| Rancher Desktop | macOS 13+, Apple silicon or Intel with VT-x, recommended 8 GB and 4 CPUs ([install](https://docs.rancherdesktop.io/getting-started/installation/)) **[high]** | Licence not stated on the page | K3s, versions not listed on the page |
| Podman | `podman machine` VM on Mac; chip support not on the page ([install](https://podman.io/docs/installation)) **[medium]** | not stated | kind needs extra rootless setup ([quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)) **[high]** |
| k3d | Wrapper that runs k3s in Docker; needs Docker ([k3d](https://k3d.io/stable/)) **[high]** | free | n/a |

Recommendation for this project: **Docker Desktop with kind**, because the owner already ran Docker Desktop on this Mac
(`docs/guides/local-aws-environment.md`), it is free for a single individual under the quoted terms, and kind is also what the
plan's CI environment uses (so local equals CI). Colima is the free fallback. Not benchmarked here.

**Chip matters.** The project's images are arm64 only (D27). On Apple silicon they run natively; on an Intel Mac they would
need emulation, which was not tested and is unlikely to be pleasant **[low]**. kind itself ships both architectures, so the
cluster is fine; the application images are the issue. Whether an Intel Mac can run macOS 13 or later (Claude Code, Rancher
Desktop) was not checked against Apple's list.

**mise on macOS, and the lockfile.** `mise.lock` records URLs and checksums per platform, and `mise install --locked` fails
rather than resolve when the lockfile has no matching entry for a backend that records URLs; the docs recommend locking
"every platform that runs the tools" ([mise lock](https://mise.jdx.dev/dev-tools/mise-lock.html)) **[high]**. The repo's
`mise.lock` has `linux-arm64`, `linux-x64` and `macos-arm64` for all nine tools and **no `macos-x64`** (counted in the file
today). So `mise install --locked` should work on Apple silicon and fail on an Intel Mac until the lock is extended with
`mise lock --platform linux-arm64,linux-x64,macos-arm64,macos-x64` **[medium]** (the docs say fail; not run on a Mac). OpenTofu,
kubectl and awscli come through mise's aqua backend, so no separate Homebrew step is needed in principle; the AWS CLI must be
2.32.0 or later for `aws login`; the lock pins 2.37.9 **[high]**.

**The repo is not yet Mac-ready in these ways** (read from the files):

- `.claude/hooks/session-start.sh` exits at once unless `CLAUDE_CODE_REMOTE=true`, so on a Mac nothing installs mise or sets
  `core.hooksPath`; there is no one-command bootstrap for a person.
- `mise.toml` still sets `AWS_CONFIG_FILE`, `AWS_SHARED_CREDENTIALS_FILE` and `KUBECONFIG` to project-local `.aws/` and
  `.kube/` ("the emulator is the only AWS here"). That is Floci-era; with D55 to D59 a real `aws login` in a mise-activated
  shell would write its config into the repo's gitignored `.aws/` while the login token cache would still go to
  `~/.aws/login/cache` unless `AWS_LOGIN_CACHE_DIRECTORY` is set. Needs a decision, not an accident.
- The session hook's header cites `PLAN.md D30`, which is retired.
- The scripts are bash; whether they run under macOS's default tools (an old system bash, BSD `sed` and `date`) was **not
  tested** **[low]**. The first run on the Mac should be `mise run check`, treated like any new check: expect to fix.
- `kind` is not in `mise.toml`, so the Mac and CI could drift.

### 3. AWS credentials on a Mac

- **`aws login`** (AWS CLI 2.32.0 or later): browser sign-in with console credentials (root, IAM user, or IAM federation); the
  CLI refreshes credentials about every 15 minutes and the session lasts up to the principal's duration, "maximum of 12 hours",
  then `aws login` again; `aws logout` deletes the cache. The IAM identity needs the managed policy
  `SignInLocalDevelopmentAccess` (root needs none)
  ([AWS CLI sign-in](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html)) **[high]**.
- **Where tokens live:** "stored by default in `~/.aws/login/cache` on Linux and macOS" as files; the location can be moved
  with `AWS_LOGIN_CACHE_DIRECTORY`; the page documents no macOS Keychain integration, so on a Mac the protection is file
  permissions and the disk encryption the owner turns on **[high]** for the path, **[medium]** for "no keychain" (absence in the
  page read). The config file gets `login_session = <ARN>` and the region.
- **`aws login --remote`:** for a device without a browser, prints a URL, the person signs in on any browser-equipped device
  and pastes an authorization code back. Same-device and cross-device flows have separate resource ARNs
  (`.../oauth2/public-client/localhost` and `.../remote`) that an IAM policy can allow or deny
  ([AWS CLI sign-in](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html)) **[high]**.
- **The new AWS experience (the owner's project):** "Connect an AI coding tool" creates per-project credentials used by the AWS
  CLI and SDKs ("External tools may not be supported"), valid 12 hours, renewed with `aws login --profile <name>`, and "AWS
  can renew your credentials for 90 days. After 90 days, you'll need to grant access in a browser window again." The page carries a limited-release
  warning and covers projects "you own or ... shared with you"
  ([connect an AI coding tool](https://docs.aws.amazon.com/accounts/latest/reference/connect-ai-coding-tool.html)) **[high]**.
  The 12 hours and 90 days therefore come from this page, not the general CLI page.
- **IAM Identity Center / `aws sso login`:** needs an Identity Center instance; tokens cached under `~/.aws/sso/cache`; the
  owner's project cannot create an instance until advanced features are activated
  ([SSO](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html),
  [research 2026-10-13](2026-10-13-aws-new-experience.md)) **[high]**.
- **`credential_process`:** AWS says this method is "only as secure as the external location" and calls it not recommended;
  its example is a script that prints credentials JSON, and the CLI does not cache its output
  ([authentication](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html),
  [credential_process](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-sourcing-external.html)) **[high]**. It
  could read a Keychain item, but that item would hold long-term keys, which this project does not have; so it does not apply.
  A dedicated AWS page on protecting local credentials was not found.
- **The consequence for agents.** Whatever the owner's `aws login` caches is readable by any process running as the same Mac
  user, an agent included. Claude Code's defaults agree: the Bash sandbox allows reads of "most of the machine, including
  credential files such as `~/.ssh` and `~/.aws/credentials`" until `filesystem.denyRead` or `sandbox.credentials` entries
  (with `"mode": "deny"`) say otherwise; the sandbox uses Seatbelt on macOS; it covers shell commands only, while the Read, Edit
  and Write tools follow permission rules; `Read` deny rules do not stop "arbitrary subprocesses that read ... files
  indirectly, like a Python or Node script"
  ([sandboxing](https://code.claude.com/docs/en/sandboxing), [permissions](https://code.claude.com/docs/en/permissions))
  **[high]**. The sandbox cache path `~/.aws/login/cache` is not named in those pages; denying `~/.aws/` as a directory is the
  safe reading **[medium]**. Remote Control sessions honour sandbox settings from settings files
  ([Remote Control](https://code.claude.com/docs/en/remote-control)) **[high]**.

### 4. Other places to work from anywhere

- **AWS CloudShell.** Free, already signed in; 1 GB persistent storage per Region, deleted after 120 days without a session;
  shell ends after 20-30 minutes without keyboard or pointer input (running processes do not count) and after about 12 hours
  of continuous running; 10 concurrent shells per Region; outbound internet yes, inbound none
  ([limits](https://docs.aws.amazon.com/cloudshell/latest/userguide/limits.html)) **[high]**. Fine for the first bootstrap
  apply (already the plan); poor for a long EKS session. Docker availability was not checked.
- **GitHub Codespaces / devcontainer.** A cloud dev environment in a Docker container on a VM, 2 to 32 cores; personal accounts
  get a monthly free quota (Free: 15 GB-month storage and 120 hours of compute; Pro: 20 GB-month and 180 hours), with compute
  proportional to cores ([overview](https://docs.github.com/en/codespaces/overview),
  [billing](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces)) **[high]**. The Docker-in-Docker
  devcontainer feature exists and needs a Docker host of the same chip architecture
  ([feature](https://github.com/devcontainers/features/tree/main/src/docker-in-docker)) **[high]**. Whether a Codespace kernel
  is cgroup v2 and runs kind 1.36 was **not verified**; the kernel is not named on the overview page. Default idle behaviour,
  spending-limit default and kernel: not on the pages read.
- **Always-on VM.** Hetzner Cloud lists plans "starting from" EUR 5.99 a month (Cost-Optimized) and EUR 6.49 (Regular
  Performance), excluding VAT, in Germany, Finland, Singapore and the USA; the page does not say which are arm64
  ([Hetzner Cloud](https://www.hetzner.com/cloud/), read 2026-10-22) **[medium]**. Needs a card; not recommended (see option F).
- **Purely GitHub-driven.** Issues, PRs and Actions need no machine, are free on public repositories for standard runners, and
  can host the `@claude` action with a repository secret, but they cannot reach AWS on the Free plan (no OIDC provider, D55)
  **[high]** (Actions billing page, research 2026-10-13).

### 5. Making the project resumable from anywhere

**What already helps (read in the repo):** `PLAN.md` holds decisions, stages and a log; `CLAUDE.md` holds the working rules and
the delivery loop; `mise.toml` plus `mise.lock` pin nine tools; the SessionStart hook installs them in cloud sessions
(`mise install --locked`); `.mcp.json` wires the AWS Knowledge MCP (no credentials); `scripts/check` is the single gate for
hook and CI; the CloudShell runbook has a "keep nothing there that is not in git or the state bucket" rule **[high]** (repo
files).

**What is missing, from the files:**

1. **A current-state pointer.** The log is one line per merged change; nothing says "right now: branch X, PR Y, next step Z,
   nothing running in AWS". A new session on any machine must infer it from `git log`. Cheapest fix: a short **Now** block at
   the top of `PLAN.md` (no new file, in line with "one living document").
2. **A one-command bootstrap for a person.** The hook does the job only in the cloud. Extract it into `scripts/bootstrap`
   (install mise, trust, `mise install --locked`, set `core.hooksPath`) that the hook calls and the owner runs on the Mac.
3. **A lockfile that covers the Mac** (`macos-x64` if Intel; and `kind` in `mise.toml` so the Mac matches CI).
4. **A decision on `mise.toml`'s project-local AWS paths** (keep with a comment that the real profile is selected explicitly,
   or remove them).
5. **Agent fencing for the Mac**: `sandbox` and `Read(~/.aws/**)` deny entries in the checked-in `.claude/settings.json` so the
   protection travels with the repo, plus the rule that applies run in the owner's own terminal.
6. **State that must not live on one machine.** The bootstrap root's own state is a local file until it is migrated into the
   bucket it creates (runbook, "After the apply"). If the first apply happens on the Mac, that file lives only there until the
   migration; treat the migration as part of the same sitting.
7. **Secrets handling is already right in principle** (no AWS secrets in the cloud environment; GitHub credentials stay on
   Anthropic's side). Add: the `CLAUDE_CODE_OAUTH_TOKEN` or API key for the Action goes only into a GitHub repository secret,
   made on the Mac with `claude setup-token`, when stage 7 arrives.
8. **Auto memory does not travel**, so `CLAUDE.md` and `PLAN.md` must carry every preference and fact; the "Real AWS" section
   of `CLAUDE.md` is marked superseded but still contradicts D55 and D59 until stage 0 rewrites it.

## The ideal setup, step by step

Effort is the owner's or an agent's time; money is extra spend. "Agent alone" means a cloud session can do it through a PR
with no credentials; "Owner" means the owner must be at the machine or account.

**One-time, before the Mac becomes primary ("declare the laptop ready" checklist)**

| # | Step | Who | Money | Effort |
|---|---|---|---|---|
| 1 | Tell the agent the Mac's chip and macOS (`uname -m`, `sw_vers`). Intel: also check macOS 13 or later is possible. | Owner | $0 | 1 min |
| 2 | Extend `mise.lock` to the Mac's platform (`mise lock --platform ...`); add `kind` to `mise.toml`; add `scripts/bootstrap`; make the hook call it; decide the `mise.toml` AWS paths. One PR through the delivery loop. | Agent alone | $0 | 1 session |
| 3 | Add a **Now** block to the top of `PLAN.md` and a rule in `CLAUDE.md` to update it at the end of every session. | Agent alone | $0 | small |
| 4 | Install Claude Code (or the Desktop app) on the Mac and sign in with the same claude.ai account; install a container runtime (Docker Desktop recommended). | Owner | $0 (free tiers as quoted) | 30 min |
| 5 | Clone, run `scripts/bootstrap`, then `mise run check`. Fix what breaks (bash and BSD tools untested). Prove the Kubernetes path: `kind create cluster --image kindest/node:v1.36.4` with the digest from the kind release notes, and confirm `stat -fc %T /sys/fs/cgroup/` inside the node prints `cgroup2fs`. | Owner runs, agent fixes via PR | $0 | 1 to 2 h |
| 6 | Fence the agent: add `sandbox.credentials` deny for `~/.aws/` and `AWS_*` env vars and `Read` deny rules to the checked-in settings; confirm with a probe command inside a Claude session that reading `~/.aws` fails. | Agent writes, owner confirms the probe | $0 | 30 min |
| 7 | Install the Claude app on the phone, sign in, open the Code tab (`/mobile` shows a QR code). Turn on push notifications in `/config`. | Owner | $0 | 10 min |
| 8 | Start Remote Control on the Mac: `claude remote-control --spawn worktree` in the project folder (or turn on the Desktop setting "Use this computer from your phone and claude.ai"). Keep the Mac awake and plugged in while it is wanted (macOS sleep settings are the owner's; not researched). | Owner | $0 | 10 min |
| 9 | Install the Claude GitHub App on the repository (auto-fix of PRs from the phone). | Owner | $0 | 5 min |

**Per session**

| # | Step | Who | Money | Effort |
|---|---|---|---|---|
| 10 | Pick the place: Mac session (via Remote Control from the phone, or at the keyboard) for AWS or cluster work; a cloud session (claude.ai/code or the app) for code, PRs, docs and review. Start by reading the **Now** block and `git pull`. | Owner chooses; agent follows | $0 | seconds |
| 11 | AWS only: the owner runs `aws login --profile <project>` (browser on the Mac, or `--remote` and paste the code from another device), runs plan and apply in their **own terminal outside Claude**, then `aws logout`. No agent session runs while that sign-in is live unless step 6 is confirmed. | Owner | AWS credits as in the plan | per apply |
| 12 | End of session: the agent opens or updates the PR, ticks the checklist, updates **Now** (branch, open PRs, "nothing running in AWS"), and for a Mac session pushes the branch so a cloud session or teleport can continue it. | Agent | $0 | 2 min |

**Recurring**

| # | Step | Who | Money | Effort |
|---|---|---|---|---|
| 13 | Every 12 hours of AWS work: `aws login` again. Every 90 days: AWS asks for a fresh browser grant. | Owner | $0 | 1 min |
| 14 | Cloud environment cache rebuilds on its own about weekly; no action. If the setup script changes, existing paused sessions keep the old cache until reclaimed. | Automatic | $0 | none |

**Later (stage 7, not now):** `/install-github-app` or a hand-written workflow for the team agents, `claude setup-token` run on
the Mac, the token stored only as a repository secret, with the permissions and rulesets D51 already describes.

**Do not do:** put AWS keys in a cloud environment variable or network secret; run a cloud session with `aws login --remote`
as the routine path (it works, but the credentials die with the VM and the agent holds them); use `/schedule` routines for
anything that pushes to protected paths (they push as the owner); buy an always-on VM.

## What this changes in PLAN.md (not edited here)

- **D59 (amend).** From "hybrid ... applies from the laptop once the owner declares it ready" to: the laptop is the primary
  workbench for AWS and Kubernetes work once the checklist in steps 1 to 9 is ticked; cloud sessions stay the default for code,
  review and planning, and the fallback when the Mac is off. Define "declared ready" by that checklist.
- **D56 (amend).** Applies run owner-at-keyboard from the Mac in the owner's own terminal, with CloudShell as the fallback;
  define "at the keyboard" (is authorising `aws login --remote` from the phone acceptable? it is the owner's decision); say
  that a Mac `aws login` session is never open while an unfenced agent session is running.
- **D49 (clarify).** "Agents never hold AWS credentials" is guaranteed by construction in the cloud, and by sandbox plus
  owner-run applies on the Mac. Record that it is a rule enforced by settings there, not by distance.
- **New decision, work environments (D60).** Which kinds of work happen where (the table above), and that the Mac is not a
  single point of failure because the repository is the memory.
- **New decision, resumability (D61).** The **Now** block, `scripts/bootstrap`, and the lockfile covering the Mac's platform.
- **New decision or amendment to D25 (D62).** `mise.lock` covers every platform that runs the tools (add `macos-x64` if Intel);
  `kind` is pinned; the project-local AWS paths in `mise.toml` are resolved.
- **D27 (only if the Mac is Intel).** Arm64-only images become a problem locally; either accept slow emulation or build
  multi-arch.
- **Stage 2a checklist.** Reword "from CloudShell" to "from the Mac, CloudShell as fallback"; add the sandbox probe and the
  "Mac ready" checklist as items; keep the state-migration item and tie it to the same sitting as the first apply.
- **CLAUDE.md.** The stage 0 rewrite should drop the superseded "Real AWS" section and say plainly where each kind of work
  runs; the hook header should stop citing retired D30.
- **Open question to add:** which Claude plan the owner is on (Dispatch, Projects, Remote Control depend on it).

## Open and unconfirmed

- The Mac's chip and macOS version, and the owner's Claude plan tier. Remote Control, cloud sessions and scheduled tasks need
  Pro or above; Dispatch needs Pro or Max; Projects is Pro and Max, rolling out.
- Whether each Mac runtime's VM kernel is cgroup v2 (and so runs Kubernetes 1.36): no primary page found; verify with the two
  commands in section 2 before relying on it.
- OrbStack's macOS and chip requirements and its definition of "personal use" for a job-search portfolio; Rancher Desktop's
  licence; Podman's chip support. Docker Desktop's free tier fits an individual under the quoted terms.
- Whether `mise install --locked` fails on an Intel Mac exactly as the docs imply, and whether the repo's bash scripts pass
  under macOS tools: neither was run on a Mac.
- Whether Remote Control keeps a session alive with the lid closed on battery; the docs say only that it reconnects after the
  machine wakes.
- Whether `aws login` credentials can be kept out of the agent's reach by `~/.aws/` deny rules alone (the cache path is not
  named in the sandbox pages); the probe in step 6 is the test.
- Whether the Agent Toolkit setup works as written on a Mac; `setup.md` was not re-read today.
- Whether Codespaces' kernel runs kind 1.36 (cgroup v2); whether GitHub's arm64 runners are free for a public repository (the
  billing page is silent, the plan assumes yes); Hetzner's arm64 plans.
- Whether the `failCgroupV1: false` opt-out could make a cloud session run k3s: documented, not tried, and the VM is x86_64
  while the images are arm64.
- AWS's new experience is "released to a limited number of customers" and may change; the 12-hour and 90-day figures are from
  that page as read today.
