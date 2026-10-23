# /infra

The OpenTofu code for the project's AWS account ([D5](../PLAN.md#d5): OpenTofu, not Terraform). Original work for this
project, not part of the vendored `/app`. Only the owner runs plan and apply here, in their own terminal; agents and CI
never hold AWS credentials ([D64](../PLAN.md#d64)).

## Layout

```
infra/
├── account/            the account root: the state bucket, the permissions boundary, the deployer role (D64, D65)
│   └── tests/          offline tests (mock providers, no AWS calls), run by scripts/check
└── modules/            kept from the Floci era for the session root (stage 2a); no root calls them yet
    ├── vpc/            VPC, public and private subnets over 2 AZs, internet gateway, one shared NAT gateway
    ├── eks-cluster/    EKS control plane, managed node group, cluster and node IAM roles
    ├── ecr/            one repository per app service, lifecycle policy, immutable tags
    ├── github-oidc/    GitHub OIDC provider and least-privilege roles (D6)
    └── argocd/         Argo CD from its Helm chart, and its Applications
```

The first apply of `account/` follows the runbook [`docs/guides/account-bootstrap-cloudshell.md`](../docs/guides/account-bootstrap-cloudshell.md).

## Checks

- `mise run check` formats the tree and runs the account root's tests offline.
- The `infra` workflow formats, runs `validate` on the account root and on each module, and scans for misconfigurations
  (Trivy, report-only). It does not plan or apply: there is no AWS for CI to use.

The Floci-era local AWS (the compose file, the three dev roots, `mise run up` and `down`, the drills and the emulator's
quirks) is readable at the tag [`archive/floci-era`](https://github.com/yaaf-some/yaaf-project/tree/archive/floci-era/infra).
