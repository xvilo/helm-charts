# AirTrail

Helm chart for [AirTrail](https://github.com/johanohly/AirTrail) — a modern,
open-source personal flight tracking system.

| Resource | What it is |
|---|---|
| `Deployment` + `Service` | AirTrail app (`johly/airtrail`), port 3000 |
| `PersistentVolumeClaim` | Uploads volume mounted at `/app/uploads` |
| `Secret` | DB connection URL (only when not using an existing Secret) |
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

Configure the connection in one of three ways (checked in this order):

**1. Existing Secret (recommended for production).** Nothing is templated — the
chart reads the URL straight from a Secret you manage, so the password never
appears in values or in Helm release state:

```yaml
database:
  existingSecret: airtrail-db
  existingSecretKey: db-url        # key holding postgres://user:pass@host:5432/db
```

```bash
kubectl create secret generic airtrail-db \
  --from-literal=db-url='postgres://airtrail:secret@db.example.com:5432/airtrail'
```

**2. Full URL inline** (chart stores it in a generated Secret):

```bash
--set database.url='postgres://airtrail:secret@db.example.com:5432/airtrail'
```

**3. Individual components** (assembled into the URL, used when `url` is empty):

```yaml
database:
  host: db.example.com
  port: 5432
  name: airtrail
  username: airtrail
  password: secret                 # use A-Za-z0-9 only to avoid URL-parsing issues
```

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
