# weekend-platform-gitops

Desired state for two local Kind clusters. `weekend-lab` is development and includes the existing platform stack. `weekend-production` is intentionally lightweight and contains Flux, ingress-nginx, and the three applications. GitHub Actions never receives a kubeconfig and never deploys directly to either cluster.

## Layout

- `clusters/weekend-lab`: development Flux entry point and reconciliation ordering
- `clusters/weekend-production`: production Flux entry point and reconciliation ordering
- `applications/base`: shared Namespaces, Deployments, Services, and Ingress resources
- `environments/dev/applications`: development image, replica, hostname, and Istio overlays
- `environments/production/applications`: production image, replica, and hostname overlays
- `infrastructure`: development Helm sources/releases for NGINX Ingress and monitoring
- `environments/production/infrastructure`: lightweight production ingress infrastructure
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

## Application promotion paths

Application repositories promote immutable image SHAs into the development
overlay:

```text
environments/dev/applications/<app>/deployment-patch.yaml
```

Production has independent image patches under
`environments/production/applications`. Promoting a tested development image to
production therefore changes only the production patch; shared workload
configuration remains in `applications/base`.
