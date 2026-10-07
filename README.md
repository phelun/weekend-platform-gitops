# weekend-platform-gitops

Desired state for two local Kind clusters. `weekend-lab` is development and includes the existing platform stack. `weekend-production` is intentionally lightweight and contains Flux, ingress-nginx, and the three applications. GitHub Actions never receives a kubeconfig and never deploys directly to either cluster.

## Layout

- `clusters/weekend-lab`: Flux entry point and reconciliation ordering
- `clusters/weekend-production`: production Flux entry point and reconciliation ordering
- `infrastructure`: Helm sources/releases for NGINX Ingress, monitoring, and Istio
- `applications`: Kustomize resources for App01, App02, and App03
- `environments/production`: lightweight production infrastructure and applications
- `kind`: reproducible Kind cluster definitions
- `scripts`: local validation and tunnel helpers

## Before the first bootstrap

The application images are pinned to the full commit SHAs of their initial app-repository commits. Push each app repository and wait for all three GHCR workflows to succeed before bootstrapping Flux.

Validate locally:

```sh
./scripts/validate.sh
```

Bootstrap is intentionally deferred until the repositories and GHCR images exist:

```sh
flux bootstrap github \
  --owner=phelun \
  --repository=weekend-platform-gitops \
  --branch=main \
  --path=clusters/weekend-lab \
  --personal
```

The existing App03 plaintext secret is deliberately excluded. Add it in the hardening phase as a SOPS/Age-encrypted Secret.
