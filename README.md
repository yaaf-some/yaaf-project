# yaaf-project

A shop (Google's Online Boutique, vendored in `app/`) delivered to Kubernetes by GitOps, through a tested pipeline.
Built to learn how a small platform is run: Argo CD deploys the manifests in `deploy/`, `.github/` builds, scans and
pins the images, and `mise run check` is the gate for every change.

The project is being reset. A proper "start here" lands once the plan is written; until then, the working rules are in
[`CLAUDE.md`](CLAUDE.md) and the work is in the GitHub Issues. Earlier eras are readable at the tags `archive/*`.

`app/` is Google's code (Apache-2.0, see `app/LICENSE`); everything else is original to this project.
