# Home Platform Engineering Project

Platform, infrastructure, delivery and architecture work built around a vendored target application (`/app`, Google's
Online Boutique; see `README.md` for scope and attribution). This file defines terminology specific to the platform
work; it does not describe `/app` itself, which is upstream code.

## Language

Terms are added as they are resolved (via `/domain-modeling`), not written speculatively.

**The project**

- **Engagement**: the fictional card-payments retailer's move to AWS, which frames the architecture track from
  discovery to the second review (D21).
- **Evidence label**: every claim is **designed**, **verified in CI** or **verified on AWS (date)**. Older claims say
  **verified on Floci**, the retired emulator (D63).
- **Guide**: a `docs/guides/` page that teaches one concept: the idea, how it works here, why this way, what to watch
  out for, and self-check questions. `PLAN.md` records decisions; guides teach.
- **App team**: the Claude agents that change `app/src` and open PRs. A simulated team; two teams by domain from stage 3,
  **Checkout** and **Catalog** (D35).
- **Client 1, client 2**: the two pressures the project simulates: developer teams pushing change, and shop users
  bringing traffic, abuse and failure (`PLAN.md`).
- **Platform engineer**: the owner of infrastructure, pipelines, delivery and environments; the code owner for
  everything outside `app/src`.

**The environment**

- **AWS**: the project's own account on the Free plan, in `us-east-1`; its credit is the spending cap (D65). Only the
  owner changes it, from their own terminal; agents have documentation only (D64).
- **CI environment**: kind on a GitHub arm64 runner or on the Mac, with Argo CD and the app from git; proves the delivery
  system on every change, at no cost (D63).
- **AWS session**: a short EKS environment the owner creates for a purpose and that destroys itself afterwards (D63).
- **Live demo**: an ephemeral environment held open and published through the named Cloudflare tunnel on `yaafsome.fyi` (D33).
- **Tunnel**: an outbound connection from the runner to Cloudflare that carries visitors' requests in, so nothing listens
  on the internet. **Access**: Cloudflare's login in front of a hostname, used for the operator UIs (D33, D38).
- **Root**: one OpenTofu working directory with its own state. The **account root** (`infra/account/`) holds the
  state bucket, the permissions boundary and the deployer role; not applied yet.
- **Scenario**: a failure exercise kept as a folder, `docs/scenarios/<name>/`: a spec written before it is run, a script that
  injects the fault, and a dated report in `docs/postmortems/` for each run (D28).

**Build and delivery**

- **Content tag**: an image tag `content-<hash>-arm64`, the git tree hash of a service's build context plus the architecture (D27), so unchanged
  services keep their tag (D23).
- **Image pin**: the committed content tag for a service in `deploy/dev`; what Argo CD deploys. Pins are derived from
  the source, so rollback is reverting the source change: a pin-only revert is undone by the next bump.
- **Argo CD**: runs in the cluster and reconciles workloads from git every 60 seconds; nothing pushes into the
  cluster (D23).
- **App-of-apps**: one root Argo CD Application that points at `deploy/apps/`, where each other Application is a file,
  so platform changes arrive by pull request (D26).
- **Gateway API**: the Kubernetes routing API that replaces `Ingress` here: the platform owns a **Gateway**, each team owns
  **HTTPRoutes** attached to it (D29, `docs/guides/gateway-api.md` once written).
- **Digest pin**: an image pin written as `tag@sha256:...`, readable and immutable; what the bot writes (D24).
- **Attestation**: a Sigstore-signed statement stored on GitHub about an image digest: its SLSA build provenance and its
  SBOM. Checked with `gh attestation verify` (D24).
- **Scan ratchet**: the build fails on a fixable CRITICAL vulnerability unless it is an accepted, unexpired entry in
  `.trivyignore.yaml`, so new findings fail and known ones are tracked (D24).
- **Gate job**: an always-running job (`build`, `infra`, `check`) that is the single required check for its pipeline,
  so PRs that touch nothing relevant still report it.
