# Deploying Stonker to Kubernetes

A self-contained Helm chart in [`stonker/`](./stonker) deploys the whole app:

| Resource | What it is |
|---|---|
| `backend` Deployment + Service | Symfony API (FrankenPHP), 2 replicas |
| `worker` Deployment | 1 replica running the scheduler (daily price fetch + IBKR Flex pull) |
| `migrate` Job | runs Doctrine migrations on every install/upgrade (post hook) |
| `frontend` Deployment + Service | React SPA on nginx |
| `Ingress` | routes `/api` → backend, everything else → frontend |
| `Secret` / `ConfigMap` | APP_SECRET, JWT passphrase, app config |

> **No database is bundled.** Provide an external Postgres (e.g. via the
> [Zalando postgres-operator](https://github.com/zalando/postgres-operator)) and
> point the chart at it — see [Database](#database) below.

## 1. Build and push the images

```bash
# from the repo root
docker build -t ghcr.io/your-org/stonker-backend:0.1.0  backend
docker build -t ghcr.io/your-org/stonker-frontend:0.1.0 frontend
docker push ghcr.io/your-org/stonker-backend:0.1.0
docker push ghcr.io/your-org/stonker-frontend:0.1.0
```

## 2. Generate JWT signing keys (once)

```bash
cd backend
php bin/console lexik:jwt:generate-keypair --skip-if-exists
# Use NO passphrase for the simplest k8s setup (leave jwt.passphrase empty),
# or note the passphrase you chose and pass it via --set jwt.passphrase=…
```

## 3. Install

```bash
helm install stonker deploy/stonker \
  --namespace stonker --create-namespace \
  --set image.backend.repository=ghcr.io/your-org/stonker-backend \
  --set image.backend.tag=0.1.0 \
  --set image.frontend.repository=ghcr.io/your-org/stonker-frontend \
  --set image.frontend.tag=0.1.0 \
  --set ingress.host=stonker.example.com \
  --set-file jwt.privateKey=backend/config/jwt/private.pem \
  --set-file jwt.publicKey=backend/config/jwt/public.pem \
  --values db-values.yaml   # database.* — see Database below
```

`APP_SECRET` is auto-generated and **persisted across upgrades** (the chart reads
back the existing Secret). It also encrypts stored broker credentials, so it must
stay stable — let the chart manage it, or set your own with `--set app.secret=…`.

Upgrades re-run migrations automatically:

```bash
helm upgrade stonker deploy/stonker --reuse-values --set image.backend.tag=0.2.0
```

## TLS

With [cert-manager](https://cert-manager.io) + nginx-ingress:

```bash
--set ingress.tls.enabled=true \
--set ingress.tls.secretName=stonker-tls \
--set 'ingress.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod'
```

## Database

The chart bundles no database — it connects to an external Postgres via
`DATABASE_HOST/PORT/NAME/USER/PASSWORD/SERVER_VERSION`. Each `database.*` value is
a string **or** a Kubernetes-native object (rendered verbatim), so the user and
password can come straight from an operator-managed Secret.

With the **Zalando postgres-operator** — it provisions a cluster and creates a
Secret (keys `username` / `password`) named like
`<role>.<cluster>.credentials.postgresql.acid.zalan.do` — a `db-values.yaml`:

```yaml
database:
  host: stonker-db.my-namespace.svc.cluster.local   # the operator's cluster service
  name: stonker
  port: 5432
  serverVersion: "16"
  user:
    valueFrom:
      secretKeyRef:
        name: stonker.stonker-db.credentials.postgresql.acid.zalan.do
        key: username
  password:
    valueFrom:
      secretKeyRef:
        name: stonker.stonker-db.credentials.postgresql.acid.zalan.do
        key: password
```

For a plain managed DB you can inline strings instead:

```bash
--set database.host=your-db --set database.name=stonker \
--set database.user=stonker --set database.password=secret
```

The migration Job and a `wait-for-db` init container both use this connection, so
rollout waits for the database to be reachable before serving.

## Market-data credentials

Each `marketData.*` value (`eodhdApiKey`, `twelveDataApiKey`, `openFigiApiKey`,
`yahooUserAgent`, `yahooCookie`) accepts **either** an inline string **or** a
Kubernetes-native object that's rendered verbatim as the env var's source — so
you can reference an existing Secret instead of putting the value in `values`.

Inline string (simple):

```bash
--set marketData.eodhdApiKey=6a37...20
```

From an existing Secret (recommended for production), via a values file:

```yaml
marketData:
  eodhdApiKey:
    valueFrom:
      secretKeyRef:
        name: stonker-market-data   # a Secret you manage
        key: eodhd
```

Empty values are omitted entirely, so the image's `.env` default applies (e.g.
`yahooUserAgent`). Only the worker fetches prices, but the keys are injected into
the backend too so on-demand commands (`kubectl exec … app:prices:fetch`) work.

## Notes

- Prices: set `marketData.eodhdApiKey` (primary). Without any key, prices are entered manually.
- The worker is intentionally a single replica — the schedule state is per-process.
- `helm template deploy/stonker --set-file jwt.privateKey=… --set-file jwt.publicKey=… --set ingress.host=…`
  renders the manifests for review without installing.
