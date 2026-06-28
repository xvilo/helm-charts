# AirTrail

Helm chart for [AirTrail](https://github.com/johanohly/AirTrail) — a modern,
open-source personal flight tracking system.

| Resource | What it is |
|---|---|
| `Deployment` + `Service` | AirTrail app (`johly/airtrail`), port 3000 |
| `PersistentVolumeClaim` | Uploads volume mounted at `/app/uploads` |
| `Ingress` | routes the host to the app |

No database is bundled — bring your own PostgreSQL (managed service, operator, or
a separate chart) and point this chart at it via values or an existing Secret.

## Install

```bash
helm install airtrail ./charts/airtrail \
  --namespace airtrail --create-namespace \
  --set origin=https://airtrail.example.com \
  --set ingress.host=airtrail.example.com
```

> `origin` **must** match the public URL the app is served from (scheme + host).
> AirTrail rejects login/registration form submissions from other origins. Pass a
> comma-separated list to allow multiple origins.

The first account you register becomes the admin.

## Database

No database is bundled. AirTrail consumes a single `DB_URL`, which the chart
assembles at runtime from the `database.*` components via Kubernetes `$(VAR)` env
interpolation. Each component is **either** a plain string **or** a
Kubernetes-native object rendered verbatim as the env var's source — so any part
(typically the password) can come straight from a Secret you manage.

Inline strings (simplest):

```yaml
database:
  host: db.example.com
  port: 5432
  name: airtrail
  username: airtrail
  password: secret                 # use A-Za-z0-9 only to avoid URL-parsing issues
```

Pull the password (or any field) from an existing Secret:

```yaml
database:
  host: db.example.com
  name: airtrail
  username: airtrail
  password:
    valueFrom:
      secretKeyRef:
        name: airtrail-db          # a Secret you manage
        key: password
```

The chart never templates a Secret of its own, so inline string values land in the
Deployment's env as-is — use the `valueFrom` object form for anything sensitive.

A `wait-for-db` init container (`waitForDb.enabled`, default true) blocks rollout
until the database is reachable; set `waitForDb.enabled=false` to skip it.

## Uploads

Persistent storage for uploads (airline icons, etc.) is enabled by default and
mounted at `UPLOAD_LOCATION=/app/uploads`. Disable with `persistence.enabled=false`
(uploads are then turned off), or point at a pre-created claim with
`persistence.existingClaim`.

## TLS

With [cert-manager](https://cert-manager.io) + nginx-ingress:

```bash
--set ingress.tls.enabled=true \
--set ingress.tls.secretName=airtrail-tls \
--set 'ingress.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod'
```

## Render without installing

```bash
helm template airtrail ./charts/airtrail \
  --set origin=https://airtrail.example.com \
  --set ingress.host=airtrail.example.com
```
