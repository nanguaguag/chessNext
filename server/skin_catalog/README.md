# Self hosted skin catalog with optional book service

This service exposes a public, read only catalog. It has no account system,
upload endpoint, likes endpoint, or connection to xiangqiai.com. The operator
publishes metadata and package files from a local directory. Public clients can
search and sort the published entries, read the license/attribution, and fetch a
bounded project piece-skin ZIP. An optional second root can publish board-skin
packages through a separate endpoint on the same host.

## Data directory

Create this layout and copy `catalog.example.json` to `data/catalog.json`:

```text
data/
  catalog.json
  packages/
    <skin-id>.zip
```

An optional board catalog uses a separate root:

```text
board-data/
  board-catalog.json
  board-packages/
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
deployment. To enable board skins, also set
`SKIN_BOARD_CATALOG_ROOT=./board-data`. This root contains
`board-catalog.json` and `board-packages/<skin-id>.zip`, using the same metadata
schema, hash and license checks. Packages must use the project's board-skin ZIP
schema; clients validate them again before import. The piece catalog uses
`catalog.json` and `packages/`. Catalogs load once at startup. Use immutable package IDs:
copy new package files first, atomically replace `catalog.json`, then restart
the process. Keep old package files until the prior catalog has been retired.

To serve operator-published version and release notes, also set
`CHESSNEXT_RELEASE_ROOT=./release-data`. See the Release metadata section for
the optional `releases.json` format and endpoint. No update package is served.

To accept user-submitted problem reports and suggestions, explicitly set
`CHESSNEXT_FEEDBACK_ROOT` to an existing private writable directory. The route stays
disabled by default. Create the directory owned by the service account with
mode `0700`; with the supplied systemd unit, uncomment both the environment
setting and its matching `ReadWritePaths`. Each submission is a separate
exclusive-create JSON file, with a hard limit of 5,000 records. There is no
public read/list/delete endpoint, no email forwarding, and no automatic
retention cleanup. Operators must define a retention period, review the inbox
locally, and remove expired records through their deployment procedure. The
Dart service does not log submitted fields or persist the request IP. The
sample Nginx config disables access logs for this route and applies its own
per-IP rate limit; network and hosting layers still see source-IP metadata,
and operators control error-log policy.

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
- `GET /v1/board-catalog?q=&sort=default|likes|name|author|recent&page=1&pageSize=24` (optional board root)
- `GET /v1/board-catalog/{id}`
- `GET /v1/board-catalog/{id}/package`
- `POST /v1/book/query` (optional book root, JSON schema 1)
- `POST /v1/feedback` (optional feedback root, JSON schema 1)

Only GET/HEAD, the bounded book-query POST, the optional bounded feedback POST,
and CORS preflight are accepted. Feedback accepts only `kind` (`problem` or
`suggestion`), `message` (1–2,000 characters), and optional `contact` (up to
200 characters); unknown fields, including device/browser/record diagnostics,
are rejected. Request bodies are capped at 16 KiB and stored submissions at
5,000. The sample proxy disables access logs for this location and allows six
submissions per IP per minute, with a burst of five. Network/hosting layers can
still see source IP metadata; operators control error-log policy. The response confirms storage only; it does not imply that an operator
has read or answered the feedback. The API has bounded query,
pagination, manifest and package sizes. Package responses use a content hash as
an ETag and immutable cache key. There are no mutations, tokens, or user
profiles. API response schema is versioned independently from the downloadable
application skin ZIP schema.

### Release metadata

Set `CHESSNEXT_RELEASE_ROOT` to a directory containing `releases.json` to enable
`GET /v1/releases/latest`. The schema is 1 and contains a newest-first `releases`
array with semantic version, positive build number, UTC publication timestamp,
and plain-text notes. The server rejects unknown keys, duplicate version/build
identities, unsorted dates, more than 100 entries, and notes over 4,000
characters. [`releases.example.json`](releases.example.json) is an illustrative
template; replace it with release details you publish.

This endpoint serves public metadata only. It never distributes or installs
binaries and contains no machine identifiers. Clients should call it only when
the user explicitly asks to check. An empty/unconfigured root leaves it
disabled (404). Replace the file atomically and restart to publish changes.

## Optional operator supplied book data

Set `CHESSNEXT_BOOK_ROOT` to a directory containing `book.json`. The schema is
1 and includes `dataset: {id, license, attribution}` plus
`entries: [{kind, fen, history, moves}]`. `kind` is `opening` or `endgame`;
each move contains coordinate `move`, side-to-move `scoreCp`, and positive
`weight`. Lookups match exact FEN plus complete ICCS/UCI history. Candidate
selection and legality are left to the client. An empty manifest is an empty
service, not a populated book. This repository includes no game corpus; publish
only data you own or are authorized to redistribute, with license and
attribution.

`book.example.json` is an empty protocol template with placeholder metadata;
it contains no positions and is not a usable chess book. Replace the license
and attribution placeholders and add only authorized records before exposing
the service.

The service loads the manifest at startup. Replace it atomically and restart to
publish changes. Requests are bounded to 32 KiB and are neither logged nor
persisted. Queries contain the current position and move history, so the app
must use an endpoint the user explicitly configured. The supplied Nginx sample
allows a 32 KiB request body for this endpoint.
