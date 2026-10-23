# Home Platform Engineering Project

A portfolio and learning project: a fictional card-payments retailer moves its storefront to AWS, and this repository
is that engagement, designed, built, operated and broken on purpose, with every decision written down. It targets
DevOps and platform roles now and Solutions Architect roles next.

The project simulates the two pressures a real platform lives under:

1. **Developer teams** pushing pull requests all the time, much of it AI-written, which must be caught before it ships
   when it is wrong. That is the DevOps and platform side.
2. **Shop users** bringing traffic spikes, abuse and failures, and the disasters the shop must recover from. SRE
   operates it; the solutions architect decides what it must withstand and at what cost.

Everyday work and tests run on a small Kubernetes (kind) on the owner's Mac and on GitHub's free runners; real AWS is
used only in short sessions that destroy themselves, paid from the account's Free-plan credit (PLAN.md D63, D65).

**Start with [`PLAN.md`](PLAN.md)**: the architecture, the stages of work, the open questions and every decision.

## How it runs

Nothing is long-lived. The delivery system (images, pins, Argo CD, the routes) is proved on kind at no cost; AWS
behaviour is proved in short EKS sessions that only the owner starts, from their own terminal (PLAN.md D64). Agents
write the code and never hold AWS credentials. `mise run check` runs the fast checks. The Floci-era local AWS
(`mise run up`) is readable at the tag `archive/floci-era`.

## What is here

- **Infrastructure as code** (OpenTofu): the account root (a state bucket, a permissions boundary, a deployer role),
  tested offline with mock providers, and the modules the session root will use.
- **CI on GitHub Actions** to a written standard: pull requests build and scan but never push; `main` publishes arm64
  images by digest with SLSA provenance and an SBOM; a Trivy gate that fails on new criticals; zizmor, kubeconform,
  Scorecard and Dependabot ([guide](docs/guides/ci-cd-pipeline-standard.md)).
- **GitOps delivery**: Argo CD deploys from git as an app-of-apps through Gateway API routes; a bot pull request pins
  images by digest; rollback is reverting the source change, learned in a
  [deliberate failure exercise](docs/postmortems/2026-09-21-phase1-bad-emailservice.md).
- **Least-privilege identity**: a permissions boundary on everything the deployer role creates; GitHub Actions will
  federate into AWS with OIDC and narrowly trusted roles, no stored keys (D6).
- **The architecture track** (starting): requirements, views, a Well-Architected review with a findings register,
  reliability, cost, migration and security designs ([`docs/architecture/`](docs/architecture/README.md)). Each claim
  is labelled *designed*, *verified in CI* or *verified on AWS (date)*.
- **Guides** ([`docs/guides/`](docs/guides/README.md)): what each piece is, why it was done this way, and what to watch
  out for.

## How the team works (simulated)

The "app team" is Claude agents that change `app/src` through pull requests; I am the platform engineer and code owner
of everything else. Stage 3 of the plan splits the app into its own repository, worked by two agent teams, Checkout and
Catalog. One GitHub identity does every role, so required reviews cannot be enforced; `CODEOWNERS` records the intent.
Working rules: [`CLAUDE.md`](CLAUDE.md).

## Repository layout

| Path | What lives here |
|---|---|
| `PLAN.md` | The architecture, stages, open questions, decisions and log |
| `infra/` | The account root and the OpenTofu modules |
| `deploy/` | What Argo CD deploys: the Applications, the `dev` overlay with committed image pins, the routes |
| `scripts/` | `check`, the pre-commit gate, also run by CI |
| `.github/` | Workflows and their scripts, with tests |
| `app/` | Vendored Online Boutique (Google's code; see Attribution) |
| `docs/architecture/` | The architecture track |
| `docs/guides/` | Explanations for learning and interviews |
| `docs/postmortems/`, `docs/research/` | Failure write-ups; dated research behind the decisions |
| `CONTEXT.md` | This project's glossary |

Earlier history: the ADRs, handoff, milestones and journal were folded into the plan on 2026-10-08 and are readable at
commit `c4c44b0`; the Windows era and the Floci era are at the tags `archive/windows-era` and `archive/floci-era`.

## Attribution

- **`app/`** is [Google's Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo), Apache-2.0,
  vendored from upstream commit `72ba613a05f7fcee51cf1d0badff401b6ae7074d` and kept to `src/`, `protos/` and
  `kustomize/` (the Google Cloud tooling was removed). **That code is Google's.** Files the simulated app team changed
  carry a modification notice, as Apache-2.0 requires. See `app/LICENSE`.
- Everything else is original work for this project.
