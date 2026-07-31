# Monitoring a PDS

A ready-made Grafana dashboard for a self-hosted PDS, covering both host health
(CPU, memory, disk, network) and PDS activity (accounts, sessions, OAuth grants,
XRPC request rate and latency).

This is entirely optional and completely separate from the main PDS stack. It
does not modify `/pds/compose.yaml` and is not touched by `pdsadmin update`.

## How metrics get out of the PDS

The PDS speaks [OpenTelemetry](https://opentelemetry.io/). It **pushes** metrics
over OTLP rather than exposing a `/metrics` endpoint to be scraped.

Prometheus v3 can receive OTLP directly, so this stack is just three containers
with no OpenTelemetry Collector in between.

## Quick start

Grab this directory and start the stack:

```bash
curl -sL https://github.com/bluesky-social/pds/archive/refs/heads/main.tar.gz \
  | tar xz --strip-components=1 pds-main/monitoring
cd monitoring && docker compose up --detach
```

Then tell the PDS where to send metrics. Add to `/pds/pds.env`:

```bash
OTEL_SERVICE_NAME=pds
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://localhost:9090/api/v1/otlp/v1/metrics
OTEL_EXPORTER_OTLP_METRICS_PROTOCOL=http/protobuf
OTEL_METRIC_EXPORT_INTERVAL=15000
OTEL_SEMCONV_STABILITY_OPT_IN=http
```

and restart:

```bash
sudo systemctl restart pds
```

Two notes on those variables:

- Setting only `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` rather than the generic
  `OTEL_EXPORTER_OTLP_ENDPOINT` is intentional. The PDS enables exactly the
  OTel signals you configure, so this turns on metrics and leaves traces and
  logs off. Setting the generic endpoint would point traces and logs at
  Prometheus too, which cannot accept them.
- `OTEL_SEMCONV_STABILITY_OPT_IN=http` opts into the stable HTTP semantic
  conventions (`http.server.request.duration`, in seconds). The dashboard is
  built against those names. Without it, older HTTP metric names are emitted
  and the request-rate and latency panels stay empty.

## Reaching Grafana

Everything binds to `127.0.0.1` and none of it is exposed to the internet. Do
not open these ports on your cloud firewall. Use an SSH tunnel:

```bash
ssh -L 3001:localhost:3001 you@your-pds-host
```

Then open <http://localhost:3001> and log in with `admin` / `admin`. Grafana
will ask you to change the password on first login.

Grafana runs on **3001** because the PDS itself owns port 3000.

The **PDS Overview** dashboard is provisioned automatically, in a folder named
PDS. It is read-only; to customize it, use "Save as" to make your own copy, or
edit `dashboards/pds-overview.json` and restart Grafana.

## Already running Prometheus and Grafana?

In this case, don't use `compose.yaml` you only need two things.

**1. Point the PDS at your metrics backend.** Set the variables above in
`/pds/pds.env`, with `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` pointed at your own
OTLP endpoint. If your Prometheus runs elsewhere, enable its OTLP receiver
(`--web.enable-otlp-receiver`) and use
`http://your-prometheus:9090/api/v1/otlp/v1/metrics`. If you run an
OpenTelemetry Collector, send to that instead.

**2. Import the dashboard.** In Grafana, *Dashboards → New → Import → Upload
JSON file*, and pick `dashboards/pds-overview.json`. It expects a Prometheus
data source; select yours when prompted.

For host metrics, you presumably already run node_exporter. If not, you can
start just that one service from this directory:

```bash
docker compose up --detach node-exporter
```

and add a scrape job to your own Prometheus:

```yaml
scrape_configs:
  - job_name: pds-node
    static_configs:
      - targets: ['your-pds-host:9100']
```

Note that `compose.yaml` binds node_exporter to `127.0.0.1`, so a Prometheus on
another machine cannot reach it as-is. Either scrape it over an SSH tunnel or a
private network, or change `--web.listen-address`, but if you make it listen on
a public interface, firewall it. `node_exporter` has no authentication.

## Retention and disk

Prometheus keeps 15 days by default (`--storage.tsdb.retention.time` in
`compose.yaml`) and stores data in a Docker volume, not under `/pds`. For a
single PDS this is a small amount of data, but it is not
included in a `/pds` backup, and that it does share the host's disk with your
repos and blobs.

## If a panel is empty

Metric names come from the OpenTelemetry instrumentation and are translated by
Prometheus's OTLP receiver (dots become underscores, and type and unit suffixes
are appended — `account.created` becomes `account_created_total`). Names can
shift as the instrumentation libraries are upgraded.

To see what your PDS is actually reporting:

```bash
curl -s localhost:9090/api/v1/label/__name__/values | tr ',' '\n' | grep -Ei 'account|session|oauth|http_server|nodejs|v8js'
```

If a name differs from what a panel queries, edit the panel's query, or open an
issue so the dashboard can be fixed.