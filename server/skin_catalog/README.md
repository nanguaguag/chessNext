# Self hosted piece skin catalog

This service exposes a public, read only catalog. It has no account system,
upload endpoint, likes endpoint, or connection to xiangqiai.com. The operator
publishes metadata and package files from a local directory. Public clients can
search and sort the published entries, read the license/attribution, and fetch a
bounded project skin ZIP.

## Data directory

Create this layout and copy `catalog.example.json` to `data/catalog.json`:

```text
data/
  catalog.json
  packages/
    <skin-id>.zip
```

Each catalog entry has these fields:

```json
{
  "id": "sample-skin",
  "name": "Sample skin",
  "author": "Local studio",
  "description": "A short description.",
  "likes": 0,
  "publishedAt": "2026-11-04T00:00:00Z",
  "license": "CC0-1.0",
  "attribution": "",
  "packageSha256": "64 lowercase hex characters"
}
```

The package is `<id>.zip`, at most 8 MiB, and must have the SHA-256 declared in
the metadata. The application validates the project schema, every image, and
every entry again before import. Publish only assets that you own or are
authorized to redistribute, and include a clear license and attribution.
`likes` is operator supplied display metadata; it does not implement a user vote
or claim live rating data.

## Run locally

From this directory:

```sh
dart pub get
SKIN_CATALOG_ROOT=./data dart run bin/skin_catalog_server.dart
```

It binds to `127.0.0.1:8087` by default. Configure
`SKIN_CATALOG_ADDRESS`, `SKIN_CATALOG_PORT`, and `SKIN_CATALOG_ROOT` for a
deployment. The catalog is loaded once at startup. Use immutable package IDs:
copy new package files first, atomically replace `catalog.json`, then restart
the process. Keep old package files until the prior catalog has been retired.

## Linux VM deployment

Build the executable on the same OS and CPU architecture as the target:

```sh
dart pub get --offline
dart compile exe bin/skin_catalog_server.dart -o build/chessnext-skin-catalog
```

Install the binary as `/usr/local/bin/chessnext-skin-catalog`, create a
`skin-catalog` system user, and place `catalog.json` plus `packages/` under
`/srv/chessnext/skin-catalog/public`. The example
[`skin-catalog.service`](deploy/skin-catalog.service) runs the service as that
non-root user, on loopback only, with a read-only filesystem policy. Adapt the
paths before enabling it with systemd.

The sample Nginx files split the per-IP rate limit directive, which belongs in
the `http {}` context, from the TLS virtual host:

- [`nginx-rate-limit.conf`](deploy/nginx-rate-limit.conf)
- [`nginx-site.conf`](deploy/nginx-site.conf)

Replace the sample host and certificate paths, validate the config with
`nginx -t`, then reload Nginx. DNS points to the VM; only HTTPS is public and
port 8087 remains bound to loopback. Publish packages and metadata through a
staging directory, validate hashes/licenses, atomically replace the catalog
manifest, then restart the service. Keep the previous manifest and packages so
rollback is a manifest restore plus restart. The service itself never writes
to the catalog directory.

## Endpoints

- `GET /healthz`
- `GET /v1/catalog?q=&sort=default|likes|name|author|recent&page=1&pageSize=24`
- `GET /v1/catalog/{id}`
- `GET /v1/catalog/{id}/package`

Only GET/HEAD and CORS preflight are accepted. The API has bounded query,
pagination, manifest and package sizes. Package responses use a content hash as
an ETag and immutable cache key. There are no mutations, tokens, or user
profiles. API response schema is versioned independently from the downloadable
application skin ZIP schema.
